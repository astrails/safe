module Astrails
  module Safe
    class Source < Command

      def initialize(id, config, timestamp)
        @id, @config, @timestamp = id, config, timestamp
      end

      def filename
        @filename ||= expand(":kind-:id.:timestamp#{extension}")
      end

      # process each config key as source (with full pipe)
      def self.run(config, timestamp)
        unless config
          puts "No configuration found for #{kind}"
          return
        end

        config.each do |key, value|
          stream = [Gpg, Gzip, Local, S3].inject(new(key, value, timestamp)) do |res, klass|
          klass.new(res)
          end
          stream.run
        end
      end

    end
  end
end

