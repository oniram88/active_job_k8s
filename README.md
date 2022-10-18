# ActiveJobK8s

WIP gem to make active job work with kubernetes jobs.

Roadmap for V1.0:
- [ ] ActiveJob.perform_later create a Job in k8s that will execute the job
- [ ] ActiveJob.perform_later with delay create a Job in k8s in suspended mode, 
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

Configure the KubeClient as documented here: https://github.com/ManageIQ/kubeclient and instantiate the adapter.

Es:
```ruby

  kubeclient_config = Kubeclient::Config.read(ENV['KUBECONFIG'] || File.join(Dir.home, '/.kube/config'))

  config.active_job.queue_adapter = ActiveJob::QueueAdapters::K8sAdapter.new(
    kubeclient_context: kubeclient_config.context('kind-kind')
  )

```

Inside you job you should describe the initial manifest for the [KubernetesJob](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

ES:
```ruby
class HelloWorldJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.debug "Hello World"
  end

  def manifest
    YAML.safe_load(
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

    MANIFEST
    )
  end
end
```

The command will be inserted by the gem.  
To the name of the Job wi will append a timestamp to make it uniq

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_job_k8s. This project is
intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/[USERNAME]/active_job_k8s/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveJobK8s project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/[USERNAME]/active_job_k8s/blob/master/CODE_OF_CONDUCT.md).
