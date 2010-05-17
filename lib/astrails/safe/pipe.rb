module Astrails
  module Safe
    class Pipe < Stream
      # process adds required commands to the current
      # shell command string
      # :active?, :pipe, :extension and :post_process are
      # defined in inheriting pipe classes
      def process
        return unless active?

        @backup.command << pipe
        @backup.extension << extension
        post_process
      end
    end
  end
end
