module Astrails
  module Safe
    class Source < Stream

      def initialize(id, config)
        @id, @config = id, config
      end

      def filename
        @filename ||= expand(":kind-:id.:timestamp#{extension}")
      end

      # process each config key as source (with full pipe)
      def self.run(config)
        unless config
          puts "No configuration found for #{human_name}"
          return
        end

        config.each do |key, value|
          stream = [Gpg, Gzip, Local, S3].inject(new(key, value)) do |res, klass|
            klass.new(res)
          end
          stream.run
        end
      end

    end
  end
end

