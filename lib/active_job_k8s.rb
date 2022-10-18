require "active_job_k8s/version"
require "active_job/queue_adapters/k8s_adapter"
require 'active_job_k8s/railtie' if defined?(Rails::Railtie)

module ActiveJobK8s
  class Error < StandardError; end
  # Your code goes here...
end
