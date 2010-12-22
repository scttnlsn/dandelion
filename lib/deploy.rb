require 'rubygems'
require 'grit'
require 'net/sftp'
require 'yaml'

module Deploy
  
  class Diff
    
    attr_reader :revision
    
    def initialize(revision)
      @revision = revision
      @raw = `git diff --name-status #{@revision} HEAD`
    end
  
    def changed
      files_flagged ['A', 'C', 'M']
    end
  
    def deleted
      files_flagged ['D']
    end
  
    private
  
    def files_flagged(statuses)
      items = []
      @raw.split("\n").each do |line|
        status, file = line.split("\t")
        items << file if statuses.include? status
      end
      items
    end
  
  end

  class Tree
  
    def initialize(revision)
      @commit = Grit::Repo.new('.').commit(revision)
      @tree = @commit.tree
    end
  
    def show(file)
      (@tree / file).data
    end
    
    def revision
      @commit.sha
    end
  
  end
  
  class Service
    
    def initialize(host, username, path)
      @host = host
      @username = username
      @path = path
    end
    
    def uri
      "#{@scheme}://#{@username}@#{@host}/#{@path}"
    end
    
  end
  
  class SFTP < Service

    def initialize(host, username, password, path)
      super(host, username, path)
      @scheme = 'sftp'
      @sftp = Net::SFTP.start(host, username, :password => password)
    end
    
    def read(file)
      @sftp.file.open(File.join(@path, file), 'r') do |f|
        f.gets
      end
    end
    
    def write(file, data)
      path = File.join(@path, file)
      begin
        dir = File.dirname(path)
        @sftp.stat!(dir)
      rescue Net::SFTP::StatusException => e
        raise unless e.code == 2
        mkdir_p(dir)
      end
      @sftp.file.open(path, 'w') do |f|
        f.puts data
      end
    end
    
    def delete(file)
      path = File.join(@path, file)
      @sftp.remove!(path)
      cleanup(File.dirname(path))
    end
    
    private
    
    def cleanup(dir)
      unless File.identical?(dir, @path)
        if empty?(dir)
          @sftp.rmdir!(dir)
          cleanup(File.dirname(dir))
        end
      end
    end
    
    def empty?(dir)
      @sftp.dir.entries(dir).map do |entry|
        entry.name unless entry.name == '.' or entry.name == '..'
      end.compact.empty?
    end
    
    def mkdir_p(dir)
      begin
        @sftp.mkdir!(dir)
      rescue Net::SFTP::StatusException => e
        raise unless e.code == 2
        mkdir_p(File.dirname(dir))
        mkdir_p(dir)
      end
    end

  end
  
  class Deployment
    
    def initialize(config, revision = 'HEAD')
      @config = config
      @service = create_service
      @diff = Deploy::Diff.new(read_revision)
      @tree = Deploy::Tree.new(revision)
    end
    
    def local_revision
      @tree.revision
    end
    
    def remote_revision
      @diff.revision
    end
    
    def remote_uri
      @service.uri
    end
    
    def deploy
      if remote_revision != local_revision
        @diff.changed.each do |file|
          puts "Uploading file: #{file}"
          @service.write(file, @tree.show(file))
        end
        @diff.deleted.each do |file|
          puts "Deleting file: #{file}"
          @service.delete(file)
        end
        @service.write('.revision', local_revision)
        puts "Deployment complete"
      else
        puts "Nothing to deploy"
      end
    end
    
    private
    
    def create_service
      if @config['scheme'] == 'sftp'
        SFTP.new(@config['host'], @config['username'], @config['password'], @config['path'])
      else
        raise "Unsupported scheme: #{@config['scheme']}"
      end
    end
    
    def read_revision
      begin
        @service.read('.revision').chomp
      rescue Net::SFTP::StatusException => e
        raise unless e.code == 2
        raise "Could not find remote file: .revision"
      end
    end
    
  end
  
  class << self
    
    def run
      unless File.exists? '.git'
        puts 'Not a git repository: .git'
        exit
      end

      unless File.exists? 'deploy.yml'
        puts 'Could not find file: deploy.yml'
        exit
      end

      config = YAML.load_file 'deploy.yml'

      deployment = Deploy::Deployment.new(config)

      puts "Connected to:     #{deployment.remote_uri}"
      puts "Remote revision:  #{deployment.remote_revision}"
      puts "Local revision:   #{deployment.local_revision}"

      deployment.deploy
    end
    
  end

end