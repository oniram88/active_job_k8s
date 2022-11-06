require 'active_job/queue_adapters/k8s_adapter'
RSpec.describe 'ActiveJob::QueueAdapters::K8sAdapter' do

  let(:args) {
    {
      kubeclient_context: instance_double("Kubeclient::Config::Context"),
      default_manifest: {}
    }
  }

  let(:subject) do
    ActiveJob::QueueAdapters::K8sAdapter.new(**args)
  end

  it "scheduler" do
    expect(subject.scheduler).to be_an_instance_of ActiveJobK8s::Scheduler
  end

  it "enqueue" do
    job = instance_double("ActiveJob::Base")
    expect(subject.scheduler).to receive(:create_job).with(job)
    subject.enqueue(job)
  end

  it "enqueue_at" do
    job = instance_double("ActiveJob::Base")
    expect(subject.scheduler).to receive(:create_job).with(job, scheduled_at: 12312323.123)
    subject.enqueue_at(job, 12312323.123)
  end

end