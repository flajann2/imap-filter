# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'semver'

def s_version
  SemVer.find.format "%M.%m.%p%s"
end

require 'juwelier'
Juwelier::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "imap-filter"
  gem.homepage = "http://github.com/flajann2/imap-filter"
  gem.license = "MIT"
  gem.summary = %Q{IMAP Scriptable filter for one or multiple Email accounts.}
  gem.description = %Q{
  imap-filter is a Ruby implementation of an IMAP filtering application.
  it can handle multiple IMAP accounts, and create IMAP folders automatically
  where none exists.

  The imap-filter DSL makes it easy to filter. You can also do "dry-runs"
  to make sure what happens is what is expected.}
  
  gem.email = "fred.mitchell@gmx.de"
  gem.authors = ["Fred Mitchell"]
  gem.version = s_version
  gem.required_ruby_version = '>= 2.2'

  # dependencies defined in Gemfile
end
Juwelier::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['spec'].execute
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
