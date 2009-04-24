module Astrails
  module Safe
    class Stream

      attr_accessor :config, :backup
      def initialize(config, backup)
        @config, @backup = config, backup
      end

      def expand(path)
        path .
        gsub(/:kind\b/, @backup.kind.to_s) .
        gsub(/:id\b/, @backup.id.to_s) .
        gsub(/:timestamp\b/, @backup.timestamp)
      end

    end
  end
end