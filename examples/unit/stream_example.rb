require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Stream do

  before(:each) do
    @parent = Object.new
    @stream = Astrails::Safe::Stream.new(@parent)
    @r = rand(10)
  end

  def self.it_delegates_to_parent(prop)
    it "delegates #{prop} to parent if not set" do
      mock(@parent).__send__(prop) {@r}
      @stream.send(prop).should == @r
    end
  end

  def self.it_delegates_to_parent_with_cache(prop)
    it_delegates_to_parent(prop)

    it "uses cached value for #{prop}" do
      dont_allow(@parent).__send__(prop)
      @stream.instance_variable_set "@#{prop}", @r + 1
      @stream.send(prop).should == @r + 1
    end
  end

  it_delegates_to_parent_with_cache :id
  it_delegates_to_parent_with_cache :config

  it_delegates_to_parent :filename

end
