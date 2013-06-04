module Astrails
  module Safe
    class Stream

      attr_accessor :config, :backup
      def initialize(config, backup)
        @config, @backup = config, backup
      end
      # FIXME: move to Backup
      def expand(path)
        path .
        gsub(/:kind\b/, @backup.kind.to_s) .
        gsub(/:id\b/, @backup.id.to_s) .
        gsub(/:timestamp\b/, @backup.timestamp)
      end

      private

      def verbose?
        config[:verbose]
      end

      def local_only?
        config[:local_only]
      end

      def dry_run?
        config[:dry_run]
      end
    end
  end
end