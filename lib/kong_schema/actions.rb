module KongSchema
  # TODO: make a validation pass before #apply
  module Actions
    class Create
      attr_reader :model, :params

      def initialize(model:, params:)
        @model = model
        @params = params
      end

      def apply(*)
        @model.create(@params)
      end
    end

    class Update
      attr_reader :model, :params, :record

      def initialize(model:, record:, params:)
        @model = model
        @params = params
        @record = record
      end

      def apply(*)
        @model.update(@record, @params)
      end
    end

    class Delete
      attr_reader :model, :record

      def initialize(model:, record:)
        @model = model
        @record = record
      end

      def apply(*)
        @model.delete(@record)
      end
    end
  end
end
