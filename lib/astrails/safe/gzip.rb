module Astrails
  module Safe
    class Gzip < Pipe

      protected

      def post_process
        @backup.compressed = true
      end

      def pipe
        "|gzip"
      end

      def extension
        ".gz"
      end

      def active?
        !@backup.compressed
      end

    end
  end
end