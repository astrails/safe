require 'tmpdir'
module Astrails
  module Safe
    module TmpFile
      @keep_files = []

      def self.tmproot
        @tmproot ||= Dir.mktmpdir
      end

      def self.cleanup
        FileUtils.remove_entry_secure tmproot
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
