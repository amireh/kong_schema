# frozen_string_literal: true

require 'kong_schema'
require 'tty-table'
require 'json'
require 'diffy'
require 'pastel'
require_relative './actions'

module KongSchema
  # Helper class for printing a report of the changes to be committed to Kong
  # created by {Schema.analyze}.
  module Reporter
    extend self

    TableHeader = %w(Change Parameters).freeze

    # @param [Array<KongSchema::Action>] changes
    #        What you get from calling {KongSchema::Schema.analyze}
    #
    # @return [String] The report to print to something like STDOUT.
    def report(changes, object_format: :json, diff: true)
      pretty_print = if object_format == :json
        JSONPrettyPrinter.method(:print)
      else
        YAMLPrettyPrinter.method(:print)
      end

      table = TTY::Table.new header: TableHeader do |t|
        changes.each do |change|
          t << print_change(
            change: change,
            pretty_print: pretty_print,
            enable_diffs: diff
          )
        end
      end

      table.render(:ascii, multiline: true, padding: [0, 1, 0, 1])
    end

    private

    # Print objects as human-readable JSON
    class JSONPrettyPrinter
      def self.print(object)
        JSON.pretty_generate(YAML.load(YAML.dump(object))) + "\n"
      end
    end

    # Print objects as YAML
    class YAMLPrettyPrinter
      def self.print(object)
        YAML.dump(object)
      end
    end

    def print_change(change:, pretty_print:, enable_diffs:)
      resource_name = change.model.to_s.split('::').last

      case change
      when KongSchema::Actions::Create
        [ "Create #{resource_name}", pretty_print.call(change.params) ]
      when KongSchema::Actions::Update
        record_attributes = rewrite_record_attributes(change.record)
        current_attributes = change.params.keys.reduce({}) do |map, key|
          map[key] = record_attributes[key]
          map
        end

        changed_attributes = normalize_api_attributes(change.record, change.params)

        if enable_diffs
          diff = Diffy::Diff.new(
            pretty_print.call(current_attributes),
            pretty_print.call(changed_attributes)
          )

          [ "Update #{resource_name}", diff.to_s(:color) ]
        else
          [ "Update #{resource_name}", pretty_print[changed_attributes.keys] ]
        end
      when KongSchema::Actions::Delete
        [
          "Delete #{resource_name}",
          pretty_print.call(rewrite_record_attributes(change.record))
        ]
      end
    end

    def normalize_api_attributes(record, attrs)
      case record
      when Kong::Api
        attrs.merge('methods' => Array(attrs['methods']).join(',').split(','))
      else
        attrs
      end
    end

    # This warrants some explanation.
    #
    # For some Kong API objects like Target, the API will accept "indirect"
    # values for certain parameters like "upstream_id" but in the responses for
    # those APIs, the payload will contain a value different than what we POSTed
    # with. In this example, it will accept an upstream_id of either an actual
    # Upstream.id like "c9633f63-fdaf-4c1c-b9dd-b5a0fa28c780" or an
    # Upstream.name like "some-upstream.kong-service".
    #
    # For our purposes, the user doesn't know about Upstream.id, so we don't
    # care to show that value, so we will rewrite it with the value they're
    # meant to input (e.g. target.upstream_id -> target.upstream.name)
    def rewrite_record_attributes(record)
      case record
      when Kong::Api
        record.attributes
      when Kong::Target
        record.attributes.merge('upstream_id' => record.upstream.name)
      else
        record.attributes
      end
    end
  end
end
