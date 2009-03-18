module Astrails
  module Safe
    class Gpg < Pipe

      protected

      def pipe
        if key
          rise RuntimeError, "can't use both gpg password and pubkey" if password
          "|gpg -e -r #{key}"
        elsif password
          "|gpg -c --passphrase-file #{gpg_password_file(password)}"
        end
      end

      def extension
        ".gpg" if active?
      end

      def active?
        password || key
      end

      def password
        @password ||= config[:gpg, :password]
      end

      def key
        @key ||= config[:gpg, :key]
      end

      def gpg_password_file(pass)
        return "TEMP_GENERATED_FILENAME" if $DRY_RUN
        Astrails::Safe::TmpFile.create("gpg-pass") { |file| file.write(pass) }
      end
    end
  end
end
