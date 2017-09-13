module KongSchema
  module Functional
    def blank?(object)
      object.nil? || object.empty?
    end

    def try(recv, meth)
      if recv.nil?
        nil
      else
        recv.send(meth)
      end
    end
  end
end
