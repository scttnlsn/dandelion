require 'deploy/deployment'
require 'deploy/service'
require 'yaml'

module Deploy
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
      
      if config['scheme'] == 'sftp'
        service = Service::SFTP.new(config['host'], config['username'], config['password'], config['path'])
      else
        puts "Unsupported scheme: #{config['scheme']}"
      end
      
      puts "Connecting to:   #{service.uri}"

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