require 'codeclimate-test-reporter'
require 'rspec'
require 'wrong'

CodeClimate::TestReporter.start if ENV['CODECLIMATE_REPO_TOKEN']

RSpec.configure do |_c|
end
