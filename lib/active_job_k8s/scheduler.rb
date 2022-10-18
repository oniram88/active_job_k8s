module ActiveJobK8s
  class Scheduler

    attr_reader :kubeclient_context

    def initialize(**opts)
      raise "No KubeClientContext given" if opts[:kubeclient_context].nil?
      # or to use a specific context, by name:
      @kubeclient_context = opts[:kubeclient_context]

    end

    def create_job(job)

      serialized_job = JSON.dump(job.serialize)

      kube_job = Kubeclient::Resource.new(job.manifest)

      # kube_job.spec.suspend = false FIXME complete for delayed jobs
      kube_job.metadata.name = "#{kube_job.metadata.name}-#{Time.now.to_i}"
      kube_job.spec.template.spec.containers.map do |container|
        container.env ||= []
        container.env.push({
                             'name' => 'SERIALIZED_JOB',
                             'value' => serialized_job
                           })

        if container.command.blank?
          container.command = ["rake"]
          container.args = ["active_job_k8s:run_job"]
        end
      end

      client.create_job(kube_job)
    end

    def self.execute_job
      ActiveJob::Base.execute(JSON.parse(ENV['SERIALIZED_JOB']))
    end

    protected

    def client
      @client ||= Kubeclient::Client.new(@kubeclient_context.api_endpoint + '/apis/batch',
                                         'v1' || @kubeclient_context.version,
                                         ssl_options: @kubeclient_context.ssl_options,
                                         auth_options: @kubeclient_context.auth_options)
    end
  end

end
