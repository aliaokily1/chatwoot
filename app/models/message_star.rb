# Elkheta: a message starred by one agent.
# == Schema Information
#
# Table name: message_stars
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  message_id      :bigint           not null
#  user_id         :bigint           not null
#
class MessageStar < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :conversation
  belongs_to :message

  validates :message_id, uniqueness: { scope: :user_id }
end
