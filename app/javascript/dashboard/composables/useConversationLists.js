// Elkheta: the current agent's personal chat lists (Favourites + custom lists),
// shared by the chat list chips and the conversation context menu.
import { computed, ref } from 'vue';
import ConversationListsAPI from 'dashboard/api/conversationLists';

const lists = ref([]);
let loadingPromise = null;

const replaceList = updated => {
  lists.value = lists.value.map(list =>
    list.id === updated.id ? updated : list
  );
};

export function useConversationLists() {
  const favourites = computed(() =>
    lists.value.find(list => list.kind === 'favourites')
  );
  const customLists = computed(() =>
    lists.value.filter(list => list.kind === 'custom')
  );

  const fetchLists = async ({ force = false } = {}) => {
    if (loadingPromise && !force) return loadingPromise;
    loadingPromise = ConversationListsAPI.get()
      .then(({ data }) => {
        lists.value = data;
      })
      .catch(() => {
        loadingPromise = null;
      });
    return loadingPromise;
  };

  const findList = listId => lists.value.find(list => list.id === listId);

  const isInList = (listId, conversationId) =>
    !!findList(listId)?.conversation_ids?.includes(conversationId);

  const createList = async name => {
    const { data } = await ConversationListsAPI.create({ name });
    lists.value = [...lists.value, data];
    return data;
  };

  const deleteList = async listId => {
    await ConversationListsAPI.delete(listId);
    lists.value = lists.value.filter(list => list.id !== listId);
  };

  const toggleConversation = async (listId, conversationId) => {
    const request = isInList(listId, conversationId)
      ? ConversationListsAPI.removeConversation(listId, conversationId)
      : ConversationListsAPI.addConversation(listId, conversationId);
    const { data } = await request;
    replaceList(data);
    return data;
  };

  return {
    lists,
    favourites,
    customLists,
    fetchLists,
    findList,
    isInList,
    createList,
    deleteList,
    toggleConversation,
  };
}
