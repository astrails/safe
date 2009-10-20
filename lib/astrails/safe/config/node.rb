require 'astrails/safe/config/builder'
module Astrails
  module Safe
    module Config
      class Node
        attr_reader :parent
        attr_reader :data
        def initialize(parent = nil, data = {}, &block)
          @parent, @data = parent, {}
          data.each { |k, v| self[k] = v }
          Builder.new(self).instance_eval(&block) if block
        end

        # looks for the path from this node DOWN. will not delegate to parent
        def get(*path)
          key = path.shift
          value = @data[key.to_s]
          return value if value && path.empty?

          value && value.get(*path)
        end

        # recursive find
        # starts at the node and continues to the parent
        def find(*path)
          get(*path) || @parent && @parent.find(*path)
        end
        alias :[] :find

        MULTIVALUES = %w/skip_tables exclude files/
        def set(key, value, &block)
          if @data[key.to_s]
            raise(ArgumentError, "duplicate value for '#{key}'") if value.is_a?(Hash) || !MULTIVALUES.include?(key.to_s)
          end

          if value.is_a?(Hash)
            @data[key.to_s] = Node.new(self, value, &block)
          else
            raise(ArgumentError, "#{key}: no block supported for simple values") if block
            if @data[key.to_s]
              @data[key.to_s] = @data[key.to_s].to_a + value.to_a
            else
              @data[key.to_s] = value
            end
            value
          end
        end
        alias :[]= :set

        def each(&block)
          @data.each(&block)
        end
        include Enumerable

        def to_hash
          @data.keys.inject({}) do |res, key|
            value = @data[key]
            res[key] = value.is_a?(Node) ? value.to_hash : value
            res
          end
        end

        def dump(indent = "")
          @data.each do |key, value|
            if value.is_a?(Node)
              puts "#{indent}#{key}:"
              value.dump(indent + "    ")
            else
              puts "#{indent}#{key}: #{value.inspect}"
            end
          end
        end
      end
    end
  end
end
