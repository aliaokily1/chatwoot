/* global axios */
// Elkheta: personal WhatsApp-style chat lists (Favourites + custom lists)
import ApiClient from './ApiClient';

class ConversationListsAPI extends ApiClient {
  constructor() {
    super('conversation_lists', { accountScoped: true });
  }

  addConversation(listId, conversationId) {
    return axios.post(`${this.url}/${listId}/conversations/${conversationId}`);
  }

  removeConversation(listId, conversationId) {
    return axios.delete(`${this.url}/${listId}/conversations/${conversationId}`);
  }
}

export default new ConversationListsAPI();
