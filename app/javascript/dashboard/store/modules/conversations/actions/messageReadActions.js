import { throwErrorMessage } from 'dashboard/store/utils/api';
import ConversationApi from '../../../../api/inbox/conversation';
import mutationTypes from '../../../mutation-types';

export default {
  markMessagesRead: async ({ commit }, data) => {
    try {
      // Elkheta: opening a chat doesn't clear "unread" — only a reply or resolve does,
      // so keep the server's unread_count instead of zeroing it.
      const {
        data: { id, agent_last_seen_at: lastSeen, unread_count: unreadCount },
      } = await ConversationApi.markMessageRead(data);
      setTimeout(
        () =>
          commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
            id,
            lastSeen,
            unreadCount,
          }),
        4000
      );
    } catch (error) {
      // Handle error
    }
  },

  markMessagesUnread: async ({ commit }, { id }) => {
    try {
      const {
        data: { agent_last_seen_at: lastSeen, unread_count: unreadCount },
      } = await ConversationApi.markMessagesUnread({ id });
      commit(mutationTypes.UPDATE_MESSAGE_UNREAD_COUNT, {
        id,
        lastSeen,
        unreadCount,
      });
    } catch (error) {
      throwErrorMessage(error);
    }
  },
};
