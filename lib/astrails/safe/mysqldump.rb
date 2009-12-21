module Astrails
  module Safe
    class Mysqldump < Source

      def command
        "mysqldump --defaults-extra-file=#{mysql_password_file} #{@config[:options]} #{mysql_skip_tables} #{@id}"
      end

      def extension; '.sql'; end

      protected

      def mysql_password_file
        Astrails::Safe::TmpFile.create("mysqldump") do |file|
          file.puts "[mysqldump]"
          %w/user password socket host port/.each do |k|
            v = @config[k]
            # values are quoted if needed
            file.puts "#{k} = #{v.inspect}" if v
          end
        end
      end

      def mysql_skip_tables
        if skip_tables = @config[:skip_tables]
          [*skip_tables].map { |t| "--ignore-table=#{@id}.#{t}" } * " "
        end
      end

    end
  end
end