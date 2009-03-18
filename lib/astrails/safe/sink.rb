module Astrails
  module Safe
    class Sink < Stream

      def run
        if active?
          save
          cleanup
        else
          @parent.run
        end
      end

      protected

      # prefix is defined in subclass
      def path
        @path ||= File.join(prefix, filename)
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

