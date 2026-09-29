json.array! @stickers do |sticker|
  json.partial! 'api/v1/accounts/stickers/sticker', sticker: sticker, favorite_ids: @favorite_ids
end
