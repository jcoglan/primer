require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"
require File.dirname(__FILE__) + "/lib/primer"

require "rspec"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(--format specdoc --colour)
end

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|

  # Change these as appropriate
  s.name              = "primer"
  s.version           = Primer::VERSION
  s.summary           = "Intelligent caching, no observers necessary"
  s.author            = "James Coglan"
  s.email             = "jcoglan@gmail.com"
  s.homepage          = "http://github.com/jcoglan/primer"

  s.has_rdoc          = true
  # You should probably have a README of some kind. Change the filename
  # as appropriate
  s.extra_rdoc_files  = %w(README.rdoc example/README.rdoc)
  s.rdoc_options      = %w(--main README.rdoc --title Primer)

  # Add any extra files to include in the gem (like your README)
  s.files             = %w(README.rdoc) + Dir.glob("{spec,lib,example}/**/*")
  s.require_paths     = ["lib"]

  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  s.add_dependency("redis", "~> 2.1.1")
  s.add_dependency("sinatra", "~> 1.1.0")
  s.add_dependency("amqp", "~> 0.6.7")
  s.add_dependency("faye", ">= 0.5")

  # If your tests use any gems, include them here
  s.add_development_dependency("rspec")
  s.add_development_dependency("activerecord")
  s.add_development_dependency("sqlite3")
  s.add_development_dependency("actionpack")
  s.add_development_dependency("tilt")
end

# This task actually builds the gem. We also regenerate a static
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
#
# To publish your gem online, install the 'gemcutter' gem; Read more 
# about that here: http://gemcutter.org/pages/gem_docs
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

# If you don't want to generate the .gemspec file, just remove this line. Reasons
# why you might want to generate a gemspec:
#  - using bundler with a git source
#  - building the gem without rake (i.e. gem build blah.gemspec)
#  - maybe others?
task :package => :gemspec

# Generate documentation
Rake::RDocTask.new do |rd|
  rd.title = "Primer"
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
