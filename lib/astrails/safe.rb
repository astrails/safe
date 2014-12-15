require "aws-sdk"
require "cloudfiles"
require 'net/sftp'
require 'fileutils'
require 'benchmark'
require 'toadhopper'
require 'raven'

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

require 'astrails/safe/version'

module Astrails
  module Safe
    ROOT = File.join(File.dirname(__FILE__), "..", "..")

    def safe(&block)
      config = Config::Node.new(&block)

      begin
        [[Mysqldump, [:mysqldump, :databases]],
         [Pgdump,    [:pgdump,    :databases]],
         [Mongodump, [:mongodump, :databases]],
         [Archive,   [:tar,       :archives]],
         [Svndump,   [:svndump,   :repos]]
        ].each do |klass, path|
          if collection = config[*path]
            collection.each do |name, config|
              klass.new(name, config).backup.run(config, :gpg, :gzip, :local, :s3, :cloudfiles, :sftp)
            end
          end
        end
      rescue => e
        begin
          if config["airbrake"]
            toad = Toadhopper.new(config["airbrake"]["api_key"])
            toad.post!(e)
          end
          if config['raven']
            Raven.configure do |raven_config|
              raven_config.dsn = config['raven']['dsn']
            end
            Raven.capture_exception(e)
          end
        rescue => e
          STDERR.puts "Error sending notification: #{e.class}, #{e.message}"
          STDERR.puts e.backtrace
        end
      ensure
        Astrails::Safe::TmpFile.cleanup
      end
    end
    module_function :safe
  end
end
