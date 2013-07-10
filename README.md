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
    # --------

    scheme: sftp
    host: example.com
    username: user
    password: pass

    # Optional
    # --------

    # Remote path
    path: path/to/deployment

    # Local Path
    local_path: path/in/repo

    # Remote file name in which the current revision is stored
    revision_file: .revision

    # These files (from Git) will not be uploaded during a deploy
    exclude:
        - .gitignore
        - dandelion.yml

    # These files (from your working directory) will be uploaded on every deploy
    additional:
        - public/css/print.css
        - public/css/screen.css
        - public/js/main.js

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
 * `local_path` (defaults to repository root)
 * `exclude` (if local_path is set, files are relative to that path)
 * `additional`
 * `port`
 * `revision_file` (defaults to .revision)
 * `preserve_permissions` (defaults to true)

**FTP**: `scheme: ftp`

Required:

 * `host`
 * `username`
 * `password`

Optional:

 * `path`
 * `local_path` (defaults to repository root)
 * `exclude` (if local_path is set, files are relative to that path)
 * `additional`
 * `port`
 * `revision_file` (defaults to .revision)
 * `passive` (defaults to true)

**Amazon S3**: `scheme: s3`

Required:

 * `access_key_id`
 * `secret_access_key`
 * `bucket_name`

Optional:

 * `path`
 * `local_path` (defaults to repository root)
 * `exclude` (if local_path is set, files are relative to that path)
 * `additional`
 * `revision_file` (defaults to .revision)

Usage
-----
From within your Git repository, run:

    $ dandelion deploy

This will deploy the local `HEAD` revision to the location specified in the config
file.  Dandelion keeps track of the currently deployed revision so that only files
which have been added/changed/deleted need to be transferred.

You can specify the revision you wish to deploy and Dandelion will determine which
files need to be transferred:

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
