# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'astrails/safe/version'

Gem::Specification.new do |spec|
  spec.name          = "astrails-safe"
  spec.version       = Astrails::Safe::VERSION
  spec.authors       = ["Vitaly Kushner"]
  spec.email         = ["we@astrails.com"]
  spec.description = <<-DESC
Astrails-Safe is a simple tool to backup databases (MySQL and PostgreSQL), Subversion repositories (with svndump) and just files.
Backups can be stored locally or remotely and can be enctypted.
Remote storage is supported on Amazon S3, Rackspace Cloud Files, or just plain SFTP.
DESC
  spec.summary       = %Q{Backup filesystem and databases (MySQL and PostgreSQL) locally or to a remote server/service (with encryption)}
  spec.homepage      = "http://astrails.com/astrails-safe"
  spec.license       = "MIT"

  spec.default_executable = %q{astrails-safe}

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-s3"
  spec.add_dependency "cloudfiles"
  spec.add_dependency "net-sftp"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
