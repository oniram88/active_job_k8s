require_relative 'lib/active_job_k8s/version'

Gem::Specification.new do |spec|
  spec.name          = "active_job_k8s"
  spec.version       = ActiveJobK8s::VERSION
  spec.authors       = ["Marino Bonetti"]
  spec.email         = ["marinobonetti@gmail.com"]

  spec.summary       = "ActiveJob adapter for kubernetes job"
  spec.homepage      = "https://github.com/oniram88/active_job_k8s"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'kubeclient', '~> 4.0' #https://github.com/ManageIQ/kubeclient
  spec.add_dependency 'rails', '>= 5.0', '<8'

end
