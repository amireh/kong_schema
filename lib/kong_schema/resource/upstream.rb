# frozen_string_literal: true

require 'kong'
require_relative '../adapter'

module KongSchema
  module Resource
    # https://getkong.org/docs/0.11.x/admin-api/#upstream-objects
    module Upstream
      extend self

      def identify(record)
        case record
        when Kong::Upstream
          record.name
        when Hash
          record['name']
        end
      end

      def all(*)
        Kong::Upstream.all
      end

      def create(attributes)
        Adapter.for(Kong::Upstream).create(attributes)
      end

      def changed?(record, attributes)
        Adapter.for(Kong::Upstream).changed?(record, attributes)
      end

      def update(record, partial_attributes)
        Adapter.for(Kong::Upstream).update(record, partial_attributes)
      end

      def delete(record)
        Adapter.for(Kong::Upstream).delete(record)
      end
    end
  end
end
