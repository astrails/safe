module Astrails
  module Safe
    class Local < Sink

      def open(&block)
        return @parent.open(&block) unless active?
        run
        File.open(path, &block) unless $DRY_RUN
      end

      protected

      def active?
        # S3 can't upload from pipe. it needs to know file size, so we must pass through :local
        # will change once we add SSH sink
        true
      end

      def prefix
        @prefix ||= File.expand_path(expand(@config[:local, :path] || raise(RuntimeError, "missing :local/:path in configuration")))
      end

      def command
        "#{@parent.command} > #{path}"
      end

      def save
        puts "command: #{command}" if $_VERBOSE
        unless $DRY_RUN
          FileUtils.mkdir_p(prefix) unless File.directory?(prefix)
          system command
        end
      end

      def cleanup
        return unless keep = @config[:keep, :local]

        base = File.basename(filename).split(".").first

        pattern = File.join(prefix, "#{base}*")
        puts "listing files #{pattern.inspect}" if $_VERBOSE
        files = Dir[pattern] .
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
