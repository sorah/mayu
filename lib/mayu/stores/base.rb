require 'time'
module Mayu
  module Stores
    class Base
      def initialize(**options)
        @options = options
      end

      def put(obj)
        raise NotImplementedError
      end

      def get
        raise NotImplementedError
      end

      def for_json(obj)
        case obj
        when Array
          obj.map{ |_| for_json(_) }
        when Hash
          obj.transform_values { |v| v.is_a?(Time) ? v.xmlschema : for_json(v) }
        else
          obj
        end
      end

      def from_json(obj)
        case obj
        when Array
          obj.map do |v|
            from_json(v)
          end
        when Hash
          obj.map do |k,v|
            [k, k.to_s.end_with?('_at') ? (v && Time.xmlschema(v)) : from_json(v)]
          end.to_h
        else
          obj
        end
      end
    end
  end
end
