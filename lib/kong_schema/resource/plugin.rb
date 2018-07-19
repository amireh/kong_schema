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
          [
            record.name,
            api_bound?(record) ? record.api.name : nil,
            consumer_bound?(record) ? record.consumer_id : nil
          ]
        when Hash
          [
            record['name'],
            record['api_id'] || nil,
            record['consumer_id'] || nil
          ]
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
        # a plugin may be removed implicitly by the API if its context has been
        # removed like an Api or Consumer, so we need to refresh before
        # attempting to update it
        if deleted_by_owner?(record)
          return nil
        elsif partial_attributes['enabled'] == false
          delete(record)
        else
          Adapter.for(Kong::Plugin).update(
            record,
            partial_attributes.merge(
              'api_id' => api_bound?(record) ? record.api.id : nil
            )
          )
        end
      end

      def delete(record)
        Adapter.for(Kong::Plugin).delete(record)
      end

      private

      def api_bound?(record)
        !blank?(record.api_id)
      end

      def consumer_bound?(record)
        !blank?(record.consumer_id)
      end

      def deleted_by_owner?(record)
        if api_bound?(record) || consumer_bound?(record)
          Kong::Plugin.find(record.id).nil?
        else
          false
        end
      end
    end
  end
end
