module Astrails
  module Safe
    module Config
      class Builder
        COLLECTIONS = %w/database archive/
        ITEMS = %w/s3 key secret bucket path gpg password keep local mysqldump options
        user socket tar files exclude filename/
        NAMES = COLLECTIONS + ITEMS
        def initialize(node)
          @node = node
        end

        # supported args:
        #   args = [value]
        #   args = [id, data]
        #   args = [data]
        # id/value - simple values, data - hash
        def method_missing(sym, *args, &block)
          return super unless NAMES.include?(sym.to_s)

          # do we have id or value?
          unless args.first.is_a?(Hash)
            id_or_value = args.shift # nil for args == []
          end

          # do we have data hash?
          if data = args.shift
            die "#{sym}: hash expected: #{data.inspect}" unless data.is_a?(Hash)
          end

          #puts "#{sym}: args=#{args.inspect}, id_or_value=#{id_or_value}, data=#{data.inspect}, block=#{block.inspect}"

          die "#{sym}: unexpected: #{args.inspect}" unless args.empty?
          die "#{sym}: missing arguments" unless id_or_value || data || block

          if COLLECTIONS.include?(sym.to_s) && id_or_value
            data ||= {}
          end

          if !data && !block
            # simple value assignment
            @node[sym] = id_or_value

          elsif id_or_value
            # collection element with id => create collection node and a subnode in it
            key = sym.to_s + "s"
            collection = @node[key] || @node.set(key, {})
            collection.set(id_or_value, data || {}, &block)

          else
            # simple subnode
            @node.set(sym, data || {}, &block)
          end
        end
      end
    end
  end
end
