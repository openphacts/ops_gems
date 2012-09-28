require 'rubygems'
require 'bundler/setup'

require 'vcr'
require 'webmock/rspec'

WebMock.disable_net_connect!

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each {|f| require f}

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.mock_with :flexmock

  # so we can use `:vcr` rather than `:vcr => true`;
  # in RSpec 3 this will no longer be necessary.
  config.treat_symbols_as_metadata_keys_with_true_values = true
end


$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ops'

OPS.log = false