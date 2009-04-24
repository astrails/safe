require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::S3 do

  describe :active do
    it "should be true when all params are set"
    it "should be false if bucket is missing"
    it "should be false if key is missing"
    it "should be false if secret is missing"
  end

  describe :prefix do
    it "should use s3/path 1st"
    it "should use local/path 2nd"
    it "should use constant 3rd"
  end

  describe :save do
    it "should establish s3 connection"
    it "should RuntimeError if no local file (i.e. :local didn't run)"
    it "should open local file"
    it "should upload file"
  end

  describe :cleanup do
    it "should have some tests"
  end
end
