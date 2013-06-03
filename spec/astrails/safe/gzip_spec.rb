require 'spec_helper'

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

      before(:each) { @gzip = gzip({}, :extension => ".foo", :command => "foobar", :compressed => true) }

      it "should not touch extension" do
        @gzip.process
        @backup.extension.should == ".foo"
      end

      it "should not touch command" do
        @gzip.process
        @backup.command.should == "foobar"
      end

      it "should not touch compressed" do
        @gzip.process
        @backup.compressed.should == true
      end
    end
  end
end
