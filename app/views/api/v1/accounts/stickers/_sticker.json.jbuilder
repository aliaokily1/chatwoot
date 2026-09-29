json.id sticker.id
json.name sticker.name
json.source sticker.source
json.user_id sticker.user_id
json.uses_count sticker.uses_count
json.favorite favorite_ids.include?(sticker.id)
json.url sticker.image.attached? ? rails_blob_path(sticker.image, only_path: true) : nil
