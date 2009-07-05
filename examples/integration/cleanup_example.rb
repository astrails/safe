require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

require "fileutils"
include FileUtils

describe "tar backup" do
  before(:all) do
    # need both local and instance vars
    # instance variables are used in tests
    # local variables are used in the backup definition (instance vars can't be seen)
    @root = root = "tmp/cleanup_example"

    # clean state
    rm_rf @root
    mkdir_p @root

    # create source tree
    @src = src = "#{@root}/src"
    mkdir_p src

    File.open(qwe = "#{@src}/qwe", "w") {|f| f.write("qwe") }

    @dst = dst = "#{@root}/backup"
    mkdir_p "#{@dst}/archive"

    @now = Time.now
    @timestamp = @now.strftime("%y%m%d-%H%M")

    stub(Time).now {@now} # Freeze

    cp qwe, "#{dst}/archive/archive-foo.000001.tar.gz"
    cp qwe, "#{dst}/archive/archive-foo.000002.tar.gz"
    cp qwe, "#{dst}/archive/archive-foobar.000001.tar.gz"
    cp qwe, "#{dst}/archive/archive-foobar.000002.tar.gz"

    Astrails::Safe.safe do
      local :path => "#{dst}/:kind"
      tar do
        keep :local => 1 # only leave the latest
        archive :foo do
          files src
        end
      end
    end

    @backup = "#{dst}/archive/archive-foo.#{@timestamp}.tar.gz"
  end

  it "should create backup file" do
    puts "Expecting: #{@backup}"
    File.exists?(@backup).should be_true
  end

  it "should remove old backups" do
    Dir["#{@dst}/archive/archive-foo.*"].should == [@backup]
  end

  it "should NOT remove backups with base having same prefix" do
    Dir["#{@dst}/archive/archive-foobar.*"].should == ["#{@dst}/archive/archive-foobar.000001.tar.gz", "#{@dst}/archive/archive-foobar.000002.tar.gz"]
  end

end