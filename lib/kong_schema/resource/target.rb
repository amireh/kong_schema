# frozen_string_literal: true

require 'kong'
require_relative '../adapter'

module KongSchema
  module Resource
    module Target
      extend self

      def identify(record)
        case record
        when Kong::Target
          [record.upstream.name, record.target].to_json
        when Hash
          [record['upstream_id'], record['target']].to_json
        end
      end

      def all(*)
        Kong::Upstream.all.map(&:targets).flatten
      end

      def create(attributes)
        with_upstream(attributes) do |upstream|
          Adapter.for(Kong::Target).create(
            attributes.merge('upstream_id' => upstream.id)
          )
        end
      end

      def creatable?(*)
        true
      end

      def changed?(record, directive)
        (
          record.target != directive['target'] ||
          record.weight != directive.fetch('weight', 100) ||
          record.upstream.name != directive['upstream_id']
        )
      end

      def update(record, partial_attributes)
        delete(record)
        create(partial_attributes)
      end

      def delete(target)
        Adapter.for(Kong::Target).delete(target)
      end

      private

      def with_upstream(params)
        upstream = Kong::Upstream.find_by_name(params.fetch('upstream_id', ''))

        fail "Can not add a target without an upstream!" if upstream.nil?

        yield upstream
      end
    end
  end
end
