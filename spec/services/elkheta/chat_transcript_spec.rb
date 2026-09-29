require 'rails_helper'

describe Elkheta::ChatTranscript do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user, account: account, name: 'Dina') }
  let(:contact) { create(:contact, account: account, name: 'Ahmed') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }

  before do
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming,
                     sender: contact, content: 'I missed lesson 3', created_at: Time.zone.parse('2026-09-29 10:42'))
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :outgoing,
                     sender: agent, content: 'Watch it today', created_at: Time.zone.parse('2026-09-29 10:45'))
    create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :outgoing,
                     sender: agent, content: 'follow up tomorrow', private: true, created_at: Time.zone.parse('2026-09-29 10:46'))
  end

  it 'exports WhatsApp-style lines without internal notes' do
    expect(described_class.new(conversation, time_zone: 'UTC').lines).to eq(
      ['29/09/2026, 10:42 AM - Ahmed: I missed lesson 3', '29/09/2026, 10:45 AM - Dina: Watch it today']
    )
  end

  it 'labels roles and includes notes for the AI summary' do
    transcript = described_class.new(conversation, time_zone: 'UTC', include_notes: true, roles: true).to_s

    expect(transcript).to include('Student (Ahmed): I missed lesson 3')
    expect(transcript).to include('Admin (Dina): Watch it today')
    expect(transcript).to include('Internal note by Dina: follow up tomorrow')
  end
end
