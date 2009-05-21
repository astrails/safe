require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Gpg do
  def def_backup
    {
      :compressed => false,
      :command => "command",
      :extension => ".foo",
      :filename => "qweqwe"
    }
  end

  def gpg(config = {}, backup = def_backup)
    Astrails::Safe::Gpg.new(
      @config = Astrails::Safe::Config::Node.new(nil, config),
      @backup = Astrails::Safe::Backup.new(backup)
    )
  end

  after(:each) { Astrails::Safe::TmpFile.cleanup }

  describe :process do

    before(:each) do
      @gpg = gpg()
      stub(@gpg).gpg_password_file {"pwd-file"}
      stub(@gpg).pipe {"|gpg -BLAH"}
    end

    describe "when active" do
      before(:each) do
        stub(@gpg).active? {true}
      end

      it "should add .gpg extension" do
        mock(@backup.extension) << '.gpg'
        @gpg.process
      end

      it "should add command pipe" do
        mock(@backup.command) << (/\|gpg -BLAH/)
        @gpg.process
      end

      it "should set compressed" do
        mock(@backup).compressed = true
        @gpg.process
      end
    end

    describe "when inactive" do
      before(:each) do
        stub(@gpg).active? {false}
      end

      it "should not touch extension" do
        dont_allow(@backup.extension) << anything
        @gpg.process
      end

      it "should not touch command" do
        dont_allow(@backup.command) << anything
        @gpg.process
      end

      it "should not touch compressed" do
        dont_allow(@backup).compressed = anything
        @gpg.process
      end
    end
  end

  describe :active? do

    describe "with key" do
      it "should be true" do
        gpg(:gpg => {:key => :foo}).should be_active
      end
    end

    describe "with password" do
      it "should be true" do
        gpg(:gpg => {:password => :foo}).should be_active
      end
    end

    describe "without key & password" do
      it "should be false" do
        gpg.should_not be_active
      end
    end

    describe "with key & password" do
      it "should raise RuntimeError" do
        lambda {
          gpg(:gpg => {:key => "foo", :password => "bar"}).send :active?
        }.should raise_error(RuntimeError, "can't use both gpg password and pubkey")
      end
    end
  end

  describe :pipe do

    describe "with key" do
      before(:each) do
        @gpg = gpg(:gpg => {:key => "foo", :options => "GPG-OPT"}, :options => "OPT")
      end

      it "should not call gpg_password_file" do
        dont_allow(@gpg).gpg_password_file(anything)
        @gpg.send(:pipe)
      end

      it "should use '-r' and :options" do
        @gpg.send(:pipe).should == "|gpg GPG-OPT -e -r foo"
      end
    end

    describe "with password" do
      before(:each) do
        @gpg = gpg(:gpg => {:password => "bar", :options => "GPG-OPT"}, :options => "OPT")
        stub(@gpg).gpg_password_file(anything) {"pass-file"}
      end

      it "should use '--passphrase-file' and :options" do
        @gpg.send(:pipe).should == "|gpg GPG-OPT -c --passphrase-file pass-file"
      end
    end
  end

  describe :gpg_password_file do
    it "should create password file" do
      file = gpg.send(:gpg_password_file, "foo")
      File.exists?(file).should be_true
      File.read(file).should == "foo"
    end
  end
end