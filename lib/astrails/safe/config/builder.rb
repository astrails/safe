module Astrails
  module Safe
    module Config
      class Builder

        def initialize(node)
          @node = node
        end

        %w/database archive repo/.each do |m|
          define_method(m) do |id, data={}, &block|

            raise "bad collection id: #{id.inspect}" unless id
            raise "#{sym}: hash expected: #{data.inspect}" unless data.is_a?(Hash)

            name = m.to_s + 's'

            collection = @node[name] || @node.set(name, Node.new(@node, {}))

            collection.set id, Node.new(collection, data, &block)
          end
        end

        NAMES = %w/s3 cloudfiles key secret bucket api_key container service_net path gpg password keep local mysqldump pgdump command options
        user host port socket skip_tables tar files exclude filename svndump repo_path sftp ftp mongodump verbose dry_run local_only/
        MULTIVALUES = %w/skip_tables exclude files/
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

          id_or_value = id_or_value.map(&:to_s) if id_or_value.is_a?(Array)

          # do we have data hash?
          if data = args.shift
            raise "#{sym}: hash expected: #{data.inspect}" unless data.is_a?(Hash)
          end

          raise "#{sym}: unexpected: #{args.inspect}" unless args.empty?

          unless (nil != id_or_value) || data || block
            raise "#{sym}: missing arguments"
          end

          if !data && !block
            unless MULTIVALUES.include?(sym.to_s)
              if @node.get(sym)
                raise(ArgumentError, "duplicate value for '#{sym}'")
              end
            end

            # simple value assignment
            @node.set sym, id_or_value

          else
            # simple subnode
            @node.set sym, Node.new(@node, data || {}, &block)
          end
        end
      end
    end
  end
end
