require 'tmpdir'
module Astrails
  module Safe
    module TmpFile
      @keep_files = []

      def self.tmproot
        @tmproot ||= Dir.mktmpdir
      end

      def self.cleanup
        begin
          FileUtils.remove_entry_secure tmproot
        rescue ArgumentError => e
          if e.message =~ /parent directory is world writable/
            puts <<-ERR


********************************************************************************
It looks like you have wrong permissions on your TEMP directory.  The usual
case is when you have world writable TEMP directory withOUT the sticky bit.

Try "chmod +t" on it.

********************************************************************************

ERR
          else
            raise
          end
        end
        @tmproot = nil
      end

      def self.create(name)
        # create temp directory

        file = Tempfile.new(name, tmproot)

        yield file

        file.close
        @keep_files << file # so that it will not get gcollected and removed from filesystem until the end
        file.path
      end
    end
  end
end
