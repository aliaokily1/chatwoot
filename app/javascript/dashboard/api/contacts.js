/* global axios */
import ApiClient from './ApiClient';

// Elkheta: inboxId narrows the list to one Admin's number (Supervisors/Managers)
export const buildContactParams = (page, sortAttr, label, search, inboxId) => {
  let params = `include_contact_inboxes=false&page=${page}&sort=${sortAttr}`;
  if (inboxId) {
    params = `${params}&inbox_id=${inboxId}`;
  }
  if (search) {
    params = `${params}&q=${search}`;
  }
  if (label) {
    params = `${params}&labels[]=${label}`;
  }
  return params;
};

class ContactAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  get(page, sortAttr = 'name', label = '', inboxId = null) {
    let requestURL = `${this.url}?${buildContactParams(
      page,
      sortAttr,
      label,
      '',
      inboxId
    )}`;
    return axios.get(requestURL);
  }

  show(id) {
    return axios.get(`${this.url}/${id}?include_contact_inboxes=false`);
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}?include_contact_inboxes=false`, data);
  }

  getConversations(contactId, { inboxId } = {}) {
    const params = inboxId ? { inbox_id: inboxId } : {};
    return axios.get(`${this.url}/${contactId}/conversations`, { params });
  }

  getAttachments(contactId, page = 1) {
    return axios.get(`${this.url}/${contactId}/attachments`, {
      params: { page },
    });
  }

  getContactableInboxes(contactId) {
    return axios.get(`${this.url}/${contactId}/contactable_inboxes`);
  }

  getContactLabels(contactId) {
    return axios.get(`${this.url}/${contactId}/labels`);
  }

  initiateCall(contactId, inboxId, conversationId = null) {
    return axios.post(`${this.url}/${contactId}/call`, {
      inbox_id: inboxId,
      conversation_id: conversationId,
    });
  }

  updateContactLabels(contactId, labels) {
    return axios.post(`${this.url}/${contactId}/labels`, { labels });
  }

  search(search = '', page = 1, sortAttr = 'name', label = '', options = {}) {
    let requestURL = `${this.url}/search?${buildContactParams(
      page,
      sortAttr,
      label,
      search,
      options.inboxId
    )}`;
    return axios.get(requestURL, { signal: options.signal });
  }

  active(page = 1, sortAttr = 'name', inboxId = null) {
    let requestURL = `${this.url}/active?${buildContactParams(page, sortAttr, '', '', inboxId)}`;
    return axios.get(requestURL);
  }

  // eslint-disable-next-line default-param-last
  filter(page = 1, sortAttr = 'name', queryPayload, inboxId = null) {
    let requestURL = `${this.url}/filter?${buildContactParams(page, sortAttr, '', '', inboxId)}`;
    return axios.post(requestURL, queryPayload);
  }

  importContacts(file) {
    const formData = new FormData();
    formData.append('import_file', file);
    return axios.post(`${this.url}/import`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  destroyCustomAttributes(contactId, customAttributes) {
    return axios.post(`${this.url}/${contactId}/destroy_custom_attributes`, {
      custom_attributes: customAttributes,
    });
  }

  destroyAvatar(contactId) {
    return axios.delete(`${this.url}/${contactId}/avatar`);
  }

  exportContacts(queryPayload) {
    return axios.post(`${this.url}/export`, queryPayload);
  }
}

export default new ContactAPI();
