require "spec_helper"

describe Stormpath::Rails::UsersController, type: :controller do
  it { should be_a Stormpath::Rails::BaseController }

  describe "on GET to #new" do
    context "when signed out" do
      it "renders a form for a new user" do
        get :new

        expect(response).to be_success
        expect(response).to render_template(:new)
      end
    end
  end

  describe "on POST to #create" do
    let(:user_attributes) { attributes_for(:user) }

    context "invalid data" do
      it "without email render email error" do
        post :create, user: attributes_for(:user, email: "")
        expect(flash[:error]).to eq('Account email address cannot be null, empty, or blank.')
      end

      it "with invalid email render email error" do
        post :create, user: attributes_for(:user, email: "test")
        expect(flash[:error]).to eq('Account email address is in an invalid format.')
      end

      it "without password render password error" do
        post :create, user: attributes_for(:user, password: "")
        expect(flash[:error]).to eq('Account data cannot be null, empty, or blank.')
      end

      it "with short password render password error" do
        post :create, user: attributes_for(:user, password: "pass")
        expect(flash[:error]).to eq('Account password minimum length not satisfied.')
      end

      it "without numeric character in password render numeric error" do
        post :create, user: attributes_for(:user, password: "somerandompass")
        expect(flash[:error]).to eq('Password requires at least 1 numeric character.')
      end

      it "without upercase character in password render upercase error" do
        post :create, user: attributes_for(:user, password: "somerandompass123")
        expect(flash[:error]).to eq('Password requires at least 1 uppercase character.')
      end
    end

    context "user verification enabled" do
      before do
        Stormpath::Rails.config.verify_email = true
      end

      it "creates a user" do
        expect { post :create, user: user_attributes }.to change(User, :count).by(1)
      end

      it "renders verified template" do
        post :create, user: user_attributes

        expect(response).to be_success
        expect(response).to render_template(:verified)
      end
    end

    context "user verification disabled" do
      before do
        Stormpath::Rails.config.verify_email = false
      end

      it "creates a user" do
        expect { post :create, user: user_attributes }.to change(User, :count).by(1)
      end

      it "redirects to root_path on successfull login" do
        post :create, user: user_attributes
        expect(response).to redirect_to(root_path)
      end

      it "stores user_id in session" do
        post :create, user: user_attributes
        expect(session[:user_id]).to_not be_nil
      end
    end
  end
end