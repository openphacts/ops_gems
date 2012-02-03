require 'rubygems'
require 'bundler/setup'

require 'webmock/rspec'

WebMock.disable_net_connect!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ops'

OPS.log = false

RSpec.configure do |config|
  # some (optional) config here
end