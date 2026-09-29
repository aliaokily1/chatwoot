/* global axios */
// Elkheta: WhatsApp-style message actions (react, forward, pin, star)
import ApiClient from './ApiClient';

class MessageActionsAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  messageUrl(conversationId, messageId, action) {
    return `${this.url}/${conversationId}/messages/${messageId}/${action}`;
  }

  react(conversationId, messageId, emoji) {
    return axios.post(this.messageUrl(conversationId, messageId, 'react'), {
      emoji,
    });
  }

  forward(conversationId, messageId, conversationIds) {
    return axios.post(this.messageUrl(conversationId, messageId, 'forward'), {
      conversation_ids: conversationIds,
    });
  }

  pin(conversationId, messageId) {
    return axios.post(this.messageUrl(conversationId, messageId, 'pin'));
  }

  unpin(conversationId, messageId) {
    return axios.delete(this.messageUrl(conversationId, messageId, 'pin'));
  }

  star(conversationId, messageId) {
    return axios.post(this.messageUrl(conversationId, messageId, 'star'));
  }

  unstar(conversationId, messageId) {
    return axios.delete(this.messageUrl(conversationId, messageId, 'star'));
  }

  starred(conversationId) {
    return axios.get(`${this.baseUrl()}/starred_messages`, {
      params: { conversation_id: conversationId },
    });
  }
}

export default new MessageActionsAPI();
