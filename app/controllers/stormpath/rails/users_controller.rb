module Stormpath
  module Rails
    class UsersController < BaseController
      def create
        begin
          form = RegistrationForm.new(
            params.except(:controller, :action, :format, :user, :utf8, :button)
          )

          database_user

          if form.save
            database_user.save

            if api_request?
              render json: AccountSerializer.to_h(form.account)
            else
              if configuration.web.verify_email.enabled
                redirect_to "#{configuration.web.login.uri}?status=unverified"
              else
                if configuration.web.register.auto_login
                  initialize_session(database_user, form.account.href)
                  #login the user
                  redirect_to configuration.web.register.next_uri
                else
                  redirect_to "#{configuration.web.login.uri}?status=created"
                end
              end
            end
          else
            reply_with_error(form.errors.full_messages.first)
          end
        rescue RegistrationForm::ArbitraryDataSubmitted => error
          reply_with_error(error.message)
        end
      end

      private def reply_with_error(error_message)
        respond_to do |format|
          format.json { render json: { status: 400, message: error_message }, status: 400 }
          format.html do
            set_flash_message :error, error_message
            render template: "users/new"
          end
        end
      end

      def new
        if configuration.web.id_site.enabled
          redirect_to id_site_register_url
        else
          if signed_in?
            redirect_to root_path
          else
            database_user
            respond_to do |format|
              format.json { render json: RegistrationFormSerializer.to_h  }
              format.html { render template: "users/new" }
            end
          end
        end
      end

      def profile
        if signed_in?
          account = get_account current_user_href
          render json: account.properties
        else
          render nothing: true, status: 401
        end
      end

      def verify
        result = verify_email_token params[:sptoken]

        if result.success?
          @account_url = result.account_url
          render template: "users/verification_complete"
        else
          render template: "users/verification_failed"
        end
      end

      private

      def database_user
        @user ||= ::User.new(registration_params.slice(:email, :given_name, :surname))
      end

      def registration_params
        {
          email: params[:email],
          password: params[:password],
          given_name: params[:givenName],
          surname: params[:surname],
          middle_name: params[:middleName],
          username: params[:username]
        }
      end
    end
  end
end
