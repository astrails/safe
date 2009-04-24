module Astrails
  module Safe
    class S3 < Sink

      protected

      def active?
        bucket && key && secret
      end

      def prefix
        @prefix ||= expand(config[:s3, :path] || config[:local, :path] || ":kind/:id")
      end

      def save
        raise RuntimeError, "pipe-streaming not supported for S3." unless @backup.path

        # needed in cleanup even on dry run
        AWS::S3::Base.establish_connection!(:access_key_id => key, :secret_access_key => secret, :use_ssl => true) unless $LOCAL

        puts "Uploading #{bucket}:#{path}" if $_VERBOSE || $DRY_RUN
        unless $DRY_RUN || $LOCAL
          AWS::S3::Bucket.create(bucket)
          File.open(@backup.path) do |file|
            AWS::S3::S3Object.store(path, file, bucket)
          end
          puts "...done" if $_VERBOSE
        end
      end

      def cleanup
        return if $LOCAL

        return unless keep = @config[:keep, :s3]

        base = File.basename(filename).split(".").first

        puts "listing files in #{bucket}:#{prefix}/#{base}"
        files = AWS::S3::Bucket.objects(bucket, :prefix => "#{prefix}/#{base}", :max_keys => keep * 2)
        puts files.collect {|x| x.key} if $_VERBOSE

        files = files.
          collect {|x| x.key}.
          sort

        cleanup_with_limit(files, keep) do |f|
          puts "removing s3 file #{bucket}:#{f}" if $DRY_RUN || $_VERBOSE
          AWS::S3::Bucket.find(bucket)[f].delete unless $DRY_RUN || $LOCAL
        end
      end

      def bucket
        @config[:s3, :bucket]
      end

      def key
        @config[:s3, :key]
      end

      def secret
        @config[:s3, :secret]
      end

    end
  end
end
