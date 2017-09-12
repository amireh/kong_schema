# frozen_string_literal: true

require 'kong'
require_relative '../adapter'

module KongSchema
  module Resource
    module Api
      extend self

      def identify(record)
        case record
        when Kong::Api
          record.name
        when Hash
          record['name']
        end
      end

      def all(*)
        Kong::Api.all
      end

      def create(attributes)
        Adapter.for(Kong::Api).create(serialize_outbound(attributes))
      end

      def changed?(record, attributes)
        Adapter.for(Kong::Api).changed?(record, attributes)
      end

      def update(record, partial_attributes)
        Adapter.for(Kong::Api).update(
          record,
          serialize_outbound(partial_attributes)
        )
      end

      def delete(record)
        Adapter.for(Kong::Api).delete(record)
      end

      def serialize_outbound(attributes)
        attributes.keys.reduce({}) do |map, key|
          case key
          when 'hosts', 'uris', 'methods'
            map[key] = attributes[key].join(',')
          else
            map[key] = attributes[key]
          end

          map
        end
      end
    end
  end
end
