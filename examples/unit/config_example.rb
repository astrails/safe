require File.expand_path(File.dirname(__FILE__) + '/../example_helper')

describe Astrails::Safe::Config do
  it "should parse example config" do
    config = Astrails::Safe::Config::Node.new do
      local do
        path "path"
      end

      s3 do
        key "s3 key"
        secret "secret"
        bucket "bucket"
        path "path1"
      end

      sftp do
        user "sftp user"
        password "sftp password"
        host "sftp host"
      end

      gpg do
        key "gpg-key"
        password "astrails"
      end

      keep do
        local 4
        s3 20
      end

      mysqldump do
        options "-ceKq --single-transaction --create-options"

        user "astrails"
        password ""
        host "localhost"
        port 3306
        socket "/var/run/mysqld/mysqld.sock"

        database :blog

        database :production do
          keep :local => 3

          gpg do
            password "custom-production-pass"
          end

          skip_tables [:logger_exceptions, :request_logs]
        end

      end

      pgdump do
        options "-i -x -O"

        user "astrails"
        password ""
        host "localhost"
        port 5432

        database :blog

        database :production do
          keep :local => 3

          skip_tables [:logger_exceptions, :request_logs]
        end

      end

      svndump do
        repo :my_repo do
          repo_path "/home/svn/my_repo"
        end
      end

      tar do
        archive "git-repositories" do
          files "/home/git/repositories"
        end

        archive "etc-files" do
          files "/etc"
          exclude "/etc/puppet/other"
        end

        archive "dot-configs" do
          files "/home/*/.[^.]*"
        end

        archive "blog" do
          files "/var/www/blog.astrails.com/"
          exclude ["/var/www/blog.astrails.com/log", "/var/www/blog.astrails.com/tmp"]
        end

        archive :misc do
          files [ "/backup/*.rb" ]
        end
      end

    end

    expected = {
      "local" => {"path" => "path"},

      "s3" => {
        "key" => "s3 key",
        "secret" => "secret",
        "bucket" => "bucket",
        "path" => "path1",
      },

      "sftp" => {
        "user" => "sftp user",
        "password" => "sftp password",
        "host" => "sftp host",
      },

      "gpg" => {"password" => "astrails", "key" => "gpg-key"},

      "keep" => {"s3" => 20, "local" => 4},

      "mysqldump" => {
        "options" => "-ceKq --single-transaction --create-options",
        "user" => "astrails",
        "password" => "",
        "host" => "localhost",
        "port" => 3306,
        "socket" => "/var/run/mysqld/mysqld.sock",

        "databases" => {
          "blog" => {},
          "production" => {
           "keep" => {"local" => 3},
           "gpg" => {"password" => "custom-production-pass"},
            "skip_tables" => ["logger_exceptions", "request_logs"],
          },
        },
      },

      "pgdump" => {
        "options" => "-i -x -O",
        "user" => "astrails",
        "password" => "",
        "host" => "localhost",
        "port" => 5432,

        "databases" => {
          "blog" => {},
          "production" => {
           "keep" => {"local" => 3},
            "skip_tables" => ["logger_exceptions", "request_logs"],
          },
        },
      },

      "svndump" => {
        "repos" => {
          "my_repo"=> {
            "repo_path" => "/home/svn/my_repo"
          }
        }
      },

      "tar" => {
        "archives" => {
          "git-repositories" => {"files" => "/home/git/repositories"},
          "etc-files" => {"files" => "/etc", "exclude" => "/etc/puppet/other"},
          "dot-configs" => {"files" => "/home/*/.[^.]*"},
          "blog" => {
            "files" => "/var/www/blog.astrails.com/",
            "exclude" => ["/var/www/blog.astrails.com/log", "/var/www/blog.astrails.com/tmp"],
          },
          "misc" => { "files" => ["/backup/*.rb"] },
        },
      },
    }

    config.to_hash.should == expected
  end

  it "should make an array from multivalues" do
    config = Astrails::Safe::Config::Node.new do
      skip_tables "a"
      skip_tables "b"
      files "/foo"
      files "/bar"
      exclude "/foo/bar"
      exclude "/foo/bar/baz"
    end

    expected = {
      "skip_tables" => ["a", "b"],
      "files" => ["/foo", "/bar"],
      "exclude" => ["/foo/bar", "/foo/bar/baz"],
    }

    config.to_hash.should == expected
  end

  it "should raise error on key duplication" do
    proc do
      Astrails::Safe::Config::Node.new do
        path "foo"
        path "bar"
      end
    end.should raise_error(ArgumentError, "duplicate value for 'path'")
  end

end
