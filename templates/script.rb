safe do

  # backup file path (not including filename)
  # supported substitutions:
  #   :kind -> backup 'engine' kind, e.g. "mysqldump" or "archive"
  #   :id -> backup 'id', e.g. "blog", "production", etc.
  #   :timestamp -> current run timestamp (same for all the backups in the same 'run')
  # you can set separate :path for all backups (or once globally here)
  local do
    path "/backup/:kind"
  end

  ## uncomment to enable uploads to Amazon S3
  ## Amazon S3 auth (optional)
  # s3 do
  #   key YOUR_S3_KEY
  #   secret YOUR_S3_SECRET
  #   bucket S3_BUCKET
  #   # path for uploads to S3. supports same substitution like :local/:path
  #   path ":kind/" # this is default
  # end

  ## alternative style:
  # s3 :key => YOUR_S3_KEY, :secret => YOUR_S3_SECRET, :bucket => S3_BUCKET, :path => ":kind/"

  ## uncomment to enable uploads to Rackspace Cloud Files
  ## http://www.rackspacecloud.com/cloud_hosting_products/files
  ## Rackspace auth (optional)
  # cloudfiles do
  #   user "YOUR_RACKSPACE_CLOUD_USERNAME"
  #   api_key "YOUR_RACKSPACE_API_KEY"
  #   container "YOUR_CONTAINER_NAME"
  #   # path for uploads to Cloud Files, supports same substitution like :local/:path
  #   path ":kind/" # this is default
  #   # If you are running the backup from a system within the Rackspace/Slicehost network and would like
  #   # to back up over the private (unbilled) service net, set this value to true.
  #   # service_net true
  # end

  ## uncomment to enable uploads via SFTP
  # sftp do
  #   host "YOUR_REMOTE_HOSTNAME"
  #   user "YOUR_REMOTE_USERNAME"
  #   # port "NON STANDARD SSH PORT"
  #   password "YOUR_REMOTE_PASSWORD"
  #   path ":kind/:id" # this is the default
  # end

  ## uncomment to enable GPG encryption.
  ## Note: you can use public 'key' or symmetric password but not both!
  # gpg do
  #   # you can specify your own gpg executable with the 'command' options
  #   # this can be useful for example to choose b/w gpg and gpg2 if both are installed
  #   # some gpg installations will automatically set 'use-agent' option in the
  #   # config file on the 1st run. see README for more details
  #   options "--no-use-agent"
  #   # command "/usr/local/bin/gpg"
  #   # key "backup@astrails.com"
  #   password "astrails"
  # end

  ## uncomment to enable backup rotation. keep only given number of latest
  ## backups. remove the rest
  # keep do
  #   local 4 # keep 4 local backups
  #   s3 20 # keep 20 S3 backups
  # end

  # backup mysql databases with mysqldump
  mysqldump do
    # you can override any setting from parent in a child:
    options "-ceKq --single-transaction --create-options"

    user "astrails"
    password ""
    # host "localhost"
    # port 3306
    socket "/var/run/mysqld/mysqld.sock"

    # database is a 'collection' element. it must have a hash or block parameter
    # it will be 'collected' in a 'databases', with database id (1st arg) used as hash key
    # the following code will create mysqldump/databases/blog and mysqldump/databases/mysql ocnfiguration 'nodes'

    # backup database with default values
    # database :blog

    # backup overriding some values
    # database :production do
    #   # you can override 'partially'
    #   keep :local => 3
    #   # keep/local is 3, and keep/s3 is 20 (from parent)

    #   # local override for gpg password
    #   gpg do
    #     password "custom-production-pass"
    #   end
    #   # skip those tables during backup
    #   # you can pass an array
    #   skip_tables [:logger_exceptions, :request_logs]
    #   # or pass them all separately
    #   skip_tables :test1
    #   skip_tables :test2
    # end

  end

  # # uncomment to enable
  # # backup PostgreSQL databases with pg_dump
  # pgdump do
  #   options "-i -x -O"
  #
  #   user "markmansour"
  #   # password "" - leave this out if you have ident setup
  #
  #   # database is a 'collection' element. it must have a hash or block parameter
  #   # it will be 'collected' in a 'databases', with database id (1st arg) used as hash key
  #   database :blog
  #   database :production
  # end

  tar do
    # options "-h" # uncomment this to dereference symbolic links

    # 'archive' is a collection item, just like 'database'
    # archive "git-repositories" do
    #   # files and directories to backup
    #   files "/home/git/repositories"
    #   # can have more then one 'files' lines or/and use an array
    #   files ["/home/dev/work/foo", "/home/dev/work/bar"]
    # end

    # archive "etc-files" do
    #   files "/etc"
    #   # exlude those files/directories
    #   exclude "/etc/puppet/other"
    #   # can have multiple 'exclude' lines or/and use an array
    #   exclude ["/etc/tmp/a", "/etc/tmp/b"]
    # end

    # archive "dot-configs" do
    #   files "/home/*/.[^.]*"
    # end

    # archive "blog" do
    #   files "/var/www/blog.astrails.com/"
    #   # specify multiple files/directories as array
    #   exclude ["/var/www/blog.astrails.com/log", "/var/www/blog.astrails.com/tmp"]
    # end

    # archive "site" do
    #   files "/var/www/astrails.com/"
    #   exclude ["/var/www/astrails.com/log", "/var/www/astrails.com/tmp"]
    # end

    # archive :misc do
    #   files [ "/backup/*.rb" ]
    # end
  end

end
