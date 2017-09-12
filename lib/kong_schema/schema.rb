# frozen_string_literal: true

require 'yaml'
require 'kong'
require 'English'

require_relative './client'
require_relative './resource'

module KongSchema
  module Schema
    extend self

    # Scan for changes between Kong's database and the configuration. To
    # commit the changes (if any) use {.commit} with the results.
    #
    # @param [Object] config
    #        The configuration directives as explain in README.
    #
    # @return [Array<Change>]
    def scan(config)
      Client.connect(config) do
        [
          scan_in(model: Resource::Api, directives: Array(config['apis'])),

          # order matters in some of the resources; Upstream directives must be
          # handled before Target ones
          scan_in(model: Resource::Upstream, directives: Array(config['upstreams'])),

          scan_in(model: Resource::Target, directives: Array(config['targets']))
        ].flatten
      end
    end

    # Commit changes to Kong's database through its REST API.
    #
    # @param [Object] config
    # @param [Array<Change>] changes
    #
    # @return NilClass
    def commit(config, directives)
      Client.connect(config) do |client|
        directives.each do |d|
          begin
            d.apply(client, config)
          rescue StandardError
            e = $ERROR_INFO
            raise e, "#{e}\nSource:\n#{YAML.dump(d)}", e.backtrace
          end
        end
      end
    end

    private

    def scan_in(model:, directives:)
      state = {
        model: model,
        defined: model.all.each_with_object({}) do |record, map|
          map[model.identify(record)] = record
        end,
        declared: directives.each_with_object({}) do |directive, map|
          map[model.identify(directive)] = directive
        end
      }

      [
        build_create_changes(state),
        build_update_changes(state),
        build_delete_changes(state)
      ].flatten
    end

    def build_create_changes(model:, defined:, declared:)
      to_create = declared.keys - defined.keys
      to_create.map do |id|
        Actions::Create.new(model: model, params: declared[id])
      end
    end

    def build_update_changes(model:, defined:, declared:)
      to_update = declared.keys & defined.keys
      changed   = to_update.select do |id|
        model.changed?(defined[id], declared[id])
      end

      changed.map do |id|
        Actions::Update.new(
          model: model,
          record: defined[id],
          params: declared[id]
        )
      end
    end

    def build_delete_changes(model:, defined:, declared:)
      to_delete = defined.keys - declared.keys
      to_delete.map do |id|
        Actions::Delete.new(model: model, record: defined[id])
      end
    end
  end
end
