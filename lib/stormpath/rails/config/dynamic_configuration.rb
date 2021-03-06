module Stormpath
  module Rails
    module Config
      class DynamicConfiguration
        attr_reader :static_config

        delegate(
          :facebook_app_id,
          :facebook_app_secret,
          :github_app_id,
          :github_app_secret,
          :google_app_id,
          :linkedin_app_id,
          to: :social_login_verification
        )
        delegate(:client_api_enabled, :client_api_domain, to: :application_client_api)

        def initialize(static_config)
          @static_config = static_config
          proccess_account_store_verification
          process_multitenancy_verification if static_config.stormpath.web.multi_tenancy.enabled
          process_id_site_verification if static_config.stormpath.web.id_site.enabled
        end

        def app
          @app ||= Config::ApplicationResolution.new(
            static_config.stormpath.application.href,
            static_config.stormpath.application.name
          ).app
        end

        def forgot_password_enabled?
          return false if static_config.stormpath.web.forgot_password.enabled == false
          password_reset_enabled?
        end

        def change_password_enabled?
          return false if static_config.stormpath.web.change_password.enabled == false
          password_reset_enabled?
        end

        def has_social_providers?
          facebook_app_id || github_app_id || google_app_id || linkedin_app_id
        end

        def verify_email_enabled?
          return false if static_config.stormpath.web.verify_email.enabled == false
          email_verification_enabled?
        end

        private

        def password_reset_enabled?
          return false if default_account_store.nil?
          default_account_store.password_policy.reset_email_status == 'ENABLED'
        end

        def email_verification_enabled?
          return false if default_account_store.nil?
          default_account_store.account_creation_policy.verification_email_status == 'ENABLED'
        end

        def default_account_store
          @default_account_store ||=
            app.default_account_store_mapping && app.default_account_store_mapping.account_store
        end

        def proccess_account_store_verification
          AccountStoreVerification.new(
            app.href,
            static_config.stormpath.web.register.enabled
          ).call
        end

        def application_client_api
          ApplicationClientApi.new(app)
        end

        def process_multitenancy_verification
          MultitenancyVerification.new(static_config.stormpath.web).call
        end

        def process_id_site_verification
          IdSiteVerification.new(static_config.stormpath.web).call
        end

        def social_login_verification
          @social_login_verification ||= SocialLoginVerification.new(app.href)
        end
      end
    end
  end
end
