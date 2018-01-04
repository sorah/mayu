module Mayu
  module Relation
    def self.included(klass)
      klass.extend ClassMethods
    end

    def _ensure_relation_finders_satisfied!
      self.class.relations.map do |k|
        unless instance_variable_get(:"@_#{k}_finder")
          raise "#{k.class}: #{k.inspect} not satisfied"
        end
      end
    end

    module ClassMethods
      def relations
        @_relations ||= []
      end
      def relates(name)
        self.relations << name

        key_exist = self.instance_methods.include?(:"#{name}_key")
        self.class_eval(<<-EOF, __FILE__, __LINE__ + 1)
          def _#{name}_finder=(x)
            @_#{name}_finder = x
          end

          def _#{name}
            @_#{name}
          end

          def _#{name}=(x)
            key = #{key_exist ? "#{name}_key" : 'nil'}
            @_#{name}_key = key
            @_#{name} = x
          end

          def #{name}
            raise "#{name} finder not set" unless @_#{name}_finder
            key = #{key_exist ? "#{name}_key" : 'nil'}
            if @_#{name}_key && @_#{name}_key != key
              @_#{name} = nil
            end
            self._#{name} ||= @_#{name}_finder[key]
          end
        EOF
      end
    end
  end
end
