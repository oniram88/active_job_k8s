require "kubeclient"
require "active_job"
require "json"

module ActiveJobK8s
  class Scheduler

    #@return [Kubeclient::Config::Context]
    attr_reader :kubeclient_context

    #@return [Hash]
    attr_reader :default_manifest

    # @param [Kubeclient::Config::Context] kubeclient_context
    # @param [Hash] default_manifest
    # @param [Integer] max_concurrent_jobs default 5
    def initialize(kubeclient_context:, default_manifest: {}, max_concurrent_jobs: 5)
      # or to use a specific context, by name:
      @kubeclient_context = kubeclient_context
      @default_manifest = default_manifest
      @max_concurrent_jobs = max_concurrent_jobs
    end

    def create_job(job, scheduled_at: nil)

      serialized_job = JSON.dump(job.serialize)

      manifest = (job.respond_to?(:manifest) and job.manifest.is_a?(Hash) and !job.manifest.empty?) ? job.manifest : default_manifest
      kube_job = Kubeclient::Resource.new(manifest)

      kube_job.metadata.name = "#{kube_job.metadata.name}-#{job.job_id}"
      kube_job.metadata.annotations ||= {}
      kube_job.metadata.annotations.job_id = job.job_id
      kube_job.metadata.annotations.queue_name = job.queue_name
      kube_job.metadata.namespace = kube_job.metadata.namespace || kubeclient_context.namespace
      kube_job.spec.template.spec.containers.map do |container|
        container.env ||= []
        container.env.push({
                             'name' => 'SERIALIZED_JOB',
                             'value' => serialized_job
                           })

        if container.command.blank?
          container.command = ["rails"]
          container.args = ["active_job_k8s:run_job"]
        end
      end
      kube_job.spec.ttlSecondsAfterFinished = 300 #number of seconds the job will be erased

      kube_job.metadata.labels ||= {}
      if scheduled_at
        kube_job.spec.suspend = true
        kube_job.metadata.annotations.scheduled_at = scheduled_at.to_s
        kube_job.metadata.labels.activeJobK8s = "scheduled" # job to be execute when time comes
      else
        kube_job.metadata.labels.activeJobK8s = "delayed" # job to be execute when possible
      end
      client.create_job(kube_job)
    end

    def self.execute_job
      ActiveJob::Base.execute(JSON.parse(ENV['SERIALIZED_JOB']))
    end

    ##
    # Un-suspend jobs if the scheduled at is outdated, limited to max allowed concurrent
    def un_suspend_jobs

      to_activate_jobs = @max_concurrent_jobs - active_jobs.size #FIXME devo sottrarre il numero degli attivi attualmente
      to_activate_jobs = 0 if to_activate_jobs < 0
      Rails.logger.debug { "Devo abilitare: [#{to_activate_jobs}/#{active_jobs.size}]" }
      suspended_jobs.select { |sj|
        scheduled_at = Time.at(sj.metadata.annotations.scheduled_at.to_f)
        Time.now > scheduled_at and sj.spec.suspend
      }.take(to_activate_jobs).each do |sj|
        client.patch_job(sj.metadata.name, { spec: { suspend: false } }, sj.metadata.namespace).inspect
      end
    end

    protected

    def client
      @client ||= Kubeclient::Client.new(@kubeclient_context.api_endpoint + '/apis/batch',
                                         @kubeclient_context.api_version || 'v1',
                                         ssl_options: @kubeclient_context.ssl_options,
                                         auth_options: @kubeclient_context.auth_options)
    end

    private

    ##
    # Internal list of all suspended jobs
    def suspended_jobs
      client.get_jobs(namespace: kubeclient_context.namespace,
                      label_selector: "activeJobK8s=scheduled",
                      field_selector: 'status.successful!=1')
    end

    def active_jobs
      client.get_jobs(namespace: kubeclient_context.namespace,
                      label_selector: "activeJobK8s",
                      field_selector: 'status.successful!=1').select do |j|

        # Rails.logger.debug { [j.status.inspect , j.spec.suspend.inspect ] }
        j.status.active.to_i == 1 and j.spec.suspend != "true"
      end
    end
  end

end
