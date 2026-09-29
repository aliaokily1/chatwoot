// Elkheta: the current agent's starred messages, cached per conversation.
import { reactive } from 'vue';
import MessageActionsAPI from 'dashboard/api/messageActions';

const byConversation = reactive({}); // { [conversationId]: number[] }
const loading = new Set();

export function useStarredMessages() {
  const ensureLoaded = async conversationId => {
    if (!conversationId || byConversation[conversationId] || loading.has(conversationId)) {
      return;
    }
    loading.add(conversationId);
    try {
      const { data } = await MessageActionsAPI.starred(conversationId);
      byConversation[conversationId] = data.map(item => item.message_id);
    } catch {
      byConversation[conversationId] = [];
    } finally {
      loading.delete(conversationId);
    }
  };

  const isStarred = (conversationId, messageId) =>
    (byConversation[conversationId] || []).includes(messageId);

  const toggleStar = async (conversationId, messageId) => {
    const starred = isStarred(conversationId, messageId);
    const current = byConversation[conversationId] || [];
    byConversation[conversationId] = starred
      ? current.filter(id => id !== messageId)
      : [...current, messageId];
    try {
      await (starred
        ? MessageActionsAPI.unstar(conversationId, messageId)
        : MessageActionsAPI.star(conversationId, messageId));
    } catch (error) {
      byConversation[conversationId] = current;
      throw error;
    }
    return !starred;
  };

  return { ensureLoaded, isStarred, toggleStar };
}
