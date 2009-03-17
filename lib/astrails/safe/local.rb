module Astrails
  module Safe
    class Local < Storage

      def run
        @stream.run
        cleanup
      end

      def cleanup
        return unless keep = @config[:keep, :local]

        dir = File.dirname(filename)
        base = File.basename(filename).split(".").first

        files = Dir[File.join(dir, "#{base}*")] .
          select{|f| File.file?(f)} .
          sort

        cleanup_with_limit(files, keep) do |f|
          puts "removing local file #{f}" if $DRY_RUN || $_VERBOSE
          File.unlink(f) unless $DRY_RUN
        end
      end

    end
  end
end
