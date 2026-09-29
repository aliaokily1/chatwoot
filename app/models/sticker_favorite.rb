# Elkheta: a sticker an agent marked as favourite (personal).
# == Schema Information
#
# Table name: sticker_favorites
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sticker_id :bigint           not null
#  user_id    :bigint           not null
#
class StickerFavorite < ApplicationRecord
  belongs_to :sticker
  belongs_to :user

  validates :sticker_id, uniqueness: { scope: :user_id }
end
