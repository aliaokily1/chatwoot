# Elkheta: membership of a conversation in an agent's personal list.
# == Schema Information
#
# Table name: conversation_list_items
#
#  id                   :bigint           not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  conversation_id      :bigint           not null
#  conversation_list_id :bigint           not null
#
class ConversationListItem < ApplicationRecord
  belongs_to :conversation_list
  belongs_to :conversation

  validates :conversation_id, uniqueness: { scope: :conversation_list_id }
end
