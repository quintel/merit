# frozen_string_literal: true

require 'rspec'
require 'pathname'
require 'factory_bot'

require 'support/coverage'
require 'merit'

Dir['./spec/support/**/*.rb'].map do |file|
  require file unless file.end_with?('coverage.rb')
end

RSpec.configure do |config|
  # Use only the new "expect" syntax.
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  # Tries to find examples / groups with the focus tag, and runs them. If no
  # examples are focues, run everything. Prevents the need to specify
  # `--tag focus` when you only want to run certain examples.
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  config.expose_dsl_globally = true

  config.include(FactoryBot::Syntax::Methods)
  config.include(Merit::Spec)

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

def capture_stdout
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end
