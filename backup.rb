#!/usr/bin/env ruby

require 'tmpdir'
require 'tempfile'
require 'rubygems'
require 'ruby-debug'
require 'fileutils'
require "aws/s3"
require 'yaml'

def die(msg)
  puts "ERROR: #{msg}"
  exit 1
end

def usage
  puts <<-END
Usage: backup.rb [OPTIONS] CONFIG_FILE
Options:
  -h, --help           This help screen
  -v, --verbose        be verbose, duh!
  -n, --dry-run        just pretend, don't do anything.
  -L, --local          skip S3

Note: config file will be created from template if missing
END
  exit 1
end

def now
  @now ||= Time.now
end

def timestamp
  @timestamp ||= now.strftime("%y%m%d-%H%M")
end

# We allow to put configuration keys on any level
class ConfigHash
  def initialize(root, *path)
    path = [*path] unless path.empty?
    # sequence of all the config levels on path given
    # if at some point there is no value, @config will contain nil for this element and all the following
    @configs = path.inject([root]) { |res, x| res << (res.last && res.last[x]) }.reverse
    # if the first element (last before revers) is nil -> the required path does not exist
    @configs = [{}] if @configs.first.nil?
  end

  def [](key)
    conf = @configs.find {|x| x.is_a?(Hash) && x[key]}
    conf && conf[key]
  end

  def keys
    @configs.first.keys
  end

end

def create_config_file(path)
  File.open(path, "w") do |conf|
    conf.write <<-CONF
# you can use comments

# Note: keys defined on a deeper level will override upper level keys
# See :path for example

# global path
:path: /backup

## uncomment to enable uploads to Amazon S3
## Amazon S3 auth (optional)
# :s3_key: YOUR_S3_KEY
# :s3_secret: YOUR_S3_SECRET
# :s3_bucket: S3_BUCKET

## uncomment to enable backup rotation. keep only given number of latest
## backups. remove the rest
#:keep_local: 50
#:keep_s3: 200

:mysql:
  # local path override for mysql
  :path: /backup/mysql
  :socket: /var/run/mysqld/mysqld.sock
  :mysqldump_options: -ceKq --single-transaction --create-options
  :username: MYSQL_USER
  :password: MYSQL_PASS

  :databases:

    :production_db:
      :skip_tables:
      - logged_exceptions
      - request_logs
      :gpg_password: OPTIONAL_PASSWORD_TO_ENCRYPT

:tar:
  :path: /backup/archives
  :archives:
    :git_repositories:
      :files:
      - /home/git/repositories
      - /home/mirrors/foo/repositories
      :exclude:
      - /home/mirrors/foo/repositories/junk
    :etc:
      :files:
      - /etc

    CONF
  end
end

def process_options
  usage if ARGV.delete("-h") || ARGV.delete("--help")
  $VERBOSE = ARGV.delete("-v") || ARGV.delete("--verbose")
  $DRY_RUN = ARGV.delete("-n") || ARGV.delete("--dry-run")
  $LOCAL   = ARGV.delete("-L") || ARGV.delete("--local")
  usage unless ARGV.first
  $CONFIG_FILE_NAME = File.expand_path(ARGV.first)
end

$KEEP_FILES = []

def create_temp_file(name)
  file = Tempfile.new("mysqldump", $TMPDIR)

  yield file

  file.close
  $KEEP_FILES << file # so that it will not get gcollected and removed from filesystem until the end
  file.path
end

def create_mysql_password_file(conf)
  create_temp_file("mysqldump") do |file|
    username = conf[:username]
    password = conf[:password]
    socket   = conf[:socket]
    host     = conf[:host]
    port     = conf[:port]

    file.puts "[mysqldump]"
    file.puts "user = #{username}" if username
    file.puts "password = #{password}" if password
    file.puts "socket = #{socket}" if socket
    file.puts "host = #{host}" if host
    file.puts "port = #{port}" if port
  end
end

def create_gpg_password_file(pass)
  create_temp_file("gpg-pass") { |file| file.write(pass) }
end


def mysql_skip_tables(conf, db)
  if skip_tables = conf[:skip_tables]
    skip_tables.map{|t| "--ignore-table=#{db}.#{t} "}.join
  end
end

def mysqldump(conf, db)
  cmd = "mysqldump  --defaults-extra-file=#{create_mysql_password_file(conf)} "
  cmd << conf[:mysqldump_options] << " " if conf[:mysqldump_options]
  cmd << mysql_skip_tables(conf, db)
  cmd << " #{db} "

  path = conf[:path]
  die "missing :path in configuration" unless path
  backup_filename = File.join(path, "mysql-#{db}.#{timestamp}.sql")

  [cmd, backup_filename]
end

def tar_extra_options(conf, cmd)
  cmd << conf[:tar_options] << " " if conf[:tar_options]
  cmd
end
def tar_exclude_files(conf, cmd)
  if exclude = conf[:exclude]
    cmd << exclude.map{|x| "--exclude=#{x} "}.join
  end
  cmd
end

def tar_files(conf, cmd)
  die "missing files for tar" unless conf[:files]
  cmd << conf[:files] * " "
end

def tar_archive(conf, arch)
  cmd = "tar -cf - "
  cmd = tar_extra_options(conf, cmd)
  cmd = tar_exclude_files(conf, cmd)
  cmd = tar_files(conf, cmd)

  path = conf[:path]
  die "missing :path in configuration" unless path
  backup_filename = File.join(path, "archive-#{arch}.#{timestamp}.tar")

  [cmd, backup_filename]
end

# GPG uses compression too :)
def compress(conf, cmd, backup_filename)

  gpg_pass = conf[:gpg_password]
  gpg_key = conf[:gpg_public_key]

  if gpg_key
    die "can't sue both password and pubkey" if gpg_pass
    cmd << "|gpg -e -r #{gpg_key}"
    backup_filename << ".gpg"
  elsif gpg_pass
    unless $DRY_RUN
      cmd << "|gpg -c --passphrase-file #{create_gpg_password_file(gpg_pass)}"
    else
      cmd << "|gpg -c --passphrase-file TEMP_GENERATED_FILENAME"
    end
    backup_filename << ".gpg"
  else
    cmd << "|gzip"
    backup_filename << ".gz"
  end
  [cmd, backup_filename]
end

def timestamped_path(prefix, filename, date)
  File.join(prefix, "%04d" % date.year, "%02d" % date.month, "%02d" % date.day, File.basename(filename))
end

def cleanup_files(files, limit, &block)
  return unless files.size > limit

  to_remove = files[0..(files.size - limit - 1)]
  to_remove.each(&block)
end

def cleanup_local(conf, backup_filename)
  return unless keep_local = conf[:keep_local]

  dir = File.dirname(backup_filename)
  base = File.basename(backup_filename).split(".").first

  files = Dir[File.join(dir, "#{base}*")].
    select{|f| File.file?(f)}.
    sort

  cleanup_files(files, keep_local) do |f|
    puts "removing local file #{f}" if $DRY_RUN || $VERBOSE
    File.unlink(f) unless $DRY_RUN
  end
end

class String
  def starts_with?(str)
    self[0..(str.length - 1)] == str
  end
end

def cleanup_s3(conf, bucket, prefix, backup_filename)

  return unless keep_s3 = conf[:keep_s3]

  base = File.basename(backup_filename).split(".").first

  puts "listing files in #{bucket}:#{prefix}"
  files = AWS::S3::Bucket.objects(bucket, :prefix => prefix, :max_keys => keep_s3 * 2)
  puts files.collect(&:key)
  files = files.
    collect(&:key).
    select{|o| File.basename(o).starts_with?(base)}.
    sort

  cleanup_files(files, keep_s3) do |f|
    puts "removing s3 file #{bucket}:#{f}" if $DRY_RUN || $VERBOSE
    AWS::S3::Bucket.find(bucket)[f].delete unless $DRY_RUN
  end
end


def s3_upload(conf, backup_filename, default_path)
  s3_bucket = conf[:s3_bucket]
  s3_key = conf[:s3_key]
  s3_secret = conf[:s3_secret]
  s3_prefix = conf[:s3_path] || default_path
  s3_path = timestamped_path(s3_prefix, backup_filename, now)

  return unless s3_bucket && s3_key && s3_secret

  puts "Uploading file #{backup_filename} to #{s3_bucket}/#{s3_path}" if $VERBOSE || $DRY_RUN

  AWS::S3::Base.establish_connection!(:access_key_id => s3_key, :secret_access_key => s3_secret, :use_ssl => true)

  unless $DRY_RUN || $LOCAL
    AWS::S3::Bucket.create(s3_bucket)
    AWS::S3::S3Object.store(s3_path, open(backup_filename), s3_bucket)
  end
  puts "...done" if $VERBOSE

  cleanup_s3(conf, s3_bucket, s3_prefix, backup_filename)
end

def stream_backup(conf, cmd, backup_name, default_path)
  # prepare COMPRESS
  cmd, backup_filename = compress(conf, cmd, backup_name)

  dir = File.dirname(backup_filename)
  FileUtils.mkdir_p(dir) unless File.directory?(dir) || $DRY_RUN

  # EXECUTE
  puts "Backup command: #{cmd} > #{backup_filename}" if $DRY_RUN || $VERBOSE
  system "#{cmd} > #{backup_filename}" unless $DRY_RUN

  # UPLOAD
  s3_upload(conf, backup_filename, default_path)

  # CLEANUP
  cleanup_local(conf, backup_filename)
end

def backup_mysql
  ConfigHash.new($CONFIG, :mysql, :databases).keys.each do |db|
    puts "Backup database #{db}" if $VERBOSE
    conf = ConfigHash.new($CONFIG, :mysql, :databases, db)
    cmd, backup_filename = mysqldump(conf, db)
    stream_backup(conf, cmd, backup_filename, "mysql/#{db}/")
  end
end

def backup_archives
  ConfigHash.new($CONFIG, :tar, :archives).keys.each do |arch|
    puts "Backup archive #{arch}" if $VERBOSE
    conf = ConfigHash.new($CONFIG, :tar, :archives, arch)

    cmd, backup_filename = tar_archive(conf, arch)
    stream_backup(conf, cmd, backup_filename, "archives/#{arch}/")
  end
end

def main
  process_options

  unless File.exists?($CONFIG_FILE_NAME)
    die "Missing configuration file. NOT CREATED! Rerun w/o the -n argument to create a template configuration file." if $DRY_RUN
    create_config_file($CONFIG_FILE_NAME)
    die "Created default #{$CONFIG_FILE_NAME}. Please edit and run again."
  end

  $CONFIG = YAML.load(File.read($CONFIG_FILE_NAME))

  # create temp directory
  $TMPDIR = Dir.mktmpdir

  backup_mysql

  backup_archives
end

main
