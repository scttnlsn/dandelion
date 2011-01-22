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
In the root of the Git repository you wish to deploy, create a `deploy.yml`
file:

    scheme: sftp
    host: example.com
    username: user
    password: pass
    path: path/to/deployment
    
    exclude:
      - .gitignore
      - deploy.yml
      
Then, to deploy the HEAD revision of the repository, run:

    $ dandelion
    
If the repository has previously been deployed then only the files that have
changed since the last deployment will be transferred.  All files (except those
excluded) will be transferred on first deployment.