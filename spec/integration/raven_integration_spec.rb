require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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

  describe "when not configured to send raven notifications" do
    it "should not notify the raven" do
      dont_allow(Raven).capture_exception

      Astrails::Safe.safe do
        local :path => "#{@dst}/:kind"
        tar do
          archive :test1, :files => @src
        end
      end
    end
  end

  describe "when configured to send raven notifications" do
    def perform_backup
      Astrails::Safe.safe do
        raven do
          dsn "test_api_key"
        end

        local :path => "#{@dst}/:kind"
        tar do
          archive :test1, :files => @src
        end
      end
    end

    it "should notifiy raven" do
      mock(Raven).capture_exception(@exception)
      perform_backup
    end

    it "should clean up the tmp files" do
      mock(Astrails::Safe::TmpFile).cleanup
      perform_backup
    end

    it "should not raise exceptions from raven" do
      mock(Raven).capture_exception(@exception) { raise RuntimeError.new("From raven") }
      lambda { perform_backup }.should_not raise_exception("From raven")
    end
  end
end
