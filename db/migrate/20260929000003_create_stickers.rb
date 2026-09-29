# Elkheta: account-wide WhatsApp sticker library (+ personal favourites)
class CreateStickers < ActiveRecord::Migration[7.1]
  def change
    create_table :stickers do |t|
      t.references :account, null: false, index: true
      t.references :user, null: true, index: true
      t.string :name
      t.integer :source, null: false, default: 0
      t.string :checksum, null: false
      t.integer :uses_count, null: false, default: 0
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :stickers, [:account_id, :checksum], unique: true

    create_table :sticker_favorites do |t|
      t.references :sticker, null: false, index: true
      t.references :user, null: false, index: true
      t.timestamps
    end
    add_index :sticker_favorites, [:sticker_id, :user_id], unique: true
  end
end
