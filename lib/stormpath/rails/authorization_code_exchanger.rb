module Stormpath
  module Rails
    class AuthorizationCodeExchanger
      attr_reader :provider, :root_url, :params, :uri, :redirect_uri, :client_id, :client_secret

      def initialize(provider, root_url, params)
        @provider = provider
        @root_url = root_url
        @params = params
        configure
      end

      def access_token
        @access_token ||= fetch_access_token(exchange_auth_code.body)
      end

      private

      def exchange_auth_code
        https.post(uri, encoded_params, {'Accept' => 'application/json'})
      end

      def fetch_access_token(response_body)
        JSON.parse(response_body)['access_token']
      end

      def encoded_params
        URI.encode_www_form(
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          code: code
        )
      end

      def https
        protocol = Net::HTTP.new(uri.host, uri.port)
        protocol.use_ssl = true
        protocol
      end

      def configure
        case provider
        when :facebook
          @uri = URI 'https://graph.facebook.com/v2.7/oauth/access_token'
          @redirect_uri = "#{root_url[0...-1]}#{Stormpath::Rails.config.web.social.facebook.uri}"
          @client_id = Stormpath::Rails.config.web.facebook_app_id
          @client_secret = Stormpath::Rails.config.web.facebook_app_secret
        when :github
          @uri = URI 'https://github.com/login/oauth/access_token'
          @redirect_uri = "#{root_url[0...-1]}#{Stormpath::Rails.config.web.social.github.uri}"
          @client_id = Stormpath::Rails.config.web.github_app_id
          @client_secret = Stormpath::Rails.config.web.github_app_secret
        else
          raise(NoSptokenError)
        end
      end

      def code
        raise(NoSptokenError) if params[:code].nil?
        params[:code]
      end
    end
  end
end
