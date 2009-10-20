module Astrails
  module Safe
    class Archive < Source

      def command
        "tar -cf - #{@config[:options]} #{tar_exclude_files} #{tar_files}"
      end

      def extension; '.tar'; end

      protected

      def tar_exclude_files
        [*@config[:exclude]].compact.map{|x| "--exclude=#{x}"} * " "
      end

      def tar_files
        raise RuntimeError, "missing files for tar" unless @config[:files]
        [*@config[:files]].map {|s| s.strip} * " "
      end

    end
  end
end
