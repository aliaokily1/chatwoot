# Elkheta: a personal list of conversations (like WhatsApp "Lists"), owned by one agent.
# == Schema Information
#
# Table name: conversation_lists
#
#  id         :bigint           not null, primary key
#  kind       :integer          default("custom"), not null
#  name       :string           not null
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#  user_id    :bigint           not null
#
class ConversationList < ApplicationRecord
  belongs_to :account
  belongs_to :user
  has_many :conversation_list_items, dependent: :delete_all
  has_many :conversations, through: :conversation_list_items

  enum :kind, { custom: 0, favourites: 1 }

  validates :name, presence: true, length: { maximum: 40 }
  validates :name, uniqueness: { scope: [:account_id, :user_id] }

  FAVOURITES_NAME = 'Favourites'.freeze

  scope :ordered, -> { order(kind: :desc, position: :asc, id: :asc) }

  def self.favourites_for(account, user)
    find_or_create_by!(account: account, user: user, kind: :favourites) do |list|
      list.name = FAVOURITES_NAME
    end
  end
end
