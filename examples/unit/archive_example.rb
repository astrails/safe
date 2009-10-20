require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Archive do

  def def_config
    {
      :options => "OPTS",
      :files   => "apples",
      :exclude => "oranges"
    }
  end

  def archive(id = :foo, config = def_config)
    Astrails::Safe::Archive.new(id, Astrails::Safe::Config::Node.new(nil, config))
  end

  after(:each) { Astrails::Safe::TmpFile.cleanup }

  describe :backup do
    before(:each) do
      @archive = archive
      stub(@archive).timestamp {"NOW"}
    end

    {
      :id => "foo",
      :kind => "archive",
      :extension => ".tar",
      :filename => "archive-foo.NOW",
      :command => "tar -cf - OPTS --exclude=oranges apples",
    }.each do |k, v|
      it "should set #{k} to #{v}" do
        @archive.backup.send(k).should == v
      end
    end
  end

  describe :tar_exclude_files do
    it "should return '' when no excludes" do
      archive(:foo, {}).send(:tar_exclude_files).should == ''
    end

    it "should accept single exclude as string" do
      archive(:foo, {:exclude => "bar"}).send(:tar_exclude_files).should == '--exclude=bar'
    end

    it "should accept multiple exclude as array" do
      archive(:foo, {:exclude => ["foo", "bar"]}).send(:tar_exclude_files).should == '--exclude=foo --exclude=bar'
    end
  end

  describe :tar_files do
    it "should raise RuntimeError when no files" do
      lambda {
        archive(:foo, {}).send(:tar_files)
      }.should raise_error(RuntimeError, "missing files for tar")
    end

    it "should accept single file as string" do
      archive(:foo, {:files => "foo"}).send(:tar_files).should == "foo"
    end

    it "should accept multiple files as array" do
      archive(:foo, {:files => ["foo", "bar"]}).send(:tar_files).should == "foo bar"
    end
  end
end
