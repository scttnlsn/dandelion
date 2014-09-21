require 'dandelion/utils'

module Dandelion
  module Adapter
    class DBFTP < Dandelion::Adapter::FTP
      include ::Dandelion::Utils

      adapter 'ftps'
      requires_gems 'double-bag-ftps'
      
      def initialize(config)
        require 'double_bag_ftps'
        
        @config = config
        
        @config[:auth_tls] = to_b(@config[:auth_tls])
        @config[:ftps_implicit] = to_b(@config[:ftps_implicit])
        @config[:inscecure] = to_b(@config[:insecure])
        
        super
      end

      private

      def ftp_client
        ftps_mode = @config['ftps_implicit'] ? DoubleBagFTPS::IMPLICIT : DoubleBagFTPS::EXPLICIT
        
        ftps = DoubleBagFTPS.new(@config['host'], nil, nil, nil, ftps_mode, {})
        
        if( @config['insecure'] )
          ftps.ssl_context = DoubleBagFTPS.create_ssl_context(:verify_mode => OpenSSL::SSL::VERIFY_NONE)
        end 
        
        auth = @config['auth_tls'] ? 'TLS' : nil
        ftps.login( @config['username'], @config['password'], nil, auth )
        
        ftps.chdir(@config['path']) if @config['path']
        
        ftps.passive = @config['passive']
        
        ftps
      end
    end
  end
end