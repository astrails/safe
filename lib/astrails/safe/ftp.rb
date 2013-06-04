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

        puts "Uploading #{host}:#{full_path} via FTP" if verbose? || dry_run?

        unless dry_run? || local_only?
          if !port
            port = 21
          end
          Net::FTP.open(host) do |ftp|
            ftp.connect(host, port)
            ftp.login(user, password)
            puts "Sending #{@backup.path} to #{full_path}" if verbose?
            begin
              ftp.put(@backup.path, full_path)
            rescue Net::FTPPermError
              puts "Ensuring remote path (#{path}) exists" if verbose?
            end
          end
          puts "...done" if verbose?
        end
      end

      def cleanup
        return if local_only? || dry_run?

        return unless keep = config[:keep, :ftp]

        puts "listing files: #{host}:#{base}*" if verbose?
        if !port
           port = 21
        end
        Net::FTP.open(host) do |ftp|
          ftp.connect(host, port)
          ftp.login(user, password)
          files = ftp.nlst(path)
          pattern = File.basename("#{base}")
          files = files.reject{ |x| !x.start_with?(pattern)}
          puts files.collect {|x| x} if verbose?

          files = files.
            collect {|x| x }.
            sort

          cleanup_with_limit(files, keep) do |f|
            file = File.join(path, f)
            puts "removing ftp file #{host}:#{file}" if dry_run? || verbose?
            ftp.delete(file) unless dry_run? || local_only?
          end
        end
      end

      def host
        config[:ftp, :host]
      end

      def user
        config[:ftp, :user]
      end

      def password
        config[:ftp, :password]
      end

      def port
        config[:ftp, :port]
      end

    end
  end
end