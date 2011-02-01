dandelion
=========

Install
-------
Ensure that Ruby and RubyGems are installed, then run:

    $ gem install dandelion
    
Alternatively, you can build the gem yourself:

    $ git clone git://github.com/scottbnel/dandelion.git
    $ cd dandelion
    $ rake install
    
Usage
-----
Deployment options are specified in a YAML file.  By default, Dandelion looks for
one named `dandelion.yml`, however, this can be overridden by passing a path as an
argument.

    scheme: sftp
    host: example.com
    username: user
    password: pass
    path: path/to/deployment
    
    exclude:
      - .gitignore
      - dandelion.yml
      
To deploy the HEAD revision, ensure you are in the root of the repository and run:

    $ dandelion
    
If the repository has previously been deployed then only the files that have
changed since the last deployment will be transferred.  All files (except those
excluded) will be transferred on first deployment.