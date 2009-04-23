require 'extensions/mktmpdir'
require 'astrails/safe/tmp_file'

require 'astrails/safe/config/node'
require 'astrails/safe/config/builder'

require 'astrails/safe/stream'

require 'astrails/safe/source'
require 'astrails/safe/mysqldump'
require 'astrails/safe/archive'

require 'astrails/safe/pipe'
require 'astrails/safe/gpg'
require 'astrails/safe/gzip'

require 'astrails/safe/sink'
require 'astrails/safe/local'
require 'astrails/safe/s3'

require 'astrails/safe/svndump'

module Astrails
  module Safe
    ROOT = File.join(File.dirname(__FILE__), "..", "..")

    def timestamp
      @timestamp ||= Time.now.strftime("%y%m%d-%H%M")
    end

    def safe(&block)
      config = Config::Node.new(&block)
      #config.dump

      Astrails::Safe::Mysqldump.run(config[:mysqldump, :databases])
      Astrails::Safe::Archive.run(config[:tar, :archives])
      Astrails::Safe::Svndump.run(config[:svndump, :repos])
      
      Astrails::Safe::TmpFile.cleanup
    end
  end
end