require 'rubygems'
require 'bundler/setup'

require 'webmock/rspec'

WebMock.disable_net_connect!

require 'active_model'
$:.unshift File.expand_path('../../lib/ops', __FILE__)
require 'core_api_call'

RSpec.configure do |config|
  # some (optional) config here
end