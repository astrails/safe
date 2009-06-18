module Astrails
  module Safe
    class Sftp < Sink

      protected

      def active?
        hostname && username && password
      end

      def path
        @path ||= expand(config[:sftp, :path] || config[:local, :path] || ":kind/:id")
      end

      def save
        puts "Uploading #{hostname}:#{full_path} via SFTP" if $_VERBOSE || $DRY_RUN
        
        unless $DRY_RUN || $LOCAL
          Net::SFTP.start(hostname, username, :password => password) do |sftp|            
            puts "Sending #{@backup.path} to #{full_path}" if $_VERBOSE
            begin
              sftp.upload! @backup.path, full_path
            rescue Net::SFTP::StatusException
              puts "Ensuring remote path (#{path}) exists" if $_VERBOSE
              # mkdir -p
              folders = path.split('/')
              folders.each_index do |i|
                folder = folders[0..i].join('/')
                puts "Creating #{folder} on remote" if $_VERBOSE
                sftp.mkdir!(folder) rescue Net::SFTP::StatusException
              end
              retry
            end
          end
          puts "...done" if $_VERBOSE
        end
      end

      def cleanup
        return if $LOCAL || $DRY_RUN

        return unless keep = @config[:keep, :sftp]

        puts "listing files in #{hostname}:#{path}" if $_VERBOSE
        Net::SFTP.start(hostname, username, :password => password) do |sftp|
          files = sftp.dir.glob(path, '*')
          
          puts files.collect {|x| x.name } if $_VERBOSE
          
          files = files.
            collect {|x| x.name }.
            sort
          
          cleanup_with_limit(files, keep) do |f|
            file = File.join(path, f)
            puts "removing sftp file #{hostname}:#{file}" if $DRY_RUN || $_VERBOSE
            sftp.remove!(file) unless $DRY_RUN || $LOCAL
          end
        end
      end
      
      def hostname
        @config[:sftp, :hostname]
      end

      def username
        @config[:sftp, :username]
      end
      
      def password
        @config[:sftp, :password]
      end
    end
  end
end