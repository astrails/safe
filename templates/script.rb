safe do
  # backup file path (full, including filename)
  # Note: do not include .tar, .sql, .gz or .pgp, it will be added automatically
  # supported substitutions:
  #   :kind -> backup 'engine' kind, e.g. "mysqldump" or "archive"
  #   :id -> backup 'id', e.g. "blog", "production", etc.
  #   :timestamp -> current run timestamp (same for all the backups in the same 'run')
  # you can set separate :path for all backups (or once globally here)
  path "/backup/:kind/:id-:timestamp"

  ## uncomment to enable uploads to Amazon S3
  ## Amazon S3 auth (optional)
  # s3 do
  #   key YOUR_S3_KEY
  #   secret YOUR_S3_SECRET
  #   bucket S3_BUCKET
  #   # prefix for uploads to S3. supports same substitution like :path
  #   prefix ":kind/:id" # this is default
  # end

  ## alternative style:
  # s3 :key => YOUR_S3_KEY, :secret => YOUR_S3_SECRET, :bucket => S3_BUCKET

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
