require "webmock/rspec"
require "given_filesystem/spec_helpers"

require_relative "../lib/myer"

def test_data_path(filename)
  data_path = File.expand_path( "../data/", __FILE__ )
  File.join(data_path, filename)
end
