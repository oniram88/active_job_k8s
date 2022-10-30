RSpec.describe 'ActiveJobK8s::Scheduler' do

  let(:args) {
    {
      kubeclient_context: instance_double(
        'Kubeclient::Config::Context',
        auth_options: {
          bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
        },
        ssl_options: { ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt" },
        api_endpoint: "https://kubernetes.default.svc",
        namespace: "my-namespace"
      )
    }
  }

  before(:each) do
    ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::K8sAdapter.new(**args)
  end

  it "execute jobs" do

    json_data = { data: "value" }
    stub_const('ENV', ENV.to_hash.merge('SERIALIZED_JOB' => json_data.to_json))
    expect(ActiveJob::Base).to receive(:execute).with( JSON.parse(json_data.to_json))
    ActiveJobK8s::Scheduler.execute_job

  end

  describe "instance" do

    subject do
      ActiveJobK8s::Scheduler.new(**args)
    end

    it "pass_context" do
      expect(subject.kubeclient_context).to be == args[:kubeclient_context]
    end
  end

end