require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Mysqldump do

  def def_config(extra = {})
    {
      :options => "OPTS",
      :user => "User",
      :password => "pwd",
      :host => "localhost",
      :port => 7777,
      :socket => "socket",
      :skip_tables => [:bar, :baz]
    }.merge(extra)
  end

  def mysqldump(id = :foo, config = def_config)
    Astrails::Safe::Mysqldump.new(id, Astrails::Safe::Config::Node.new(nil, config))
  end

  before(:each) do
    stub(Time).now.stub!.strftime {"NOW"}
  end

  after(:each) { Astrails::Safe::TmpFile.cleanup }

  describe :backup do
    before(:each) do
      @mysql = mysqldump
      stub(@mysql).mysql_password_file {"/tmp/pwd"}
    end

    {
      :id => "foo",
      :kind => "mysqldump",
      :extension => ".sql",
      :filename => "mysqldump-foo.NOW",
      :command => "mysqldump --defaults-extra-file=/tmp/pwd OPTS --ignore-table=foo.bar --ignore-table=foo.baz foo",
    }.each do |k, v|
      it "should set #{k} to #{v}" do
        @mysql.backup.send(k).should == v
      end
    end

  end

  describe :mysql_skip_tables do
    it "should return nil if no skip_tables" do
      config = def_config.dup
      config.delete(:skip_tables)
      m = mysqldump(:foo, Astrails::Safe::Config::Node.new(nil, config))
      stub(m).timestamp {"NOW"}
      m.send(:mysql_skip_tables).should be_nil
      m.backup.command.should_not match(/ignore-table/)
    end

    it "should return '' if skip_tables empty" do
      config = def_config.dup
      config[:skip_tables] = []
      m = mysqldump(:foo, Astrails::Safe::Config::Node.new(nil, config))
      stub(m).timestamp {"NOW"}
      m.send(:mysql_skip_tables).should == ""
      m.backup.command.should_not match(/ignore-table/)
    end

  end

  describe :mysql_password_file do
    it "should create passwords file with quoted values" do
      m = mysqldump(:foo, def_config(:password => '#qwe"asd\'zxc'))
      file = m.send(:mysql_password_file)
      File.exists?(file).should == true
      File.read(file).should == <<-PWD
[mysqldump]
user = "User"
password = "#qwe\\"asd'zxc"
socket = "socket"
host = "localhost"
port = 7777
      PWD
    end
  end
end