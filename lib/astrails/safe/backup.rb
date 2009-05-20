module Astrails
  module Safe
    class Backup
      attr_accessor :id, :kind, :filename, :extension, :command, :compressed, :timestamp, :path
      def initialize(opts = {})
        opts.each do |k, v|
          self.send("#{k}=", v)
        end
      end

      def run(config, *mods)
        mods.each do |mod|
          mod = mod.to_s
          mod[0] = mod[0..0].upcase
          Astrails::Safe.const_get(mod).new(config, self).process
        end
      end
    end
  end
end