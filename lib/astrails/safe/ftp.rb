module Astrails
  module Safe
    class Ftp < Sink

      protected

      def active?
        host && user
      end

      def path
        @path ||= expand(config[:ftp, :path] || config[:local, :path] || ":kind/:id")
      end

      def save
        raise RuntimeError, "pipe-streaming not supported for FTP." unless @backup.path

        puts "Uploading #{host}:#{full_path} via FTP" if $_VERBOSE || $DRY_RUN

        unless $DRY_RUN || $LOCAL
          if !port
            port = 21
          end
          Net::FTP.open(host) do |ftp|
            ftp.connect(host, port)
            ftp.login(user, password)
            puts "Sending #{@backup.path} to #{full_path}" if $_VERBOSE
            begin
              ftp.put(@backup.path, full_path)
            rescue Net::FTPPermError
              puts "Ensuring remote path (#{path}) exists" if $_VERBOSE
            end
          end
          puts "...done" if $_VERBOSE
        end
      end

      def cleanup
        return if $LOCAL || $DRY_RUN

        return unless keep = @config[:keep, :ftp]

        puts "listing files: #{host}:#{base}*" if $_VERBOSE
        if !port
           port = 21
        end
        Net::FTP.open(host) do |ftp|
          ftp.connect(host, port)
          ftp.login(user, password)
          files = ftp.nlst(path)
          pattern = File.basename("#{base}")
          files = files.reject{ |x| !x.start_with?(pattern)}
          puts files.collect {|x| x} if $_VERBOSE

          files = files.
            collect {|x| x }.
            sort

          cleanup_with_limit(files, keep) do |f|
            file = File.join(path, f)
            puts "removing ftp file #{host}:#{file}" if $DRY_RUN || $_VERBOSE
            ftp.delete(file) unless $DRY_RUN || $LOCAL
          end
        end
      end

      def host
        @config[:ftp, :host]
      end

      def user
        @config[:ftp, :user]
      end

      def password
        @config[:ftp, :password]
      end

      def port
        @config[:ftp, :port]
      end

    end
  end
end