require 'dandelion/utils'

module Dandelion
  module Adapter
    class FTPS < Dandelion::Adapter::FTP
      include ::Dandelion::Utils

      adapter 'ftps'
      requires_gems 'double-bag-ftps'

      def initialize(config)
        require 'double_bag_ftps'

        config[:auth_tls] = to_b(config[:auth_tls])
        config[:ftps_implicit] = to_b(config[:ftps_implicit])
        config[:inscecure] = to_b(config[:insecure])

        super(config)
      end

    private

      def ftp_client
        ftps = DoubleBagFTPS.new(@config['host'], nil, nil, nil, ftps_mode, {})

        if @config['insecure']
          ftps.ssl_context = DoubleBagFTPS.create_ssl_context(verify_mode: OpenSSL::SSL::VERIFY_NONE)
        end

        ftps.login(@config['username'], @config['password'], nil, ftps_auth)
        ftps.passive = @config[:passive]

        ftps
      end

      def ftps_auth
        @config['auth_tls'] ? 'TLS' : nil
      end

      def ftps_mode
        @config['ftps_implicit'] ? DoubleBagFTPS::IMPLICIT : DoubleBagFTPS::EXPLICIT
      end
    end
  end
end
