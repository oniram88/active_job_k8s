# frozen_string_literal: true

module ActiveJobK8s
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'active_job_k8s/tasks'
    end
  end
end