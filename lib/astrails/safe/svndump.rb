module Astrails
  module Safe
    class Svndump < Source

      def command
        @command ||= "svnadmin dump #{@config[:repo_path]}"
      end

      def extension; '.svn'; end

    end
  end
end
