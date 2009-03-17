module Astrails
  module Safe
    class S3 < Storage
      def run
        bucket = @config[:s3, :bucket]
        key    = @config[:s3, :key]
        secret = @config[:s3, :secret]

        raise(RuntimeError, "missing S3 params") unless bucket && key && secret

        upload_path = File.join(s3_prefix, File.basename(filename))

        puts "Uploading file #{filename} to #{bucket}/#{upload_path}" if $_VERBOSE || $DRY_RUN

        # needed in cleanup even on dry run
        AWS::S3::Base.establish_connection!(:access_key_id => key, :secret_access_key => secret, :use_ssl => true)

        @stream.open do |file|
          unless $DRY_RUN
            AWS::S3::Bucket.create(bucket)
            AWS::S3::S3Object.store(upload_path, file, bucket)
          end
        end

        puts "...done" if $_VERBOSE
        cleanup
      end

      def cleanup

        return unless keep = @config[:keep, :s3]

        bucket = @config[:s3, :bucket]

        base = File.basename(filename).split(".").first

        puts "listing files in #{bucket}:#{s3_prefix}/#{base}"
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
