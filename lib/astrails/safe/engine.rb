module Astrails
  module Safe
    class Engine

      def self.run(config, timestamp)
        unless config
          puts "No configuration found for #{kind}"
          return
        end
        config.each do |key, value|
          new(key, value, timestamp).run
        end
      end

      attr_accessor :timestamp
      attr_reader :id, :config
      def initialize(id, config, timestamp)
        @config, @id, @timestamp = config, id, timestamp
      end

      def run
        puts "#{kind}: #{@id}" if $_VERBOSE

        engines = @config[:store] || [:local]

        unsupported = engines - [:local, :s3]
        raise(RuntimeError, "invalid storage engine: #{unsupported.inspect}") unless unsupported.empty?

        stream = Command.new(@config, command, backup_filepath)

        stream = Local.new(@config, stream) if engines.include?(:local)
        stream = S3.new(@config, stream)    if engines.include?(:s3) && !$LOCAL

        stream.run
      end

      protected

      def self.kind
        name.split('::').last.downcase
      end
      def kind
        self.class.kind
      end

      def expand(path)
        path .
          gsub(/:kind\b/, kind) .
          gsub(/:id\b/, id) .
          gsub(/:timestamp\b/, timestamp)
      end

      def s3_prefix
        @s3_prefix ||= expand(@config[:s3, :prefix] || ":kind/:id")
      end

      def backup_filepath
        @backup_filepath ||= File.expand_path(expand(@config[:path] || raise(RuntimeError, "missing :path in configuration"))) << "." << extension
      end



    end
  end
end

