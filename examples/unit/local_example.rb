require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Local do
  def def_config
    {
      :local => {
        :path => "/:kind~:id~:timestamp"
      },
      :keep => {
        :local => 2
      }
    }
  end

  def def_backup
    {
      :kind => "mysqldump",
      :id => "blog",
      :timestamp => "NoW",
      :compressed => true,
      :command => "command",
      :extension => ".foo.gz",
      :filename => "qweqwe"
    }
  end

  def local(config = def_config, backup = def_backup)
    Astrails::Safe::Local.new(
      @config = Astrails::Safe::Config::Node.new(nil, config),
      @backup = Astrails::Safe::Backup.new(backup)
    )
  end

  describe :active? do
    it "should be true" do
      local.should be_active
    end
  end

  describe :path do
    it "should raise RuntimeError when no path" do
      lambda {
        local({}).send :path
      }.should raise_error(RuntimeError, "missing :local/:path")
    end

    it "should use local/path" do
      local.send(:path).should == "/mysqldump~blog~NoW"
    end
  end

  describe :save do
    before(:each) do
      @local = local
      stub(@local).system
      stub(@local).full_path {"file-path"}
      stub(FileUtils).mkdir_p
    end

    it "should call system to save the file" do
      mock(@local).system("command>file-path")
      @local.send(:save)
    end

    it "should create directory" do
      mock(FileUtils).mkdir_p("/mysqldump~blog~NoW")
      @local.send(:save)
    end

    it "should set backup.path" do
      mock(@backup).path = "file-path"
      @local.send(:save)
    end

    describe "dry run" do
      before(:all) {$DRY_RUN = true}
      after(:all)  {$DRY_RUN = false}

      it "should not create directory"
      it "should not call system"
      it "should set backup.path" do
        mock(@backup).path = "file-path"
        @local.send(:save)
      end
    end
  end

  describe :cleanup do
    before(:each) do
      @files = [4,1,3,2].to_a.map { |i| "/mysqldump~blog~NoW/qweqwe.#{i}" }
      stub(File).file?(anything) {true}
      stub(File).size(anything) {1}
      stub(File).unlink
    end

    it "should check [:keep, :local]" do
      @local = local(def_config.merge(:keep => {}))
      dont_allow(Dir).[]
      @local.send :cleanup
    end

    it "should delete extra files" do
      @local = local
      mock(Dir).[]("/mysqldump~blog~NoW/qweqwe.*") {@files}
      mock(File).unlink("/mysqldump~blog~NoW/qweqwe.1")
      mock(File).unlink("/mysqldump~blog~NoW/qweqwe.2")
      @local.send :cleanup
    end
  end
end
