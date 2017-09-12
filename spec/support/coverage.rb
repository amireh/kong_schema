require "simplecov"
require "simplecov_compact_json"

SimpleCov.at_exit do
  SimpleCov.minimum_coverage(95)
  SimpleCov.maximum_coverage_drop(1)
  SimpleCov.formatters = [
    SimpleCov::Formatter::CompactJSON,
    SimpleCov::Formatter::HTMLFormatter
  ]
  SimpleCov.result.format!
end

SimpleCov.start do
  add_filter "/.gem/"
  add_filter "/bin/"
  add_filter "/spec/"
end
