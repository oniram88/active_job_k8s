# frozen_string_literal: true

namespace :active_job_k8s do
  task run_job: :environment do
    ActiveJobK8s::Scheduler.execute_job
  end
end