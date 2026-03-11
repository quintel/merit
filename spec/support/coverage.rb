# frozen_string_literal: true

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'

  SimpleCov.start do
    add_filter('/spec')
    add_filter('/lib/merit/point_table')
  end
end
