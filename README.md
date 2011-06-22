Dandelion
=========
Incremental Git repository deployment.

Install
-------
Ensure that Ruby and RubyGems are installed, then run:

    $ gem install dandelion
    
Alternatively, you can build the gem yourself:

    $ git clone git://github.com/scttnlsn/dandelion.git
    $ cd dandelion
    $ rake install
    
Config
------
Configuration options are specified in a YAML file (by default, the root of your
Git repository is searched for a file named `dandelion.yml`). Example:

    # Required
    scheme: sftp
    host: example.com
    username: user
    password: pass
    
    # Optional
    path: path/to/deployment
    exclude:
        - .gitignore
        - dandelion.yml

Schemes
-------
There is support for multiple backend file transfer schemes.  The configuration
must specify one of these schemes and the set of additional parameters required
by the given scheme.

**SFTP**: `scheme: sftp`

Required:
* `host`
* `username`
* `password`

Optional:
* `path`
* `exclude`
    
**FTP**: `scheme: ftp`

Required:
* `host`
* `username`
* `password`

Optional:
* `path`
* `exclude`
* `passive` (defaults to true)
    
**Amazon S3**: `scheme: s3`

Required:
* `access_key_id`
* `secret_access_key`
* `bucket_name`

Optional:
* `path`
* `exclude`

Usage
-----
From within your Git repository, run:

    $ dandelion deploy
    
This will deploy the local `HEAD` revision to the location specified in the config
file.  Dandelion keeps track of the most recently deployed revision so that only
files which have changed since the last deployment need to be transferred.

You can also specify an arbitrary revision you wish to deploy and Dandelion will
determine which files need to be transferred.

    $ dandelion deploy <revision>

For a more complete summary of usage options, run:

    $ dandelion -h
    Usage: dandelion [options] <command> [<args>]
        -v, --version                    Display the current version
        -h, --help                       Display this screen
            --repo=[REPO]                Use the given repository
            --config=[CONFIG]            Use the given configuration file

    Available commands:
        deploy
        status
        
Note that when specifying the repository or configuration file, the given paths
are relative to the current working directory (not the repository root).  To see
the options for a particular command, run:

    $ dandelion <command> -h
