Gem::Specification.new do |s|
  s.name     = "safe"
  s.version  = "0.0.1"
  s.date     = "2009-03-03"
  s.summary  = "simple file and mysql backup"
  s.email    = "we@astrails.com"
  s.homepage = "http://github.com/astrails/safe"
  s.description = "Simple plugin to backup MySQL databases and filesystem locally or to Amazon S3 (with optional encryption)"
  s.has_rdoc = false
  s.authors  = ["Astrails Ltd."]
  s.files    = files = %w(
    bin/astrails-safe
    safe.gemspec
  )
  s.executables = files.grep(/^bin/).map {|x| x.gsub(/^bin\//, "")}

  s.test_files = []
  s.add_dependency("aws-s3")
  s.add_dependency("yaml")
end

