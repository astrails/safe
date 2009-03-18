module Astrails
  module Safe
    class Stream

      def initialize(parent)
        @parent = parent
      end

      def id
        @id ||= @parent.id
      end

      def config
        @config ||= @parent.config
      end

      def filename
        @parent.filename
      end

      def compressed?
        @parent && @parent.compressed?
      end

      protected

      def name
        self.class.name.split('::').last.downcase
      end

      def kind
        @parent ? @parent.kind : name
      end

      def expand(path)
        path .
          gsub(/:kind\b/, kind) .
          gsub(/:id\b/, id) .
          gsub(/:timestamp\b/, timestamp)
      end

    end
  end
end

