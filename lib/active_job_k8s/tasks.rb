# frozen_string_literal: true

namespace :active_job_k8s do

  desc "Execute the job from ENV: SERIALIZED_JOB"
  task run_job: :environment do
    ActiveJobK8s::Scheduler.execute_job
  end
end