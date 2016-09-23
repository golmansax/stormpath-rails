module Stormpath
  module Rails
    module Router
      STORMPATH_DEFAULT_ACTIONS_MAP = {
        'register#new' => 'stormpath/rails/register/new#call',
        'register#create' => 'stormpath/rails/register/create#call',
        'login#new' => 'stormpath/rails/login/new#call',
        'login#create' => 'stormpath/rails/login/create#call',
        'logout#create' => 'stormpath/rails/logout/create#call',
        'forgot_password#new' => 'stormpath/rails/forgot_password/new#call',
        'forgot_password#create' => 'stormpath/rails/forgot_password/create#call',
        'change_password#new' => 'stormpath/rails/change_password/new#call',
        'change_password#create' => 'stormpath/rails/change_password/create#call',
        'profile#show' => 'stormpath/rails/profile/show#call',
        'oauth2#new' => 'stormpath/rails/oauth2/new#call',
        'oauth2#create' => 'stormpath/rails/oauth2/create#call',
        'verify_email#show' => 'stormpath/rails/verify_email/show#call',
        'verify_email#create' => 'stormpath/rails/verify_email/create#call',
        'id_site#login' => 'stormpath/rails/id_site/login#call',
        'id_site#logout' => 'stormpath/rails/id_site/logout#call'
      }.freeze

      def stormpath_rails_routes(actions: {})
        actions = STORMPATH_DEFAULT_ACTIONS_MAP.merge(actions)

        constraints Stormpath::Rails::RoutingConstraint do
          if Stormpath::Rails.config.web.register.enabled
            get Stormpath::Rails.config.web.register.uri => actions['register#new'], as: :new_register
            post Stormpath::Rails.config.web.register.uri => actions['register#create'], as: :register
          end

          # LOGIN
          if Stormpath::Rails.config.web.login.enabled
            get Stormpath::Rails.config.web.login.uri => actions['login#new'], as: :new_login
            post Stormpath::Rails.config.web.login.uri => actions['login#create'], as: :login
          end

          # LOGOUT
          if Stormpath::Rails.config.web.logout.enabled
            post Stormpath::Rails.config.web.logout.uri => actions['logout#create'], as: :logout
          end

          # FORGOT PASSWORD
          if Stormpath::Rails.config.web.forgot_password.enabled
            get Stormpath::Rails.config.web.forgot_password.uri => actions['forgot_password#new'], as: :new_forgot_password
            post Stormpath::Rails.config.web.forgot_password.uri => actions['forgot_password#create'], as: :forgot_password
          end

          # CHANGE PASSWORD
          if Stormpath::Rails.config.web.change_password.enabled
            get Stormpath::Rails.config.web.change_password.uri => actions['change_password#new'], as: :new_change_password
            post Stormpath::Rails.config.web.change_password.uri => actions['change_password#create'], as: :change_password
          end

          # ME
          if Stormpath::Rails.config.web.me.enabled
            get Stormpath::Rails.config.web.me.uri => actions['profile#show']
          end

          # OAUTH2
          if Stormpath::Rails.config.web.oauth2.enabled
            get Stormpath::Rails.config.web.oauth2.uri => actions['oauth2#new']
            post Stormpath::Rails.config.web.oauth2.uri => actions['oauth2#create']
          end

          # VERIFY EMAIL
          if Stormpath::Rails.config.web.verify_email.enabled
            get Stormpath::Rails.config.web.verify_email.uri => actions['verify_email#show'], as: :new_verify_email
            post Stormpath::Rails.config.web.verify_email.uri => actions['verify_email#create'], as: :verify_email
          end

          # ID SITE LOGIN
          if Stormpath::Rails.config.web.id_site.enabled
            get '/id_site_result' => actions['id_site#login'], as: :id_site_result
            get '/logout_id_site' => actions['id_site#logout'], as: :logout_id_site
          end
        end
      end
    end
  end
end

ActionDispatch::Routing::Mapper.include(Stormpath::Rails::Router)
