# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "huginn_fitbit_agent"
  spec.version       = '1.0'
  spec.authors       = ["Alessio Signorini"]
  spec.email         = ["alessio@signorini.us"]

  spec.summary       = 'The Fitbit Agent periodically fetches your Fitbit account and creates events from new activities'
  spec.homepage      = "https://github.com/alessio-signorini/huginn_fitbit_agent"
  spec.license       = "MIT"


  spec.files         = Dir['LICENSE.txt', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*.rb'].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "byebug"

  spec.add_runtime_dependency "huginn_agent"
  spec.add_runtime_dependency "oauth2"

end
