require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Cloudfiles do

  def def_config
    {
      :cloudfiles => {
        :container => "_container",
        :user    => "_user",
        :api_key => "_api_key",
      },
      :keep => {
        :cloudfiles => 2
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

  def cloudfiles(config = def_config, backup = def_backup)
    Astrails::Safe::Cloudfiles.new(
      Astrails::Safe::Config::Node.new(nil, config),
      Astrails::Safe::Backup.new(backup)
    )
  end

  describe :cleanup do

    before(:each) do
      @cloudfiles = cloudfiles

      @files = [4,1,3,2].to_a.map { |i| "aaaaa#{i}" }

      @container = "container"

      stub(@container).objects(:prefix => "_kind/_id/_kind-_id.") { @files }
      stub(@container).delete_object(anything)

      stub(CloudFiles::Connection).
        new('_user', '_api_key', true, false).stub!.
        container('_container') {@container}
    end

    it "should check [:keep, :cloudfiles]" do
      @cloudfiles.config[:keep].data["cloudfiles"] = nil
      dont_allow(@cloudfiles.backup).filename
      @cloudfiles.send :cleanup
    end

    it "should delete extra files" do
      mock(@container).delete_object('aaaaa1')
      mock(@container).delete_object('aaaaa2')
      @cloudfiles.send :cleanup
    end

  end

  describe :active do
    before(:each) do
      @cloudfiles = cloudfiles
    end

    it "should be true when all params are set" do
      @cloudfiles.should be_active
    end

    it "should be false if container is missing" do
      @cloudfiles.config[:cloudfiles].data["container"] = nil
      @cloudfiles.should_not be_active
    end

    it "should be false if user is missing" do
      @cloudfiles.config[:cloudfiles].data["user"] = nil
      @cloudfiles.should_not be_active
    end

    it "should be false if api_key is missing" do
      @cloudfiles.config[:cloudfiles].data["api_key"] = nil
      @cloudfiles.should_not be_active
    end
  end

  describe :path do
    before(:each) do
      @cloudfiles = cloudfiles
    end
    it "should use cloudfiles/path 1st" do
      @cloudfiles.config[:cloudfiles].data["path"] = "cloudfiles_path"
      @cloudfiles.config[:local] = {:path => "local_path"}
      @cloudfiles.send(:path).should == "cloudfiles_path"
    end

    it "should use local/path 2nd" do
      @cloudfiles.config[:local] = {:path => "local_path"}
      @cloudfiles.send(:path).should == "local_path"
    end

    it "should use constant 3rd" do
      @cloudfiles.send(:path).should == "_kind/_id"
    end

  end

  describe :save do
    def add_stubs(*stubs)
      stubs.each do |s|
        case s
        when :connection
          stub(CloudFiles::Authentication).new
          stub(CloudFiles::Connection).
            new('_user', '_api_key', true, false).stub!.
            create_container('_container') {@container}
        when :stat
          stub(File).stat("foo").stub!.size {123}
        when :create_container
          @container = "container"
          stub(@container).create_object("_kind/_id/backup/somewhere/_kind-_id.NOW.bar.bar", true) {@object}
          stub(CloudFiles::Connection).create_container {@container}
        when :file_open
          stub(File).open("foo")
        when :cloudfiles_store
          @object = "object"
          mock(@object).write(nil) {true}
        end
      end
    end

    before(:each) do
      @cloudfiles = cloudfiles(def_config, def_backup(:path => "foo"))
      @full_path = "_kind/_id/backup/somewhere/_kind-_id.NOW.bar.bar"
    end

    it "should fail if no backup.file is set" do
      @cloudfiles.backup.path = nil
      proc {@cloudfiles.send(:save)}.should raise_error(RuntimeError)
    end

    it "should establish Cloud Files connection" do
      add_stubs(:connection, :stat, :create_container, :file_open, :cloudfiles_store)
      @cloudfiles.send(:save)
    end

    it "should open local file" do
      add_stubs(:connection, :stat, :create_container, :cloudfiles_store)
      mock(File).open("foo")
      @cloudfiles.send(:save)
    end

    it "should upload file" do
      add_stubs(:connection, :stat, :create_container, :file_open, :cloudfiles_store)
      @cloudfiles.send(:save)
    end

    it "should fail on files bigger then 5G" do
      add_stubs(:connection)
      mock(File).stat("foo").stub!.size {5*1024*1024*1024+1}
      mock(STDERR).puts(anything)
      dont_allow(Benchmark).realtime
      @cloudfiles.send(:save)
    end
  end
end
