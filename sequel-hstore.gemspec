$spec = Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'sequel-hstore'
  s.version = '0.1.6'
  s.date = '2011-07-08'

  s.description = "postgresql hstore support for the sequel gem"
  s.summary     = ""

  s.authors = ["Peter van Hardenberg"]
  s.email = ["pvh@heroku.com"]

  # = MANIFEST =
#  s.files = %w[LICENSE README.md] + Dir["lib/**/*.rb"]

  s.executables = []

  # = MANIFEST =
  s.add_dependency 'sequel' # hm, not sure how to express this
  s.add_development_dependency 'rspec', '~> 2.5.0'
  s.homepage = "http://github.com/pvh/sequel-hstore"
  s.require_paths = %w[lib]
end
