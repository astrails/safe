module Astrails
  module Safe
    class Engine

      def self.run(config, timestamp)
        unless config
          puts "No configuration found for #{name}"
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
        puts "#{name}: #{@id}" if $_VERBOSE

        stream = Stream.new(@config, command, backup_filename)
        stream.run # execute backup comand. result is file stream.filename

        # UPLOAD
        upload(stream.filename)

        # CLEANUP
        cleanup_s3(stream.filename)
        cleanup_local(stream.filename)
      end

      protected

      def name
        self.class.name.split('::').last.downcase
      end

      # FIXME: rename to default_prefix ?
      def default_path
        "#{name}/#{@id}"
      end

      def upload(filename)

        bucket = @config[:s3, :bucket]
        key    = @config[:s3, :key]
        secret = @config[:s3, :secret]
        path   = @config[:s3, :path] || default_path

        return unless bucket && key && secret

        s3_path = File.join(path, File.basename(filename))

        puts "Uploading file #{filename} to #{bucket}/#{s3_path}" if $_VERBOSE || $DRY_RUN
        if $LOCAL
          puts "skip upload (local operation)"
        else
          # needed in cleanup even on dry run
          AWS::S3::Base.establish_connection!(:access_key_id => key, :secret_access_key => secret, :use_ssl => true)

          unless $DRY_RUN
            AWS::S3::Bucket.create(bucket)
            AWS::S3::S3Object.store(s3_path, open(filename), bucket)
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

        prefix = @config[:s3, :path] || default_path

        base = File.basename(filename).split(".").first

        puts "listing files in #{bucket}:#{prefix}"
        files = AWS::S3::Bucket.objects(bucket, :prefix => prefix, :max_keys => keep * 2)
        puts files.collect(&:key) if $_VERBOSE

        files = files.
          collect(&:key).
          select{|f| File.basename(f)[0..(base.length - 1)] == base}.
          sort

        cleanup_files(files, keep) do |f|
          puts "removing s3 file #{bucket}:#{f}" if $DRY_RUN || $_VERBOSE
          AWS::S3::Bucket.find(bucket)[f].delete unless $DRY_RUN
        end
      end

    end
  end
end

