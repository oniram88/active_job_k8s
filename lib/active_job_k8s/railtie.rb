# frozen_string_literal: true

module ActiveJobK8s
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'active_job_k8s/tasks'
    end

    server do
      if Rails.application.config.active_job.queue_adapter.is_a? ActiveJob::QueueAdapters::K8sAdapter
        puts "=> START ActiveJobK8s - ControlLoop sleep [5]"
        Thread.new do
          Rails.application.reloader.wrap do
            loop do
              Rails.application.config.active_job.queue_adapter.scheduler.un_suspend_jobs
              sleep 5
            end
          end
        end
      else
        puts "=> Queue Adapter was not ActiveJob::QueueAdapters::K8sAdapter"
      end
    end
  end
end