/* global axios */
// Elkheta: chat ⋮ menu tools — Export chat and Summarize with AI
import ApiClient from './ApiClient';

const timeZone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;

class ChatToolsAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  exportChat(conversationId) {
    return axios.get(`${this.url}/${conversationId}/chat_export`, {
      params: { time_zone: timeZone() },
      responseType: 'blob',
    });
  }

  summarize(conversationId, locale) {
    return axios.post(`${this.url}/${conversationId}/chat_summary`, {
      locale,
      time_zone: timeZone(),
    });
  }
}

export default new ChatToolsAPI();
