module Astrails
  module Safe
    class Gzip < Pipe

      protected

      def pipe
        "|gzip" if active?
      end

      def extension
        ".gz" if active?
      end

      def active?
        !@parent.compressed?
      end

    end
  end
end
