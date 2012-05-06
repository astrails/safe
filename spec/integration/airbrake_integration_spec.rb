require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'toadhopper'

describe "a failing backup" do
  before :each do
    @exception = RuntimeError.new("BOOM")
    stub.instance_of(Astrails::Safe::Source).backup { raise @exception }

    # need both local and instance vars
    # instance variables are used in tests
    # local variables are used in the backup definition (instance vars can't be seen)
    @root = root = "tmp/airbrake_backup_example"

    # clean state
    rm_rf @root
    mkdir_p @root

    # create source tree
    @src = src = "#{@root}/src"
    @dst = dst = "#{@root}/backup"
    mkdir_p @dst

    @now = Time.now
    @timestamp = @now.strftime("%y%m%d-%H%M")

    stub(Time).now {@now} # Freeze
  end

  describe "when not configured to send airbrake notifications" do
    it "should not notify the toadhopper" do
      dont_allow(Toadhopper).post!

      Astrails::Safe.safe do
        local :path => "#{@dst}/:kind"
        tar do
          archive :test1, :files => @src
        end
      end
    end    
  end
  
  describe "when configured to send airbrake notifications" do
    def perform_backup
      Astrails::Safe.safe do
        airbrake do
          api_key "test_api_key"
        end

        local :path => "#{@dst}/:kind"
        tar do
          archive :test1, :files => @src
        end
      end      
    end
    
    it "should assign the specified api key" do
      mock(Toadhopper).new('test_api_key')      
      perform_backup
    end

    it "should notifiy the toadhopper" do
      mock.instance_of(Toadhopper).post!(@exception)
      perform_backup
    end

    it "should clean up the tmp files" do
      mock(Astrails::Safe::TmpFile).cleanup
      perform_backup
    end

    it "should not raise exceptions from the toadhopper" do
      mock.instance_of(Toadhopper).post!(@exception) { raise RuntimeError.new("From the toad") }
      lambda { perform_backup }.should_not raise_exception("From the toad")
    end
  end
end