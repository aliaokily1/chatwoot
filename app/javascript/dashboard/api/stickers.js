/* global axios */
// Elkheta: WhatsApp sticker library
import ApiClient from './ApiClient';

class StickersAPI extends ApiClient {
  constructor() {
    super('stickers', { accountScoped: true });
  }

  upload(file, name = '') {
    const formData = new FormData();
    formData.append('image', file, file.name || 'sticker.webp');
    if (name) formData.append('name', name);
    return axios.post(this.url, formData);
  }

  favorite(id) {
    return axios.post(`${this.url}/${id}/favorite`);
  }

  unfavorite(id) {
    return axios.delete(`${this.url}/${id}/favorite`);
  }

  sendToConversation(conversationId, stickerId) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/stickers/${stickerId}`
    );
  }
}

export default new StickersAPI();
