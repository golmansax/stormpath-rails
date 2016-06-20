require 'spec_helper'

describe 'Email Verification GET', type: :request, vcr: true do
  let(:response_body) { JSON.parse(response.body) }

  let(:dir_with_verification) do
    Stormpath::Rails::Client.client.directories.get(
      ENV.fetch('STORMPATH_SDK_TEST_DIRECTORY_WITH_VERIFICATION_URL')
    )
  end

  let(:account) { dir_with_verification.accounts.create(account_attrs) }

  let(:account_attrs) do
    {
      email: 'example@test.com',
      given_name: 'Example',
      surname: 'Test',
      password: 'Pa$$W0RD',
      username: 'SirExample'
    }
  end

  let(:sptoken) { account.email_verification_token.token }

  before do
    account
    enable_email_verification
    Rails.application.reload_routes!
  end

  after do
    account.delete
  end

  context 'application/json' do
    def json_verify_get(attrs = {})
      get '/verify', attrs, 'HTTP_ACCEPT' => 'application/json'
    end

    context 'valid data' do
      it 'return 200 OK' do
        json_verify_get(sptoken: sptoken)
        expect(response.status).to eq(200)
        expect(response.body).to eq('')
      end
    end

    context 'invalid data' do
      it 'return 404 OK' do
        json_verify_get(sptoken: 'invalid-sptoken')
        expect(response.status).to eq(404)
        expect(response_body['message']).to eq('The requested resource does not exist.')
      end
    end

    context 'no data' do
      it 'return 400' do
        json_verify_get
        expect(response.status).to eq(400)
        expect(response_body['message']).to eq('sptoken parameter not provided.')
      end
    end
  end
end