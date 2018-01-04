require 'mayu/stores/base'
require 'json'

module Mayu
  module Stores
    class Memory < Base
      def initialize(**options)
        @obj = nil
      end

      def put(obj)
        @obj = obj
      end

      def get
        @obj
      end
    end
  end
end

