# encoding: UTF-8
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name          = 'websockethook'
  s.version       = '0.1.02'
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Maciej Skierkowski']
  s.email         = ['maciej@factor.io']
  s.homepage      = 'http://web.sockethook.io/'
  s.summary       = 'A library for use the free web.sockethook.io service'
  s.description   = 'Listen for web hooks in your app without creating a web service.'
  s.files         = Dir.glob('lib/**/*.rb')
  s.license       = 'MIT'

  s.test_files    = Dir.glob('./{test,spec,features}/*.rb')
  s.require_paths = ['lib']

  s.add_runtime_dependency 'faye-websocket', '~> 0.9.2'

  s.add_development_dependency 'rspec', '~> 3.2.0'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.4.7'
  s.add_development_dependency 'rake', '~> 10.4.2'
  s.add_development_dependency 'wrong', '~> 0.7.1'
  s.add_development_dependency 'rest-client', '~> 1.8.0'
end
