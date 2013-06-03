require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Astrails::Safe::Mongodump do
  def def_config
    {
      :host => 'prod.example.com',
      :user => 'testuser',
      :password => 'p4ssw0rd',
    }
  end
  
  def mongodump(id = :foo, config = def_config)
    Astrails::Safe::Mongodump.new(id, Astrails::Safe::Config::Node.new(nil, config))
  end
  
  before(:each) do
    stub(Time).now.stub!.strftime {"NOW"}
    @output_folder = File.join(Astrails::Safe::TmpFile.tmproot, 'mongodump')
  end
  
  after(:each) { Astrails::Safe::TmpFile.cleanup }
  
  describe :backup do
    before(:each) do
      @mongo = mongodump
    end
    
    {
      :id => "foo",
      :kind => "mongodump",
      :extension => ".tar",
      :filename => "mongodump-foo.NOW"
    }.each do |k, v|
      it "should set #{k} to #{v}" do
        @mongo.backup.send(k).should == v
      end
    end
    
    it "should set the command" do
      @mongo.backup.send(:command).should == "mongodump -q \"{xxxx : { \\$ne : 0 } }\" --db foo --host prod.example.com -u testuser -p p4ssw0rd --out #{@output_folder} && cd #{@output_folder} && tar cf - ."
    end
    
    {
      :host => "--host ",
      :user => "-u ",
      :password => "-p "
    }.each do |key, v|    
      it "should not add #{key} to command if it is not present" do
        @mongo = mongodump(:foo, def_config.reject! {|k,v| k == key})
        @mongo.backup.send(:command).should_not =~ /#{v}/
      end
    end
  end
end
