module Astrails
  module Safe
    class Pipe < Stream

      def command
        "#{@parent.command}#{pipe}"
      end

      def filename
        "#{@parent.filename}#{extension}"
      end

    end
  end
end
