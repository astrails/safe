require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Pgdump do

  def def_config
    {
      :options => "OPTS",
      :user => "User",
      :password => "pwd",
      :host => "localhost",
      :port => 7777,
      :skip_tables => [:bar, :baz]
    }
  end

  def pgdump(id = :foo, config = def_config)
    Astrails::Safe::Pgdump.new(id, Astrails::Safe::Config::Node.new(nil, config))
  end

  before(:each) do
    stub(Time).now.stub!.strftime {"NOW"}
  end

  after(:each) { Astrails::Safe::TmpFile.cleanup }

  describe :backup do
    before(:each) do
      @pg = pgdump
    end

    {
      :id => "foo",
      :kind => "pgdump",
      :extension => ".sql",
      :filename => "pgdump-foo.NOW",
      :command => "pg_dump OPTS --username='User' --host='localhost' --port='7777' foo",
    }.each do |k, v|
      it "should set #{k} to #{v}" do
        @pg.backup.send(k).should == v
      end
    end

  end

end