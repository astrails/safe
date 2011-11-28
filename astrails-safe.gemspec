require './lib/astrails/safe/version'

Gem::Specification.new do |s|
  s.name        = %q{astrails-safe}
  s.version     = Astrails::Safe::VERSION
  s.authors     = ["Astrails Ltd."]
  s.date        = Time.now.utc.strftime("%Y-%m-%d")
  s.email       = %q{we@astrails.com}
  s.homepage    = %q{http://blog.astrails.com/astrails-safe}
  s.summary     = %q{Backup filesystem and databases (MySQL and PostgreSQL) locally or to a remote server/service (with encryption)}
  s.description = %q{Astrails-Safe is a simple tool to backup databases (MySQL and PostgreSQL), Subversion repositories (with svndump) and just files.
Backups can be stored locally or remotely and can be enctypted.
Remote storage is supported on Amazon S3, Rackspace Cloud Files, or just plain SFTP.
}

  s.extra_rdoc_files = [
    "LICENSE",
    "README.markdown",
    "TODO"
  ]
  
  s.files                     = `git ls-files`.split("\n")
  s.test_files                = `git ls-files spec`.split("\n")
  s.require_paths             = ["lib"]
  s.required_rubygems_version = %q{1.5.0}
  s.default_executable        = %q{astrails-safe}  
  s.executables               = ["astrails-safe"]

  # tests
  s.add_development_dependency 'rspec', '~> 1.3.2'
  s.add_development_dependency 'rr', '~> 1.0.4'
  
  s.add_runtime_dependency 'aws-s3', '~> 0.6.2'
  s.add_runtime_dependency 'cloudfiles', '~> 1.4.7'
  s.add_runtime_dependency 'net-sftp', '~> 2.0.4'
  
end

