require 'spec_helper'

describe 'Registration', type: :request, vcr: true do
  describe 'POST /register' do
    describe 'HTTP_ACCEPT=application/json' do
      def json_register_post(attrs = {})
        post '/register', attrs, { 'HTTP_ACCEPT' => 'application/json' }
      end

      def response_body
        JSON.parse(response.body)
      end

      def error_message
        response_body[:message]
      end

      def delete_account
        return unless response.status == 200
        Stormpath::Rails::Client.application.accounts.get(response_body['account']['href']).delete
      end

      let(:user_attrs) do
        { email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', username: 'SirExample' }
      end

      describe 'json is enabled' do
        describe 'submit valid form' do
          after { delete_account }
          it 'respond with status 200' do
            json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD')
            expect(response.status).to eq(200)
          end
        end

        describe 'submit blank givenName' do
          it 'respond with status 400' do
            json_register_post(email: 'example@test.com', surname: 'Test', password: 'Pa$$W0RD')
            expect(response.status).to eq(400)
            expect(error_message).to eq('First Name can\'t be blank')
          end
        end

        describe 'submit blank, enabled but not required middleName' do
          before do
            allow(web_config.register.form.fields.middle_name).to receive(:enabled).and_return(true)
          end

          after { delete_account }

          it 'respond with status 200' do
            json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD')
            expect(response.status).to eq(200)
          end
        end

        describe 'submit already existing email' do
          before do
            Stormpath::Rails::Client.application.accounts.create(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD')
          end

          it 'respond with status 400' do
            json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD')
            expect(response.status).to eq(400)
            expect(error_message).to eq('Email already exists')
          end
        end

        describe 'when email not required and submitted without email' do
          before do
            allow(web_config.register.form.fields.email).to receive(:required).and_return(false)
          end

          it 'respond with status 400' do
            json_register_post(givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD')
            expect(response.status).to eq(400)
            expect(error_message).to eq('Email can\'t be blank')
          end
        end

        describe 'when password not required and submitted without password' do
          before do
            allow(web_config.register.form.fields.password).to receive(:required).and_return(false)
          end

          it 'respond with status 400' do
            json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test')
            expect(response.status).to eq(400)
            expect(error_message).to eq('Password can\'t be blank')
          end
        end

        describe 'add a custom field' do
          describe 'that is required' do
            before do
              allow(web_config.register.form.fields).to receive(:age).and_return(
                OpenStruct.new(
                  enabled: true,
                  visible: true,
                  label: "Age",
                  placeholder: "Age",
                  required: true,
                  type: "number"
                )
              )
            end

            describe 'and submitted' do
              describe 'nested inside the root' do
                after { delete_account }

                it 'respond with status 200' do
                  json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', age: 25)
                  expect(response.status).to eq(200)
                  account = Stormpath::Rails::Client.application.accounts.get(response_body['account']['href'])
                  expect(account.custom_data[:age]).to eq(25)
                end
              end

              describe 'nested inside the customData hash' do
                after { delete_account }

                it 'respond with status 200' do
                  json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', customData: { age: 25 })
                  expect(response.status).to eq(200)
                  account = Stormpath::Rails::Client.application.accounts.get(response_body['account']['href'])
                  expect(account.custom_data[:age]).to eq(25)
                end
              end
            end

            describe 'and not submitted' do
              it 'respond with status 400' do
                json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', age: 25)
                expect(response.status).to eq(400)
                expect(error_message).to eq('Age can\'t be blank')
              end
            end
          end

          describe 'and its not required' do
            before do
              allow(web_config.register.form.fields).to receive(:age).and_return(
                OpenStruct.new(
                  enabled: true,
                  visible: true,
                  label: "Age",
                  placeholder: "Age",
                  required: false,
                  type: "number"
                )
              )
            end

            describe 'nested inside the root' do
              after { delete_account }

              it 'respond with status 200' do
                json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', age: 25)
                expect(response.status).to eq(200)
              end
            end

            describe 'nested inside the customData hash' do
              after { delete_account }

              it 'respond with status 200' do
                json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', customData: { age: 25 })
                expect(response.status).to eq(200)
              end
            end
          end
        end

        describe 'enable password confirmation' do
          before do
            allow(web_config.register.form.fields.confirm_password).to receive(:enabled).and_return(true)
          end

          describe 'if successfull' do
            after { delete_account }

            it 'responds with status 200 if matches' do
              json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', confirmPassword: 'Pa$$W0RD')
              expect(response.status).to eq(200)
            end
          end

          it 'responds with status 400 if does not match' do
            json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', confirmPassword: 'Pa$$')
            expect(response.status).to eq(400)
            expect(error_message).to eq('Password Confirmation can\'t be blank')
          end
        end

        describe 'disable the givenName and set it to UNKNOWN' do
          before do
            allow(web_config.register.form.fields.given_name).to receive(:enabled).and_return(false)
          end

          after { delete_account }

          it 'respond with status 200' do
            json_register_post(email: 'example@test.com', surname: 'Test', password: 'Pa$$W0RD')
            expect(response.status).to eq(200)
            expect(response_body['account']['givenName']).to eq('UNKNOWN')
          end
        end

        describe 'disable the surname and set it to UNKNOWN' do
          before do
            allow(web_config.register.form.fields.surname).to receive(:enabled).and_return(false)
          end

          after { delete_account }

          it 'respond with status 200' do
            json_register_post(email: 'example@test.com', givenName: 'Example', password: 'Pa$$W0RD')
            expect(response.status).to eq(200)
            expect(response_body['account']['surname']).to eq('UNKNOWN')
          end
        end

        describe 'dont require givenName, submit blank and set it to UNKNOWN' do
          before do
            allow(web_config.register.form.fields.given_name).to receive(:required).and_return(false)
          end

          after { delete_account }

          it 'respond with status 200' do
            json_register_post(email: 'example@test.com', surname: 'Test', password: 'Pa$$W0RD')
            expect(response.status).to eq(200)
            expect(response_body['account']['givenName']).to eq('UNKNOWN')
          end
        end

        describe 'dont require surname, submit blank and set it to UNKNOWN' do
          before do
            allow(web_config.register.form.fields.given_name).to receive(:required).and_return(false)
          end

          after { delete_account }

          it 'respond with status 200' do
            json_register_post(email: 'example@test.com', givenName: 'Example', password: 'Pa$$W0RD')
            expect(response.status).to eq(200)
            expect(response_body['account']['surname']).to eq('UNKNOWN')
          end
        end

        describe 'unknown field submission' do
          describe 'nested inside the root' do
            it 'respond with status 400' do
              json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', age: 25)
              expect(response.status).to eq(400)
              expect(error_message).to eq("Submission of unknown field: age")
            end
          end

          describe 'nested inside the customData hash' do
            it 'respond with status 400' do
              json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', customData: { age: 25 })
              expect(response.status).to eq(400)
              expect(error_message).to eq("Submission of unknown field: age")
            end
          end
        end

        describe 'a regular field that is disabled' do
          before do
            allow(web_config.register.form.fields.middle_name).to receive(:enabled).and_return(false)
          end

          it 'respond with status 400' do
            json_register_post(email: 'example@test.com', givenName: 'Example', surname: 'Test', password: 'Pa$$W0RD', middleName: 'Hako')
            expect(response.status).to eq(400)
            expect(error_message).to eq("Submission of unknown field: age")
          end
        end
      end
    end
  end

  describe 'GET /register' do
    describe 'HTTP_ACCEPT=application/json' do
      def json_registration_get
        get '/register', {}, { 'HTTP_ACCEPT' => 'application/json' }
      end

      describe 'json is enabled' do
        it 'respond with status 200' do
          json_registration_get
          expect(response.status).to eq(200)
        end

        it 'respond with content-type application/json' do
          json_registration_get
          expect(response.content_type.to_s).to eq('application/json')
        end

        xit 'should match schema' do
          json_registration_get
          expect(response).to match_response_schema(:register_response, strict: true)
        end

        it 'should match json' do
          json_registration_get
          expect(response).to match_json <<-JSON
          {
          	"form": {
          		"fields": [{
                "label": "First Name",
                "name": "givenName",
                "placeholder": "First Name",
                "required": true,
                "type": "text"
              },
              {
                "label": "Last Name",
                "name": "surname",
                "placeholder": "Last Name",
                "required": true,
                "type": "text"
              },
              {
                "label": "Email",
                "name": "email",
                "placeholder": "Email",
                "required": true,
                "type": "email"
              },
              {
                "label": "Password",
                "name": "password",
                "placeholder": "Password",
                "required": true,
                "type": "password"
              }]
          	},
          	"accountStores": []
          }
          JSON
        end

        xit 'register should show account stores' do
        end

        xit 'if id site enabled should redirect' do
          json_registration_get
          expect(response.status).to eq(400)
        end
      end

      describe 'json is disabled' do
        before do
          allow(Stormpath::Rails.config.web).to receive(:produces) { ['application/html'] }
          Rails.application.reload_routes!
        end

        it 'returns 404' do
          json_registration_get
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
