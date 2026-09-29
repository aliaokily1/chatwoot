require 'rails_helper'

# Elkheta: each Admin (agent) sees only her own number's contacts; administrators see all and can filter by inbox.
RSpec.describe 'Contacts API scoping', type: :request do
  let(:account) { create(:account) }
  let(:dina_inbox) { create(:inbox, account: account) }
  let(:donia_inbox) { create(:inbox, account: account) }
  let(:dina) { create(:user, account: account, role: :agent) }
  let(:supervisor) { create(:user, account: account, role: :administrator) }
  let!(:dina_student) { create(:contact, account: account, name: 'Ahmed', phone_number: '+201000000001') }
  let!(:donia_student) { create(:contact, account: account, name: 'Nada', phone_number: '+201000000002') }

  before do
    create(:inbox_member, user: dina, inbox: dina_inbox)
    create(:contact_inbox, contact: dina_student, inbox: dina_inbox)
    create(:contact_inbox, contact: donia_student, inbox: donia_inbox)
  end

  def contact_ids(user, path = 'contacts', params = {})
    get "/api/v1/accounts/#{account.id}/#{path}", headers: user.create_new_auth_token, params: params, as: :json
    response.parsed_body['payload'].pluck('id')
  end

  it 'shows an Admin only her own contacts' do
    expect(contact_ids(dina)).to eq([dina_student.id])
    expect(contact_ids(dina, 'contacts/search', q: 'a')).to eq([dina_student.id])
  end

  it 'still finds any contact by its full phone number' do
    expect(contact_ids(dina, 'contacts/search', q: '201000000002')).to eq([donia_student.id])
  end

  it 'blocks opening another Admin\'s contact' do
    get "/api/v1/accounts/#{account.id}/contacts/#{donia_student.id}", headers: dina.create_new_auth_token, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it 'shows administrators every contact, filterable by inbox' do
    expect(contact_ids(supervisor)).to contain_exactly(dina_student.id, donia_student.id)
    expect(contact_ids(supervisor, 'contacts', inbox_id: donia_inbox.id)).to eq([donia_student.id])
  end
end
