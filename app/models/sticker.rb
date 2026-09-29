# Elkheta: a WhatsApp sticker in the account's shared library.
# Stickers are uploaded/created by agents, or collected automatically from
# stickers students send (and stickers sent from the Admin's phone via Coexistence).
# == Schema Information
#
# Table name: stickers
#
#  id           :bigint           not null, primary key
#  checksum     :string           not null
#  last_used_at :datetime
#  name         :string
#  source       :integer          default("uploaded"), not null
#  uses_count   :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  user_id      :bigint
#
class Sticker < ApplicationRecord
  MAX_BYTES = 500.kilobytes

  belongs_to :account
  belongs_to :user, optional: true
  has_many :sticker_favorites, dependent: :delete_all
  has_one_attached :image

  enum :source, { uploaded: 0, received: 1, echo: 2 }

  validates :checksum, presence: true, uniqueness: { scope: :account_id }
  validates :name, length: { maximum: 60 }

  scope :library_order, -> { order(Arel.sql('last_used_at DESC NULLS LAST, created_at DESC')) }

  # Stores a copy of the given blob (so deleting the original message never removes the sticker).
  def self.collect_from_blob!(account:, blob:, source:, user: nil, name: nil)
    return if blob.blank? || blob.byte_size > MAX_BYTES

    existing = find_by(account: account, checksum: blob.checksum)
    return existing if existing

    sticker = new(account: account, user: user, name: name, source: source, checksum: blob.checksum)
    sticker.image.attach(io: StringIO.new(blob.download), filename: blob.filename.to_s, content_type: blob.content_type)
    sticker.save!
    sticker
  rescue ActiveRecord::RecordNotUnique
    find_by(account: account, checksum: blob.checksum)
  end

  def mark_used!
    update_columns(uses_count: uses_count + 1, last_used_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
