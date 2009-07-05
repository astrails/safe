module Astrails
  module Safe
    class Sink < Stream

      def process
        return unless active?

        save
        cleanup
      end

      protected

      # path is defined in subclass
      def base
        @base ||= File.join(path, File.basename(@backup.filename).split(".").first + '.')
      end

      def full_path
        @full_path ||= File.join(path, @backup.filename) + @backup.extension
      end

      # call block on files to be removed (all except for the LAST 'limit' files
      def cleanup_with_limit(files, limit, &block)
        return unless files.size > limit

        to_remove = files[0..(files.size - limit - 1)]
        # TODO: validate here
        to_remove.each(&block)
      end
    end
  end
end