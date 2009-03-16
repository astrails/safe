module Astrails
  module Safe
    class Archive < Engine

      def command
        "tar -cf - #{@config[:options]} #{tar_exclude_files} #{tar_files}"
      end

      def backup_filename
        @backup_filename ||= "archive-#{@id}.#{timestamp}.tar"
      end

      protected

      def default_path
        "archive/#{@id}"
      end

      def tar_exclude_files
        [*@config[:exclude]].compact.map{|x| "--exclude=#{x}"} * " "
      end

      def tar_files
        raise RuntimeError, "missing files for tar" unless @config[:files]
        [*@config[:files]] * " "
      end

    end
  end
end
