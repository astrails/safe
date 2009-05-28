require "aws/s3"
require 'fileutils'
require 'benchmark'

require 'tempfile'
require 'extensions/mktmpdir'

require 'astrails/safe/tmp_file'

require 'astrails/safe/config/node'
require 'astrails/safe/config/builder'

require 'astrails/safe/stream'

require 'astrails/safe/backup'

require 'astrails/safe/backup'

require 'astrails/safe/source'
require 'astrails/safe/mysqldump'
require 'astrails/safe/pgdump'
require 'astrails/safe/archive'
require 'astrails/safe/svndump'

require 'astrails/safe/pipe'
require 'astrails/safe/gpg'
require 'astrails/safe/gzip'

require 'astrails/safe/sink'
require 'astrails/safe/local'
require 'astrails/safe/s3'


module Astrails
  module Safe
    ROOT = File.join(File.dirname(__FILE__), "..", "..")

    def safe(&block)
      config = Config::Node.new(&block)
      #config.dump


      [[Astrails::Safe::Mysqldump, [:mysqldump, :databases]],
       [Astrails::Safe::Pgdump, [:pgdump, :databases]],
       [Astrails::Safe::Archive, [:tar, :archives]],
       [Astrails::Safe::Svndump, [:svndump, :repos]]
      ].each do |klass, path|
        if collection = config[*path]
          collection.each do |name, config|
            klass.new(name, config).backup.run(config, :gpg, :gzip, :local, :s3)
          end
        end
      end

      Astrails::Safe::TmpFile.cleanup
    end
    module_function :safe
  end
end
