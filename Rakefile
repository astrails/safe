require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "astrails-safe"
    gem.summary = %Q{Backup filesystem and databases (MySQL and PostgreSQL) locally or to a remote server/service (with encryption)}
    gem.description = <<-DESC
Astrails-Safe is a simple tool to backup databases (MySQL and PostgreSQL), Subversion repositories (with svndump) and just files.
Backups can be stored locally or remotely and can be enctypted.
Remote storage is supported on Amazon S3, Rackspace Cloud Files, or just plain SFTP.
DESC
    gem.email = "we@astrails.com"
    gem.homepage = "http://blog.astrails.com/astrails-safe"
    gem.authors  = ["Astrails Ltd."]
    gem.files = FileList["[A-Z]*.*", "{bin,examples,generators,lib,rails,spec,test,templates}/**/*", 'Rakefile', 'LICENSE*']

    gem.add_dependency("aws-s3")
    gem.add_dependency("cloudfiles")
    gem.add_dependency("net-sftp")

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'micronaut/rake_task'
Micronaut::RakeTask.new(:examples) do |examples|
  examples.pattern = 'examples/**/*_example.rb'
  examples.ruby_opts << '-Ilib -Iexamples'
end

Micronaut::RakeTask.new(:rcov) do |examples|
  examples.pattern = 'examples/**/*_example.rb'
  examples.rcov_opts = '-Ilib -Iexamples -iastrails -x\/gems\/'
  examples.rcov = true
end


task :default => :examples

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "safe #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

