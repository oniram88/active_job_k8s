# frozen_string_literal: true

module ActiveJobK8s
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'active_job_k8s/tasks'
    end

    server do
      puts "=> START ActiveJobK8s - ControlLoop sleep [5]"
      Thread.new do
        Rails.application.reloader.wrap do
          loop do
            Rails.application.config.active_job.queue_adapter.scheduler.un_suspend_jobs
            sleep 5
          end
        end
      end
    end
  end
end