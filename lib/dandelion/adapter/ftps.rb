require 'dandelion/utils'

module Dandelion
  module Adapter
    class FTPS < Dandelion::Adapter::FTP
      include ::Dandelion::Utils

      adapter 'ftps'

      def initialize(config)
        config[:ftps_implicit] = to_b(config[:ftps_implicit])
        config[:insecure] = to_b(config[:insecure])

        super(config)
      end

    private

      def ftp_client
        host = @config['host']
        ftps = Net::FTP.new(host, connection_params)
        if @config['ascii']
          ftps.binary = false
        end

        def connection_params
          {
             port: @config['port'],
             ssl: ssl_context_params,
             passive: @config['passive'],
             implicit_ftps: @config['ftps_implicit'],
             username: @config['username'],
             password: @config['password'],
             debug_mode: @config['debug']
          }
        end
      end

      def ssl_context_params
        @config['insecure'] ? { verify_mode: OpenSSL::SSL::VERIFY_NONE } : true
      end
    end
  end
end
