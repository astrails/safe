require "astrails/safe/version"

require "aws/s3"
require "cloudfiles"
require 'net/sftp'
require 'net/ftp'
require 'fileutils'
require 'benchmark'

require 'tempfile'
require 'extensions/mktmpdir'

require 'astrails/safe/tmp_file'

require 'astrails/safe/config/node'
require 'astrails/safe/config/builder'

require 'astrails/safe/stream'

require 'astrails/safe/backup'

require 'astrails/safe/source'
require 'astrails/safe/mysqldump'
require 'astrails/safe/pgdump'
require 'astrails/safe/archive'
require 'astrails/safe/svndump'
require 'astrails/safe/mongodump'

require 'astrails/safe/pipe'
require 'astrails/safe/gpg'
require 'astrails/safe/gzip'

require 'astrails/safe/sink'
require 'astrails/safe/local'
require 'astrails/safe/s3'
require 'astrails/safe/cloudfiles'
require 'astrails/safe/sftp'
require 'astrails/safe/ftp'

module Astrails
  module Safe
    ROOT = File.join(File.dirname(__FILE__), "..", "..")

    def safe(&block)
      Config::Node.new(&block)
    end

    def process(config)

      [[Mysqldump, [:mysqldump, :databases]],
       [Pgdump,    [:pgdump,    :databases]],
       [Mongodump, [:mongodump, :databases]],
       [Archive,   [:tar,       :archives]],
       [Svndump,   [:svndump,   :repos]]
      ].each do |klass, path|
        if collection = config[*path]
          collection.each do |name, c|
            klass.new(name, c).backup.run(c, :gpg, :gzip, :local, :s3, :cloudfiles, :sftp, :ftp)
          end
        end
      end

      Astrails::Safe::TmpFile.cleanup
    end
    module_function :safe
    module_function :process
  end
end
