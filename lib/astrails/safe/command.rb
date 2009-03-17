module Astrails
  module Safe
    class Command

      attr_reader :config, :command, :filename
      def initialize(config, command, filename)
        @config, @command, @filename = config, command, filename
        encrypt || compress # use gpg or gzip
        puts "Backup command: #{@command}" if $DRY_RUN || $_VERBOSE
      end

      def run
        return if @executed
        raise(RuntimeError, "Can't run after open") if @opened

        dir = File.dirname(filename)
        FileUtils.mkdir_p(dir) unless File.directory?(dir) || $DRY_RUN

        # EXECUTE
        redirect
        @executed = true
        system @command unless $DRY_RUN
      end

      def open(&block)
        # STREAM
        raise(RuntimeError, "Can't open twice") if @opened

        if @executed
          open(filename, &block) unless $DRY_RUN
        else
          @opened = true
          popen(@command, &block) unless $DRY_RUN
        end
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

    end
  end
end
