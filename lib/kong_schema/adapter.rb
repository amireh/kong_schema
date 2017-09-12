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

    def changed?(record, directive)
      directive.keys.any? do |key|
        !record.send(key).eql?(directive[key])
      end
    end

    def update(record, params)
      params.keys.each do |key|
        record.send "#{key}=", params[key]
      end

      record.save
    end

    def delete(record)
      record.delete
    end
  end
end
