class Stormpath::Rails::SessionsController < Stormpath::Rails::BaseController
  before_filter :redirect_signed_in_users, only: :new

  def create
    result = authenticate user_from_params

    if result.success?
      @user = find_user_by_email params[:session][:email]
      initialize_session(@user)

      redirect_to root_path, notice: 'Successfully signed in'
    else
      set_flash_message :error, result.error_message
      render template: "sessions/new"
    end
  end

  def destroy
    logout
    set_flash_message :notice, 'You have been logged out successfully.'
    redirect_to root_url
  end

  def new
    if configuration.id_site.enabled
      redirect_to id_site_login_url
    else
      render template: "sessions/new"
    end
  end

  def omniauth_login
    result = create_omniauth_user('facebook', params[:access_token])

    user = find_or_create_user_from_account(result.account)
    initialize_session user 
    set_flash_message :notice, "Successfully signed in"

    redirect_to root_path
  end

  def redirect
    user_data = handle_id_site_callback(request.url)
    @user = find_user_by_email user_data.email
    initialize_session(@user)

    redirect_to root_path, notice: 'Successfully signed in'
  end

  private

  def user_from_params
    ::User.new.tap do |user|
      user.email = params[:session][:email]
      user.password = params[:session][:password]
    end
  end

  def redirect_signed_in_users
    redirect_to root_path if signed_in?
  end
end
