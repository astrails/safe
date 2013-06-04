require 'rubygems'
require 'bundler/setup'
require 'astrails/safe'
require 'debugger'

RSpec.configure do |config|
  config.mock_with :rr
end
