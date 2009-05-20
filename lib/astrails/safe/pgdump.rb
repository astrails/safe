module Astrails
  module Safe
    class Pgdump < Source

      def command
        @commanbd ||= "pg_dump #{postgres_options} #{postgres_username} #{postgres_password} #{postgres_host} #{postgres_port} #{@id}"
#        @commanbd ||= "pg_dump -U #{@config["user"]} #{@config[:option]} #{@config["database"]} -f #{filename}"
#        @commanbd ||= "mysqldump --defaults-extra-file=#{mysql_password_file} #{@config[:options]} #{mysql_skip_tables} #{@id}"
      end

      def extension; '.sql'; end

      protected

      def postgres_options
        @config[:options]
      end

      def postgres_host
        @config["host"] ? "--host='#{@config["port"]}'" : ""
      end

      def postgres_port
        @config["port"] ? "--port='#{@config["port"]}'" : ""
      end

      def postgres_username
        @config["user"] ? "--username='#{@config["user"]}'" : ""
      end

      def postgres_password
        `export PGPASSWORD=#{@config["password"]}` if @config["password"]
      end

      def postgres_skip_tables
        if skip_tables = @config[:skip_tables]
          [*skip_tables].map { |t| "--exclude-table=#{@id}.#{t}" } * " "
        end
      end

    end
  end
end
