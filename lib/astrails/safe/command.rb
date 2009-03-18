module Astrails
  module Safe
    class Command < Stream

      def open(&block)
        raise(RuntimeError, "Can't open twice") if @opened

        @opened = true
        puts "command: #{command}" if $_VERSBOSE
        popen(command, &block) unless $DRY_RUN
      end

    end
  end
end
