import types from 'dashboard/store/mutation-types';

// Elkheta: show a pin change on this screen right away
// (the server also broadcasts it to every other open screen).
export const applyPinnedIds = (store, conversationId, ids) => {
  const chat = store.getters.getConversationById(conversationId);
  if (!chat || !Array.isArray(ids)) return;
  store.commit(types.UPDATE_CONVERSATION, {
    ...chat,
    additional_attributes: {
      ...(chat.additional_attributes || {}),
      pinned_message_ids: ids,
    },
  });
};
