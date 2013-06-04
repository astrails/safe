module Astrails
  module Safe
    class S3 < Sink
      MAX_S3_FILE_SIZE = 5368709120

      protected

      def active?
        bucket && key && secret
      end

      def path
        @path ||= expand(config[:s3, :path] || config[:local, :path] || ":kind/:id")
      end

      def save
        # FIXME: user friendly error here :)
        raise RuntimeError, "pipe-streaming not supported for S3." unless @backup.path

        # needed in cleanup even on dry run
        AWS::S3::Base.establish_connection!(:access_key_id => key, :secret_access_key => secret, :use_ssl => true) unless config[:local_only]

        puts "Uploading #{bucket}:#{full_path}" if config[:verbose] || config[:dry_run]
        unless config[:dry_run] || config[:local_only]
          if File.stat(@backup.path).size > MAX_S3_FILE_SIZE
            STDERR.puts "ERROR: File size exceeds maximum allowed for upload to S3 (#{MAX_S3_FILE_SIZE}): #{@backup.path}"
            return
          end
          benchmark = Benchmark.realtime do
            AWS::S3::Bucket.create(bucket) unless bucket_exists?(bucket)
            File.open(@backup.path) do |file|
              AWS::S3::S3Object.store(full_path, file, bucket)
            end
          end
          puts "...done" if config[:verbose]
          puts("Upload took " + sprintf("%.2f", benchmark) + " second(s).") if config[:verbose]
        end
      end

      def cleanup
        return if config[:local_only]

        return unless keep = config[:keep, :s3]

        puts "listing files: #{bucket}:#{base}*" if config[:verbose]
        files = AWS::S3::Bucket.objects(bucket, :prefix => base, :max_keys => keep * 2)
        puts files.collect {|x| x.key} if config[:verbose]

        files = files.
          collect {|x| x.key}.
          sort

        cleanup_with_limit(files, keep) do |f|
          puts "removing s3 file #{bucket}:#{f}" if config[:dry_run] || config[:verbose]
          AWS::S3::Bucket.objects(bucket, :prefix => f)[0].delete unless config[:dry_run] || config[:local_only]
        end
      end

      def bucket
        config[:s3, :bucket]
      end

      def key
        config[:s3, :key]
      end

      def secret
        config[:s3, :secret]
      end

      private
      
      def bucket_exists?(bucket)
        true if AWS::S3::Bucket.find(bucket)
      rescue AWS::S3::NoSuchBucket
        false
      end
    end
  end
end
