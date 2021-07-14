# frozen_string_literal: true

module Merit
  module Spec
    # Returns the path to a fixture file.
    def fixture(path)
      Pathname.new(__FILE__).dirname.dirname.join("fixtures/#{path}.csv")
    end
  end
end
