module Astrails
  module Safe
    class Stream

      attr_accessor :config, :command, :filename
      def initialize(config, command, filename)
        @config, @command, @filename = config, command, filename
      end

      def run
        encrypt || compress # use gpg or gzip
        redirect
        execute
      end

      private

      def gpg_password_file(pass)
        Astrails::Safe::TmpFile.create("gpg-pass") { |file| file.write(pass) }
      end

      def encrypt

        password = @config[:gpg, :password]
        key      = @config[:gpg, :key]

        return false unless key || password

        if key
          rise RuntimeError, "can't use both gpg password and pubkey" if password

          @filename << ".gpg"
          @command << "|gpg -e -r #{key}"
        else
          @filename << ".gpg"
          unless $DRY_RUN
            @command << "|gpg -c --passphrase-file #{gpg_password_file(password)}"
          else
            @command << "|gpg -c --passphrase-file TEMP_GENERATED_FILENAME"
          end
        end
        true
      end

      def compress
        @filename << ".gz"
        @command << "|gzip"
      end

      def redirect
        @command << ">" << @filename
      end

      def execute
        dir = File.dirname(filename)
        FileUtils.mkdir_p(dir) unless File.directory?(dir) || $DRY_RUN

        # EXECUTE
        puts "Backup command: #{@command}" if $DRY_RUN || $_VERBOSE
        system @command unless $DRY_RUN
      end

    end
  end
end
