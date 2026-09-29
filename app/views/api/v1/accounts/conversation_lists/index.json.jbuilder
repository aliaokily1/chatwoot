json.array! @conversation_lists do |conversation_list|
  json.partial! 'api/v1/accounts/conversation_lists/conversation_list', conversation_list: conversation_list
end
