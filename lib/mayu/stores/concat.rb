require 'mayu/stores/base'

module Mayu
  module Stores
    class Concat < Base
      def initialize(stores:)
        @stores = stores
      end

      attr_reader :stores

      def put(obj)
        raise NotImplementedError, "this store is read only"
      end

      def get
        objs = @stores.map(&:get)
        keys = objs.flat_map(&:keys).uniq

        r = {}
        objs.each do |i|
          keys.each do |k|
            next unless i[k]
            case r[k]
            when Array
              r[k] ||= []
              r[k] += i[k]
            when Hash
              r[k] ||= {}
              r[k] = r[k].merge(i[k])
            else
              r[k] = i[k]
            end
          end
        end
        r
      end
    end
  end
end

