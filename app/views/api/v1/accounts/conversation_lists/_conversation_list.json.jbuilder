json.id conversation_list.id
json.name conversation_list.name
json.kind conversation_list.kind
json.position conversation_list.position
# Conversation ids as used by the dashboard (display_id)
json.conversation_ids conversation_list.conversations.pluck(:display_id)
