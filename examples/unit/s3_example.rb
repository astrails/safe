require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::S3 do

  def def_config
    {
      :s3 => {
        :bucket => "_bucket",
        :key    => "_key",
        :secret => "_secret",
      },
      :keep => {
        :s3 => 2
      }
    }
  end

  def def_backup(extra = {})
    {
      :kind      => "_kind",
      :filename  => "/backup/somewhere/_kind-_id.NOW.bar",
      :extension => ".bar",
      :id        => "_id",
      :timestamp => "NOW"
    }.merge(extra)
  end

  def s3(config = def_config, backup = def_backup)
    Astrails::Safe::S3.new(
      Astrails::Safe::Config::Node.new(nil, config),
      Astrails::Safe::Backup.new(backup)
    )
  end

  describe :cleanup do

    before(:each) do
      @s3 = s3

      @files = [4,1,3,2].to_a.map { |i| stub(o = {}).key {"aaaaa#{i}"}; o }

      stub(AWS::S3::Bucket).objects("_bucket", :prefix => "_kind/_id/_kind-_id.", :max_keys => 4) {@files}
      stub(AWS::S3::Bucket).find("_bucket").stub![anything].stub!.delete
    end

    it "should check [:keep, :s3]" do
      @s3.config[:keep].data["s3"] = nil
      dont_allow(@s3.backup).filename
      @s3.send :cleanup
    end

    it "should delete extra files" do
      mock(AWS::S3::Bucket).find("_bucket").mock!["aaaaa1"].mock!.delete
      mock(AWS::S3::Bucket).find("_bucket").mock!["aaaaa2"].mock!.delete
      @s3.send :cleanup
    end

  end

  describe :active do
    before(:each) do
      @s3 = s3
    end

    it "should be true when all params are set" do
      @s3.should be_active
    end

    it "should be false if bucket is missing" do
      @s3.config[:s3].data["bucket"] = nil
      @s3.should_not be_active
    end

    it "should be false if key is missing" do
      @s3.config[:s3].data["key"] = nil
      @s3.should_not be_active
    end

    it "should be false if secret is missing" do
      @s3.config[:s3].data["secret"] = nil
      @s3.should_not be_active
    end
  end

  describe :path do
    before(:each) do
      @s3 = s3
    end
    it "should use s3/path 1st" do
      @s3.config[:s3].data["path"] = "s3_path"
      @s3.config[:local] = {:path => "local_path"}
      @s3.send(:path).should == "s3_path"
    end

    it "should use local/path 2nd" do
      @s3.config[:local] = {:path => "local_path"}
      @s3.send(:path).should == "local_path"
    end

    it "should use constant 3rd" do
      @s3.send(:path).should == "_kind/_id"
    end

  end

  describe :save do
    def add_stubs(*stubs)
      stubs.each do |s|
        case s
        when :connection
          stub(AWS::S3::Base).establish_connection!(:access_key_id => "_key", :secret_access_key => "_secret", :use_ssl => true)
        when :stat
          stub(File).stat("foo").stub!.size {123}
        when :create_bucket
          stub(AWS::S3::Bucket).create
        when :file_open
          stub(File).open("foo") {|f, block| block.call(:opened_file)}
        when :s3_store
          stub(AWS::S3::S3Object).store(@full_path, :opened_file, "_bucket")
        end
      end
    end

    before(:each) do
      @s3 = s3(def_config, def_backup(:path => "foo"))
      @full_path = "_kind/_id/backup/somewhere/_kind-_id.NOW.bar.bar"
    end

    it "should fail if no backup.file is set" do
      @s3.backup.path = nil
      proc {@s3.send(:save)}.should raise_error(RuntimeError)
    end

    it "should establish s3 connection" do
      mock(AWS::S3::Base).establish_connection!(:access_key_id => "_key", :secret_access_key => "_secret", :use_ssl => true)
      add_stubs(:stat, :create_bucket, :file_open, :s3_store)
      @s3.send(:save)
    end

    it "should open local file" do
      add_stubs(:connection, :stat, :create_bucket)
      mock(File).open("foo")
      @s3.send(:save)
    end

    it "should upload file" do
      add_stubs(:connection, :stat, :create_bucket, :file_open)
      mock(AWS::S3::S3Object).store(@full_path, :opened_file, "_bucket")
      @s3.send(:save)
    end

    it "should fail on files bigger then 5G" do
      add_stubs(:connection)
      mock(File).stat("foo").stub!.size {5*1024*1024*1024+1}
      mock(STDERR).puts(anything)
      dont_allow(Benchmark).realtime
      @s3.send(:save)
    end
  end
end
