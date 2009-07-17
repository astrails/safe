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
  ## don't forget to add :s3 to the 'store' list
  # s3 do
  #   key YOUR_S3_KEY
  #   secret YOUR_S3_SECRET
  #   bucket S3_BUCKET
  #   # path for uploads to S3. supports same substitution like :local/:path
  #   path ":kind/" # this is default
  # end

  ## alternative style:
  # s3 :key => YOUR_S3_KEY, :secret => YOUR_S3_SECRET, :bucket => S3_BUCKET, :path => ":kind/"

  ## uncomment to enable uploads via SFTP
  # sftp do
  #   host "YOUR_REMOTE_HOSTNAME"
  #   user "YOUR_REMOTE_USERNAME"
  #   password "YOUR_REMOTE_PASSWORD"
  #   path ":kind/:id" # this is the default
  # end

  ## uncomment to enable GPG encryption.
  ## Note: you can use public 'key' or symmetric password but not both!
  # gpg do
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

    #   skip_tables [:logger_exceptions, :request_logs] # skip those tables during backup
    # end

  end

  # # uncomment to enable
  # # backup PostgreSQL databases with pg_dump
  # pgdump do
  #   option "-i -x -O"
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
    # 'archive' is a collection item, just like 'database'
    # archive "git-repositories" do
    #   # files and directories to backup
    #   files "/home/git/repositories"
    # end

    # archive "etc-files" do
    #   files "/etc"
    #   # exlude those files/directories
    #   exclude "/etc/puppet/other"
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
