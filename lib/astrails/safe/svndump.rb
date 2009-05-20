module Astrails
  module Safe
    class Svndump < Source

      def command
        "svnadmin dump #{@config[:options]} #{@config[:repo_path]}"
      end

      def extension; '.svn'; end

    end
  end
end
