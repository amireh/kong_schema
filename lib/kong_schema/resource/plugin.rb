# frozen_string_literal: true

require 'kong'
require_relative '../adapter'
require_relative '../functional'

module KongSchema
  module Resource
    module Plugin
      extend self
      extend Functional

      def identify(record)
        case record
        when Kong::Plugin
          [ record.name, try(record.api, :name), record.consumer_id ]
        when Hash
          [ record['name'], record['api_id'], record['consumer_id'] ]
        end
      end

      def all(*)
        Kong::Plugin.all
      end

      def create(attributes)
        Adapter.for(Kong::Plugin).create(attributes)
      end

      def creatable?(attributes)
        attributes['enabled'] != false
      end

      def changed?(record, attributes)
        current = record.attributes.keys.each_with_object({}) do |key, map|
          value = record.attributes[key]

          map[key] = case key
          when 'api_id'
            record.api.name
          else
            value
          end
        end

        Adapter.for(Kong::Plugin).changed?(current, attributes)
      end

      def update(record, partial_attributes)
        if partial_attributes['enabled'] == false
          delete(record)
        else
          Adapter.for(Kong::Plugin).update(
            record,
            partial_attributes.merge('api_id' => record.api.id)
          )
        end
      end

      def delete(record)
        Adapter.for(Kong::Plugin).delete(record)
      end
    end
  end
end
