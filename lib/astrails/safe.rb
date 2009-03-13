require 'astrails/safe/config/node'

module Astrails
  module Safe
    def safe(&block)
      $root = Config::Node.new(&block)
      #$root.dump
    end
  end
end

