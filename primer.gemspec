Gem::Specification.new do |s|
  s.name              = "primer"
  s.version           = "0.1.0"
  s.summary           = "Intelligent caching, no observers necessary"
  s.author            = "James Coglan"
  s.email             = "jcoglan@gmail.com"
  s.homepage          = "http://github.com/jcoglan/primer"

  s.extra_rdoc_files  = %w(README.rdoc example/README.rdoc)
  s.rdoc_options      = %w(--main README.rdoc --title Primer)

  s.files             = %w(History.txt README.rdoc) + Dir.glob("{spec,lib,example}/**/*")
  s.require_paths     = ["lib"]

  s.add_dependency("redis", ">= 2.1.1")
  s.add_dependency("sinatra", ">= 1.1.0")
  s.add_dependency("amqp", ">= 0.6.7")
  s.add_dependency("faye", ">= 0.5")

  s.add_development_dependency("rspec")
  s.add_development_dependency("activerecord")
  s.add_development_dependency("sqlite3")
  s.add_development_dependency("actionpack")
  s.add_development_dependency("tilt")
end
