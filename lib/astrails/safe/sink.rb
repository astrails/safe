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

      def store
        return @store if @store

        @store = [*(config[:store] || [:local])]

        unsupported = @store - [:local, :s3]
        raise(RuntimeError, "invalid storage engine: #{unsupported.inspect}") unless unsupported.empty?

        raise(RuntimeError, "Need at least one storage (:local or :s3)") if @store.empty?

        @store
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

