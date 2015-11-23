Dandelion
=========
[![Gem Version](https://badge.fury.io/rb/dandelion.png)](http://badge.fury.io/rb/dandelion)
[![Build Status](https://travis-ci.org/scttnlsn/dandelion.png)](https://travis-ci.org/scttnlsn/dandelion)
[![Dependency Status](https://gemnasium.com/scttnlsn/dandelion.png)](https://gemnasium.com/scttnlsn/dandelion)
[![Code Climate](https://codeclimate.com/github/scttnlsn/dandelion.png)](https://codeclimate.com/github/scttnlsn/dandelion)

Incremental Git repository deployment.

Install
-------

Ensure that Ruby >= 2.0.0 is installed, then run:

    $ gem install dandelion

You may need to install `pkg-config` and `cmake` before installing Dandelion.  They're likely available in your OS package manager.  For example:

    $ brew install pkg-config cmake

or

    $ apt-get install pkg-config cmake

Config
------

Configuration options are specified in a YAML file (by default, the root of your
Git repository is searched for a file named `dandelion.yml`).

Example:

```yaml
adapter: sftp
host: example.com
username: user
password: pass
path: path/to/deployment

exclude:
    - .gitignore
    - dandelion.yml
    - dir/

additional:
    - config/auth.yml
```

Required:

 * `adapter` (alias: `scheme`, the file transfer adapter)

Optional:

* `path` (relative path from root of remote file tree, defaults to the root)
* `local_path` (relative path from root of local repository, defaults to repository root)
* `exclude` (list of files or directories to exclude from deployment, if `local_path` is set files are relative to that path)
* `additional` (additional list of files from your working directory that will be deployed)
* `revision_file` (remote file in which revision SHA is stored, defaults to .revision)

The `additional` section can either take a list of local file names or key-value formats if you want to upload something to a specific path:

```yaml
additional:
    - localdir: remotedir
    - file.txt: remotedir/file.txt
```

The `localdir` in this example is relative to the repository root (ignoring `local_path` if you set it).

Each adapter also has additional required and optional configuration parameters (see below).  Note that you can dynamically set configuration values by using environment variables.  For example:

```yaml
password: <%= ENV['DANDELION_PASSWORD'] %>
```

Adapters
--------

There is support for multiple backend file transfer adapters.  The configuration
must specify one of these adapters and the set of additional parameters required
by the given adapter.

**SFTP**: `adapter: sftp` (honors SSH config files)

Required:

 * `host`
 * `username`
 * `password` (not required if you're using an SSH key)

Optional:

 * `port` (defaults to 22)
 * `preserve_permissions` (defaults to true)

**FTP**: `adapter: ftp`

Required:

 * `host`
 * `username`
 * `password`

Optional:

 * `port` (defaults to 21)
 * `passive` (defaults to false)

**FTPS**: `adapter: ftps` (ftp over TLS, based on [DoubleBagFTPS](https://github.com/bnix/double-bag-ftps) and Dandelions native FTP adapter)

Required: (same as FTP)

 * `host`
 * `username`
 * `password`

Optional: (in addition to options for FTP)

 * `port`
 * `passive`
 * `auth_tls` (default false)
 * `ftps_implicit` (default false: explicit TLS)
 * `insecure` (default false, true to allow self-signed certificates)

**Amazon S3**: `adapter: s3`

Required:

 * `access_key_id`
 * `secret_access_key`
 * `bucket_name`
 * `host` (one of the endpoints listed [here](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region), defaults to s3.amazonaws.com)

Optional:

 * `preserve_permissions` (defaults to true)
 * `cache_control` (time to cache content in seconds, e.g. '1296000')
 * `expires` (time to cache content in seconds, e.g. '1296000')

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
        init
        status

Note that when specifying the repository or configuration file, the given paths
are relative to the current working directory (not the repository root).

To see the options for a particular command, run `dandelion <command> -h`:

    $ dandelion deploy -h
    Usage: dandelion deploy [options] [<revision>]
            --dry-run                    Show what would have been deployed
