# frozen_string_literal: true

module KongSchema
  class Adapter
    def self.for(model)
      new(model: model)
    end

    def initialize(model:)
      @model = model
    end

    def create(params)
      @model.create(params)
    end

    def changed?(current_attributes, next_attributes)
      next_attributes.keys.any? do |key|
        !current_attributes[key].eql?(next_attributes[key])
      end
    end

    def update(record, params)
      params.keys.each do |key|
        record.attributes[key] = params[key]
      end

      record.save
    end

    def delete(record)
      record.delete
    end
  end
end
