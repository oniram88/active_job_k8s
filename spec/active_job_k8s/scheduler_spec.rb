RSpec.describe 'ActiveJobK8s::Scheduler' do

  let(:default_manifest) {
    {}
  }

  let(:args) {
    {
      kubeclient_context: instance_double(
        'Kubeclient::Config::Context',
        auth_options: {
          # bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
        },
        api_version: nil,
        ssl_options: {
          # ca_file: "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        },
        api_endpoint: "https://kubernetes.default.svc",
        namespace: "my-namespace"
      ),
      default_manifest: default_manifest
    }
  }

  before(:each) do
    ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::K8sAdapter.new(**args)
  end

  it "execute jobs" do

    json_data = { data: "value" }
    stub_const('ENV', ENV.to_hash.merge('SERIALIZED_JOB' => json_data.to_json))
    expect(ActiveJob::Base).to receive(:execute).with(JSON.parse(json_data.to_json))
    ActiveJobK8s::Scheduler.execute_job

  end

  it "raise if no context" do
    expect {
      ActiveJobK8s::Scheduler.new
    }.to raise_error("No KubeClientContext given")
  end

  describe "instance" do

    subject do
      ActiveJob::Base.queue_adapter.scheduler
    end

    it "pass_context" do
      expect(subject.kubeclient_context).to be == args[:kubeclient_context]
    end

    it "manifest" do
      expect(subject.default_manifest).to be == args[:default_manifest]
    end

    it "client" do

      expect(subject.send(:client)).to be_an_instance_of(Kubeclient::Client).and(have_attributes(
                                                                                   api_endpoint: URI.parse("https://kubernetes.default.svc/apis/batch")
                                                                                 ))

    end

    describe "create job" do

      let(:default_manifest) do
        {
          "apiVersion" => "batch/v1",
          "kind" => "Job",
          "metadata" => { "name" => "scheduled-job-name" },
          "spec" =>
            { "template" =>
                { "spec" =>
                    { "restartPolicy" => "Never",
                      "containers" =>
                        [
                          {
                            "name" => "app-job",
                            "image" => "image_of_the_rails_application",
                            "imagePullPolicy" => "IfNotPresent"
                          }
                        ]
                    }
                }
            }
        }
      end
      let(:job_manifest) do
        nil
      end

      let(:job_class) do

        c = Class.new(ActiveJob::Base) do

          cattr_accessor :manifest
          queue_as "name-of-the-queue"

          def perform(arg) end

          def manifest
            self.class.manifest
          end

        end

        c.manifest = job_manifest
        c
      end

      let(:fake_client) do
        spy("Client")
      end

      before do
        allow(subject).to receive(:client).and_return(fake_client)
      end

      it "generate job" do

        expect(fake_client).to receive(:create_job).with(
          an_instance_of(Kubeclient::Resource).and(have_attributes(
                                                     kind: "Job",
                                                     metadata: include(
                                                       name: /scheduled-job-name-.*/,
                                                       queue_name: 'name-of-the-queue',
                                                       namespace: "my-namespace"
                                                     ),
                                                     spec: include(
                                                       ttlSecondsAfterFinished: 300,
                                                       template: include(
                                                         spec: include(
                                                           containers: array_including(
                                                             include(
                                                               env: array_including({
                                                                                      name: 'SERIALIZED_JOB',
                                                                                      value: an_instance_of(String)
                                                                                    }),
                                                               command: ['rails'],
                                                               args: ["active_job_k8s:run_job"]
                                                             )
                                                           )
                                                         )
                                                       )
                                                     )
                                                   ))
        )

        job_class.perform_later

      end

      context "with command" do
        let(:default_manifest) do
          super().tap do |m|
            m['spec']['template']['spec']['containers'][0].tap do |c|
              c['command'] = ['sleep']
              c['args'] = ["3000"]
            end
          end
        end

        it do
          expect(fake_client).to receive(:create_job).with(
            have_attributes(
              spec: include(
                ttlSecondsAfterFinished: 300,
                template: include(
                  spec: include(
                    containers: array_including(
                      include(
                        command: ['sleep'],
                        args: ["3000"]
                      )
                    )
                  )
                )
              )
            )
          )
          job_class.perform_later
        end
      end

      context "with job manifest" do
        let(:job_manifest) do
          default_manifest.tap do |m|
            m['spec']['template']['spec']['containers'][0].tap do |c|
              c['name'] = "custom-job-name"
            end
          end
        end

        it do
          expect(fake_client).to receive(:create_job).with(
            have_attributes(
              spec: include(
                template: include(
                  spec: include(
                    containers: array_including(
                      include(
                        name: "custom-job-name"
                      )
                    )
                  )
                )
              )
            )
          )
          job_class.perform_later
        end
      end

    end

  end

end