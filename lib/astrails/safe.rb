require 'astrails/safe/tmp_file'
require 'astrails/safe/config/node'
require 'astrails/safe/config/builder'
require 'astrails/safe/stream'
require 'astrails/safe/engine'
require 'astrails/safe/mysqldump'
require 'astrails/safe/archive'

module Astrails
  module Safe
    ROOT = File.join(File.dirname(__FILE__), "..", "..")

    def timestamp
      @timestamp ||= Time.now.strftime("%y%m%d-%H%M")
    end

    def safe(&block)
      config = Config::Node.new(&block)
      #config.dump

      Astrails::Safe::Mysqldump.run(config[:mysqldump, :databases], timestamp)
      Astrails::Safe::Archive.run(config[:tar, :archives], timestamp)
    end
  end
end

