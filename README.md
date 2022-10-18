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

TODO: Write usage instructions here

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
