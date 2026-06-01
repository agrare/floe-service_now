# frozen_string_literal: true

require_relative "lib/floe/servicenow/version"

Gem::Specification.new do |spec|
  spec.name = "floe-servicenow"
  spec.version = Floe::ServiceNow::VERSION
  spec.authors = ["Adam Grare"]
  spec.email = ["adam@grare.com"]

  spec.summary = "ServiceNow API Integration for Floe"
  spec.description = "ServiceNow API Integration for Floe"
  spec.homepage = "https://github.com/ManageIQ/floe-servicenow"
  spec.licenses = ["Apache-2.0"]
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata['rubygems_mfa_required'] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], :chdir => __dir__, :err => IO::NULL) do |ls|
    ls.readlines("\x0", :chomp => true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "floe", "~> 0.19"

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
  spec.add_development_dependency "timecop"
end
