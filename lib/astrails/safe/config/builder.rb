module Astrails
  module Safe
    module Config
      class Builder

        def initialize(node, data = {})
          @node = node
          data.each { |k, v| self.send k, v }
        end


        class << self
          def simple_value(*names)
            names.each do |m|
              define_method(m) do |value|
                ensure_uniq(m)
                @node.set m, value
              end
            end
          end

          def multi_value(*names)
            names.each do |m|
              define_method(m) do |value|
                value = value.map(&:to_s) if value.is_a?(Array)
                @node.set_multi m, value
              end
            end
          end

          def hash_value(*names)
            names.each do |m|
              define_method(m) do |data = {}, &block|
                ensure_uniq(m)
                ensure_hash(m, data)
                @node.set m, Node.new(@node, data || {}, &block)
              end
            end
          end

          def mixed_value(*names)
            names.each do |m|
              define_method(m) do |data={}, &block|
                ensure_uniq(m)
                if data.is_a?(Hash) || block
                  ensure_hash(m, data) if block
                  @node.set m, Node.new(@node, data, &block)
                else
                  @node.set m, data
                end
              end
            end
          end

          def collection(*names)
            names.each do |m|
              define_method(m) do |id, data={}, &block|
                raise "bad collection id: #{id.inspect}" unless id
                ensure_hash(m, data)

                name = "#{m}s"
                collection = @node.get(name) || @node.set(name, Node.new(@node, {}))
                collection.set id, Node.new(collection, data, &block)
              end
            end
          end
        end

        simple_value :verbose, :dry_run, :local_only, :path, :command,
          :options, :user, :host, :port, :password, :key, :secret, :bucket, :endpoint,
          :api_key, :container, :socket, :service_net, :repo_path
        multi_value :skip_tables, :exclude, :files
        hash_value :mysqldump, :tar, :gpg, :keep, :pgdump, :tar, :svndump,
          :sftp, :ftp, :mongodump
        mixed_value :s3, :local, :cloudfiles
        collection :database, :archive, :repo

        private

        def ensure_uniq(m)
          raise(ArgumentError, "duplicate value for '#{m}'") if @node.get(m)
        end

        def ensure_hash(k, v)
          raise "#{k}: hash expected: #{v.inspect}" unless v.is_a?(Hash)
        end
      end
    end
  end
end
