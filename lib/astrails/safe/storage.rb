module Astrails
  module Safe
    class Storage
      def initialize(config, stream)
        @config, @stream = config, stream
      end
      
      def filename
        @stream.filename
      end

      def open(&block)
        run
        @stream.open(&block)
      end

      # call block on files to be removed (all except for the LAST 'limit' files
      def cleanup_with_limit(files, limit, &block)
        return unless files.size > limit

        to_remove = files[0..(files.size - limit - 1)]
        to_remove.each(&block)
      end

    end
  end
end

