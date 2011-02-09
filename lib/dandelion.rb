require 'dandelion/deployment'
require 'dandelion/service'
require 'yaml'

module Dandelion
  class << self
    def run
      unless File.exists? '.git'
        puts 'Not a git repository: .git'
        exit
      end
      
      if ARGV[0]
        config_file = ARGV[0].strip
      else
        config_file = 'dandelion.yml'
      end

      unless File.exists? config_file
        puts "Could not find file: #{config_file}"
        exit
      end

      config = YAML.load_file config_file

      if config['scheme'] == 'sftp'
        service = Service::SFTP.new(config['host'], config['username'], config['password'], config['path'])
      else
        puts "Unsupported scheme: #{config['scheme']}"
        exit
      end

      puts "Connecting to:    #{service.uri}"

      begin
        # Deploy changes since remote revision
        deployment = Deployment::DiffDeployment.new('.', service, config['exclude'])

        puts "Remote revision:  #{deployment.remote_revision}"
        puts "Local revision:   #{deployment.local_revision}"

        deployment.deploy
      rescue Deployment::RemoteRevisionError
        # No remote revision, deploy everything
        deployment = Deployment::FullDeployment.new('.', service, config['exclude'])

        puts "Remote revision:  ---"
        puts "Local revision:   #{deployment.local_revision}"

        deployment.deploy
      end

      puts "Deployment complete"
    end
  end
end
