require 'rails_helper'

RSpec.describe Admin::VenuesController, type: :controller do
  let(:admin_user) { create(:user, role: 'super_admin') }

  before do
    sign_in admin_user
  end

  describe 'POST #quick_create' do
    context 'with valid params' do
      let(:valid_params) do
        { venue: { name: 'Test Venue', address: '123 Main St', capacity: 100 } }
      end

      it 'creates a venue and returns JSON' do
        post :quick_create, params: valid_params, format: :json
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('Test Venue')
        expect(json['id']).to be_present
      end

      it 'creates a venue in the database' do
        expect {
          post :quick_create, params: valid_params, format: :json
        }.to change(Venue, :count).by(1)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        { venue: { name: '', address: '', capacity: nil } }
      end

      it 'returns errors as JSON' do
        post :quick_create, params: invalid_params, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end

      it 'does not create a venue' do
        expect {
          post :quick_create, params: invalid_params, format: :json
        }.not_to change(Venue, :count)
      end
    end
  end
end
