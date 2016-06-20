module Stormpath
  module Rails
    class EmailVerificationController < BaseController
      def show
        VerifyEmailToken.new(params[:sptoken]).call

        respond_to do |format|
          format.html { redirect_to configuration.web.verify_email.next_uri }
          format.json { render nothing: true, status: 200 }
        end
      rescue Stormpath::Error => error
        status = error.status.presence || 400
        respond_to do |format|
          format.html { redirect_to configuration.web.change_password.error_uri }
          format.json { render json: { status: status, message: error.message }, status: status }
        end
      rescue VerifyEmailToken::InvalidSptokenError => error
        respond_to do |format|
          format.html { render template: 'email_verification/new' }
          format.json { render json: { status: 404, message: error.message }, status: 404 }
        end
      rescue VerifyEmailToken::NoSptokenError => error
        respond_to do |format|
          format.html { render template: 'email_verification/new' }
          format.json { render json: { status: 400, message: error.message }, status: 400 }
        end
      end

      def create
        begin
          ResendEmailVerification.new(params[:email]).call
          respond_to do |format|
            format.html { redirect_to "#{configuration.web.login.uri}?status=unverified" }
            format.json { render nothing: true }
          end
        rescue ResendEmailVerification::UnexistingEmailError
          respond_to do |format|
            format.html { redirect_to "#{configuration.web.login.uri}?status=unverified" }
            format.json { render nothing: true }
          end
        rescue ResendEmailVerification::NoEmailError => error
          respond_to do |format|
            format.json { render json: { status: 400, message: error.message }, status: 400 }
            format.html do
              set_flash_message :error, error.message
              render template: 'email_verification/new'
            end
          end
        end
      end
    end
  end
end
