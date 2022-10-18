require 'kubeclient'
require 'active_job_k8s/scheduler'

module ActiveJob
  module QueueAdapters
    class K8sAdapter

      attr_reader :scheduler

      def initialize(**executor_options)
        @scheduler = ActiveJobK8s::Scheduler.new(**executor_options)
      end

      def enqueue(job)
        scheduler.create_job(job)
      end

      def enqueue_at(*)
        # :nodoc:
        raise NotImplementedError, "It will be implemented in the future. Read the roadmap"
      end


    end
  end
end
