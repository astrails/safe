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

  def def_backup
    {
      :kind      => "_kind",
      :filename  => "/backup/somewhere/_kind-_id.NOW.bar",
      :extension => ".bar",
      :id        => "_id",
      :timestamp => "NOW"
    }
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

      stub(AWS::S3::Bucket).objects("_bucket", :prefix => "_kind/_id/_kind-_id", :max_keys => 4) {@files}
      stub(AWS::S3::Bucket).find("_bucket").stub![anything].stub!.delete
    end

    it "should check [:keep, :s3]" do
      @s3.config[:keep][:s3] = nil
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
      @s3.config[:s3][:bucket] = nil
      @s3.should_not be_active
    end

    it "should be false if key is missing" do
      @s3.config[:s3][:key] = nil
      @s3.should_not be_active
    end

    it "should be false if secret is missing" do
      @s3.config[:s3][:secret] = nil
      @s3.should_not be_active
    end
  end

  describe :prefix do
    before(:each) do
      @s3 = s3
    end
    it "should use s3/path 1st" do
      @s3.config[:s3][:path] = "s3_path"
      @s3.config[:local] = {:path => "local_path"}
      @s3.send(:prefix).should == "s3_path"
    end

    it "should use local/path 2nd" do
      @s3.config[:local] = {:path => "local_path"}
      @s3.send(:prefix).should == "local_path"
    end

    it "should use constant 3rd" do
      @s3.send(:prefix).should == "_kind/_id"
    end

  end

  describe :save do
    it "should establish s3 connection"
    it "should RuntimeError if no local file (i.e. :local didn't run)"
    it "should open local file"
    it "should upload file"
  end
end
