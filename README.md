# ActiveJobK8s

WIP gem to make active job work with kubernetes jobs.

Roadmap for V1.0:
- [x] ActiveJob.perform_later create a Job in k8s that will execute the job
- [x] ActiveJob.perform_later with delay create a Job in k8s in suspended mode, 
      a task will enable it as soon as the time is reached
- [ ] Limiting the number of concurrent jobs (if there are more jobs they will be created in suspended mode)

Future:
- [ ] Metrics (because everyone like metrics)
- [ ] Retry options

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_job_k8s'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install active_job_k8s

## Usage

### Adapter Configuration
Configure the KubeClient as documented here: https://github.com/ManageIQ/kubeclient and instantiate the adapter.

ES Local with default kind cluster:
```ruby

  kubeclient_config = Kubeclient::Config.read(ENV['KUBECONFIG'] || File.join(Dir.home, '/.kube/config'))

  config.active_job.queue_adapter = ActiveJob::QueueAdapters::K8sAdapter.new(
    kubeclient_context: kubeclient_config.context('kind-kind')
  )

```
ES production configuration:
```ruby
Rails.application.configure do

  auth_options = {
    bearer_token_file: "/var/run/secrets/kubernetes.io/serviceaccount/token"
  }
  ssl_options = {}
  if File.exist?("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
    ssl_options[:ca_file] = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
  end
  api_endpoint = "https://kubernetes.default.svc"
  api_version = "v1"
  namespace = File.read("/var/run/secrets/kubernetes.io/serviceaccount/namespace")

  context = Kubeclient::Config::Context.new(
    api_endpoint,
    api_version,
    ssl_options,
    auth_options,
    namespace
  )

  default_manifest = YAML.safe_load(
          <<~MANIFEST
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: scheduled-job-name
            namespace: default
          spec:
            template:
              spec:
                restartPolicy: Never
                containers:
                  - name: app-job
                    image: image_of_the_rails_application
                    imagePullPolicy: IfNotPresent
                    command:
                      - /bin/bash
                    args:
                      - '-c'
                      - bundle exec rails active_job_k8s:run_job

  MANIFEST
  )

  config.active_job.queue_adapter = ActiveJob::QueueAdapters::K8sAdapter.new(
    kubeclient_context: context,
    default_manifest: default_manifest
  )

end
```

### Kubernetes Configuration

The adapter should be capable to query the kubernetes cluster, this is the role to create inside the namespace, it will
add api capacity o jobs to the default ServiceAccount

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: jobs-edit
  namespace: YOURN-NAMESPACE
rules:
  - apiGroups:
      - "batch"
    resources:
      - jobs
    verbs:
      - get
      - list
      - watch
      - create
      - delete
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: jobs-edit
  namespace: YOURN-NAMESPACE
subjects:
  - kind: ServiceAccount
    name: default
    namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: jobs-edit
```

### Job configuration

Inside you job you should describe the initial manifest for the [KubernetesJob](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

ES:
```ruby
class HelloWorldJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.debug "Hello World"
  end
      
  #[Optional] if not present it will be taken from scheduler configuration
  # def manifest
  # .....
  # end 
      
end
```

The command will be inserted by the gem if not present.
```yaml
      command: ["rails"]
      args: ["active_job_k8s:run_job"]
```
To the name of the Job wi will append a timestamp to make it uniq

## Development

Requirements: [kind](https://kind.sigs.k8s.io/)

After checking out the repo, run `bin/setup` to install the environment (cluster and dummy app). 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_job_k8s. This project is
intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/oniram88/active_job_k8s/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveJobK8s project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/[USERNAME]/active_job_k8s/blob/master/CODE_OF_CONDUCT.md).
