require "kubeclient"
require "active_job"
require "json"

module ActiveJobK8s
  class Scheduler

    #@return [Kubeclient::Config::Context]
    attr_reader :kubeclient_context

    #@return [Hash]
    attr_reader :default_manifest

    # @param [Hash{ kubeclient_context: Kubeclient::Config::Context, default_manifest: Hash }] opts
    def initialize(**opts)
      raise "No KubeClientContext given" if opts[:kubeclient_context].nil?
      # or to use a specific context, by name:
      @kubeclient_context = opts[:kubeclient_context]
      @default_manifest = opts[:default_manifest] || {}

    end

    def create_job(job)

      serialized_job = JSON.dump(job.serialize)

      manifest = (job.respond_to?(:manifest) and job.manifest.is_a?(Hash) and !job.manifest.empty?) ?  job.manifest : default_manifest
      kube_job = Kubeclient::Resource.new(manifest)

      # kube_job.spec.suspend = false FIXME complete for delayed jobs
      kube_job.metadata.name = "#{kube_job.metadata.name}-#{job.job_id}"
      kube_job.metadata.job_id = job.job_id
      kube_job.metadata.queue_name = job.queue_name
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

      client.create_job(kube_job)
    end

    def self.execute_job
      ActiveJob::Base.execute(JSON.parse(ENV['SERIALIZED_JOB']))
    end

    protected

    def client
      @client ||= Kubeclient::Client.new(@kubeclient_context.api_endpoint + '/apis/batch',
                                         @kubeclient_context.api_version || 'v1',
                                         ssl_options: @kubeclient_context.ssl_options,
                                         auth_options: @kubeclient_context.auth_options)
    end
  end

end
