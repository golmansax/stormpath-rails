module Stormpath
  module Rails
    module Social
      extend ActiveSupport::Concern

      included do
        helper_method :facebook_login_enabled?, :facebook_app_id,
                      :google_login_enabled?, :google_client_id, :social_auth?,
                      :social_providers_present?
      end

      private

      def social_providers_present?
        Stormpath::Rails.config.web.has_social_providers
      end

      def facebook_login_enabled?
        false # facebook_app_id.present?
      end

      def google_login_enabled?
        false # google_client_id.present?
      end

      def facebook_app_id
        ENV['STORMPATH_FACEBOOK_APP_ID']
      end

      def google_client_id
        ENV['STORMPATH_GOOGLE_CLIENT_ID']
      end

      def social_auth?
        facebook_login_enabled? || google_login_enabled?
      end
    end
  end
end
