require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Gzip do

  def def_backup
    {
      :compressed => false,
      :command => "command",
      :extension => ".foo",
      :filename => "qweqwe"
    }
  end

  after(:each) { Astrails::Safe::TmpFile.cleanup }

  def gzip(config = {}, backup = def_backup)
    Astrails::Safe::Gzip.new(
      @config = Astrails::Safe::Config::Node.new(nil, config),
      @backup = Astrails::Safe::Backup.new(backup)
    )
  end

  describe :preocess do

    describe "when not yet compressed" do
      before(:each) { @gzip = gzip }

      it "should add .gz extension" do
        mock(@backup.extension) << '.gz'
        @gzip.process
      end

      it "should add |gzip pipe" do
        mock(@backup.command) << '|gzip'
        @gzip.process
      end

      it "should set compressed" do
        mock(@backup).compressed = true
        @gzip.process
      end
    end

    describe "when already compressed" do

      before(:each) { @gzip = gzip({}, :compressed => true) }

      it "should not touch extension" do
        dont_allow(@backup.extension).<< anything
        @gzip.process
      end

      it "should not touch command" do
        dont_allow(@backup.command).<< anything
        @gzip.process
      end

      it "should not touch compressed" do
        dont_allow(@backup).compressed = anything
        @gzip.process
      end
    end
  end
end