module Astrails
  module Safe
    class Sftp < Sink

      protected

      def active?
        host && user
      end

      def path
        @path ||= expand(config[:sftp, :path] || config[:local, :path] || ":kind/:id")
      end

      def save
        raise RuntimeError, "pipe-streaming not supported for SFTP." unless @backup.path

        puts "Uploading #{host}:#{full_path} via SFTP" if config[:verbose] || config[:dry_run]

        unless config[:dry_run] || config[:local_only]
          opts = {}
          opts[:password] = password if password
          opts[:port] = port if port
          Net::SFTP.start(host, user, opts) do |sftp|
            puts "Sending #{@backup.path} to #{full_path}" if config[:verbose]
            begin
              sftp.upload! @backup.path, full_path
            rescue Net::SFTP::StatusException
              puts "Ensuring remote path (#{path}) exists" if config[:verbose]
              # mkdir -p
              folders = path.split('/')
              folders.each_index do |i|
                folder = folders[0..i].join('/')
                puts "Creating #{folder} on remote" if config[:verbose]
                sftp.mkdir!(folder) rescue Net::SFTP::StatusException
              end
              retry
            end
          end
          puts "...done" if config[:verbose]
        end
      end

      def cleanup
        return if config[:local_only] || config[:dry_run]

        return unless keep = config[:keep, :sftp]

        puts "listing files: #{host}:#{base}*" if config[:verbose]
        opts = {}
        opts[:password] = password if password
        opts[:port] = port if port
        Net::SFTP.start(host, user, opts) do |sftp|
          files = sftp.dir.glob(path, File.basename("#{base}*"))

          puts files.collect {|x| x.name } if config[:verbose]

          files = files.
            collect {|x| x.name }.
            sort

          cleanup_with_limit(files, keep) do |f|
            file = File.join(path, f)
            puts "removing sftp file #{host}:#{file}" if config[:dry_run] || config[:verbose]
            sftp.remove!(file) unless config[:dry_run] || config[:local_only]
          end
        end
      end

      def host
        config[:sftp, :host]
      end

      def user
        config[:sftp, :user]
      end

      def password
        config[:sftp, :password]
      end

      def port
        config[:sftp, :port]
      end

    end
  end
end