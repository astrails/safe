module Astrails
  module Safe
    class Engine

      def self.run(config, timestamp)
        unless config
          puts "No configuration found for #{kind}"
          return
        end
        config.each do |key, value|
          new(key, value, timestamp).run
        end
      end

      attr_accessor :timestamp
      attr_reader :id, :config
      def initialize(id, config, timestamp)
        @config, @id, @timestamp = config, id, timestamp
      end

      def run
        puts "#{kind}: #{@id}" if $_VERBOSE

        stream = Stream.new(@config, command, backup_filepath)
        stream.run # execute backup comand. result is file stream.filename

        # UPLOAD
        upload(stream.filename)

        # CLEANUP
        cleanup_s3(stream.filename)
        cleanup_local(stream.filename)
      end

      protected

      def self.kind
        name.split('::').last.downcase
      end
      def kind
        self.class.kind
      end

      def expand(path)
        path .
          gsub(/:kind\b/, kind) .
          gsub(/:id\b/, id) .
          gsub(/:timestamp\b/, timestamp)
      end

      def s3_prefix
        @s3_prefix ||= expand(@config[:s3, :prefix] || ":kind/:id")
      end

      def backup_filepath
        @backup_filepath ||= File.expand_path(expand(@config[:path] || raise(RuntimeError, "missing :path in configuration"))) << "." << extension
      end


      def upload(filename)

        bucket = @config[:s3, :bucket]
        key    = @config[:s3, :key]
        secret = @config[:s3, :secret]

        return unless bucket && key && secret

        upload_path = File.join(s3_prefix, File.basename(filename))

        puts "Uploading file #{filename} to #{bucket}/#{upload_path}" if $_VERBOSE || $DRY_RUN
        if $LOCAL
          puts "skip upload (local operation)"
        else
          # needed in cleanup even on dry run
          AWS::S3::Base.establish_connection!(:access_key_id => key, :secret_access_key => secret, :use_ssl => true)

          unless $DRY_RUN
            AWS::S3::Bucket.create(bucket)
            AWS::S3::S3Object.store(upload_path, open(filename), bucket)
          end
        end
        puts "...done" if $_VERBOSE
      end

      # call block on files to be removed (all except for the LAST 'limit' files
      def cleanup_files(files, limit, &block)
        return unless files.size > limit

        to_remove = files[0..(files.size - limit - 1)]
        to_remove.each(&block)
      end

      def cleanup_local(filename)
        return unless keep = @config[:keep, :local]

        dir = File.dirname(filename)
        base = File.basename(filename).split(".").first

        files = Dir[File.join(dir, "#{base}*")] .
          select{|f| File.file?(f)} .
          sort

        cleanup_files(files, keep) do |f|
          puts "removing local file #{f}" if $DRY_RUN || $_VERBOSE
          File.unlink(f) unless $DRY_RUN
        end
      end

      def cleanup_s3(filename)

        return unless keep = @config[:keep, :s3]

        bucket = @config[:s3, :bucket]

        base = File.basename(filename).split(".").first

        puts "listing files in #{bucket}:#{s3_prefix}"
        files = AWS::S3::Bucket.objects(bucket, :prefix => "#{s3_prefix}/#{base}", :max_keys => keep * 2)
        puts files.collect {|x| x.key} if $_VERBOSE

        files = files.
          collect {|x| x.key}.
          sort

        cleanup_files(files, keep) do |f|
          puts "removing s3 file #{bucket}:#{f}" if $DRY_RUN || $_VERBOSE
          AWS::S3::Bucket.find(bucket)[f].delete unless $DRY_RUN
        end
      end

    end
  end
end

