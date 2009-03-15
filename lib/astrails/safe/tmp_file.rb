require 'tmpdir'
module Astrails
  module Safe
    module TmpFile
      @KEEP_FILES = []
      TMPDIR = Dir.mktmpdir

      def self.create(name)
        # create temp directory

        file = Tempfile.new(name, TMPDIR)

        yield file

        file.close
        @KEEP_FILES << file # so that it will not get gcollected and removed from filesystem until the end
        file.path
      end
    end
  end
end
