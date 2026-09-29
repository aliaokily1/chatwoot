# Elkheta: messages an agent starred (personal, like WhatsApp "Starred messages")
class CreateMessageStars < ActiveRecord::Migration[7.1]
  def change
    create_table :message_stars do |t|
      t.references :account, null: false, index: true
      t.references :user, null: false, index: true
      t.references :conversation, null: false, index: true
      t.references :message, null: false, index: true
      t.timestamps
    end
    add_index :message_stars, [:message_id, :user_id], unique: true
  end
end
