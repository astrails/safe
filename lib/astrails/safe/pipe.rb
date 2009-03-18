module Astrails
  module Safe
    class Pipe < Command

      def compressed?
        active? || @parent.compressed?
      end

      def command
        "#{@parent.command}#{pipe}"
      end

      def filename
        "#{@parent.filename}#{extension}"
      end

    end
  end
end
