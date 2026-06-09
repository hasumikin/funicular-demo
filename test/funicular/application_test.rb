require_relative "../test_helper"
require "funicular/testing"

class FunicularApplicationTest < ActiveSupport::TestCase
  test "client-side Funicular tests" do
    result = Funicular::Testing.run!(timeout_ms: 10_000)
    Funicular::Testing.assert_picotests(self, result)
  end
end
