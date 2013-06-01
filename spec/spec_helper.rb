require 'rubygems'
require 'bundler/setup'
require 'astrails/safe'

RSpec.configure do |config|
  config.mock_with :rr
end
