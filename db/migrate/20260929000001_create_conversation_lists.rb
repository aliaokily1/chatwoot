# Elkheta: personal WhatsApp-style chat lists (Favourites + custom lists) per agent.
class CreateConversationLists < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_lists do |t|
      t.references :account, null: false, index: true
      t.references :user, null: false, index: true
      t.string :name, null: false
      t.integer :kind, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :conversation_lists, [:account_id, :user_id, :name], unique: true

    create_table :conversation_list_items do |t|
      t.references :conversation_list, null: false, index: true
      t.references :conversation, null: false, index: true
      t.timestamps
    end
    add_index :conversation_list_items, [:conversation_list_id, :conversation_id], unique: true,
                                                                                    name: 'index_conversation_list_items_uniqueness'
  end
end
