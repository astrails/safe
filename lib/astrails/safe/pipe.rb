module Astrails
  module Safe
    class Pipe < Stream
      def process
        return unless active?

        @backup.command << pipe
        @backup.extension << extension
        post_process
      end
    end
  end
end
