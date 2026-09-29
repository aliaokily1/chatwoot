<script setup>
// Elkheta: forward a message to up to 5 other chats (like WhatsApp).
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import Avatar from 'next/avatar/Avatar.vue';
import Icon from 'next/icon/Icon.vue';
import Button from 'next/button/Button.vue';
import MessageActionsAPI from 'dashboard/api/messageActions';

const props = defineProps({
  conversationId: { type: Number, required: true },
  messageId: { type: Number, required: true },
});
const emit = defineEmits(['close']);
const { t } = useI18n();

const MAX_TARGETS = 5;
const allConversations = useMapGetter('getAllConversations');
const search = ref('');
const selected = ref([]);
const isSending = ref(false);

const candidates = computed(() => {
  const term = search.value.trim().toLowerCase();
  return (allConversations.value || [])
    .filter(chat => chat.id !== props.conversationId)
    .filter(chat => {
      if (!term) return true;
      const sender = chat.meta?.sender || {};
      return (
        (sender.name || '').toLowerCase().includes(term) ||
        (sender.phone_number || '').includes(term)
      );
    })
    .slice(0, 60);
});

const toggle = id => {
  if (selected.value.includes(id)) {
    selected.value = selected.value.filter(x => x !== id);
  } else if (selected.value.length < MAX_TARGETS) {
    selected.value = [...selected.value, id];
  }
};

const send = async () => {
  if (!selected.value.length) return;
  isSending.value = true;
  try {
    await MessageActionsAPI.forward(
      props.conversationId,
      props.messageId,
      selected.value
    );
    useAlert(t('CONVERSATION.FORWARD.SUCCESS', { count: selected.value.length }));
    emit('close');
  } catch (error) {
    useAlert(error?.response?.data?.error || t('CONVERSATION.FORWARD.ERROR'));
  } finally {
    isSending.value = false;
  }
};
</script>

<template>
  <div
    class="fixed inset-0 z-[200] grid place-items-center bg-n-alpha-black1 backdrop-blur-sm p-4"
    @click.self="emit('close')"
  >
    <div
      class="w-full max-w-md max-h-[80vh] flex flex-col rounded-2xl bg-n-solid-1 border border-n-weak shadow-2xl overflow-hidden"
    >
      <div class="flex items-center justify-between px-5 py-3 border-b border-n-weak">
        <h3 class="text-base font-semibold text-n-slate-12 m-0">
          {{ t('CONVERSATION.FORWARD.TITLE') }}
        </h3>
        <Button icon="i-lucide-x" slate ghost sm @click="emit('close')" />
      </div>
      <div class="px-4 py-3">
        <label
          class="flex items-center gap-2 h-9 px-3 rounded-full border border-n-strong focus-within:border-n-brand"
        >
          <Icon icon="i-ph-magnifying-glass" class="size-4 text-n-slate-10" />
          <input
            v-model="search"
            type="text"
            class="!m-0 !p-0 !h-auto !border-0 !bg-transparent !shadow-none !outline-none flex-1 text-sm"
            :placeholder="t('CONVERSATION.FORWARD.SEARCH')"
          />
        </label>
      </div>
      <ul class="flex-1 overflow-y-auto px-2 pb-2 m-0 list-none">
        <li v-for="chat in candidates" :key="chat.id">
          <button
            type="button"
            class="w-full flex items-center gap-3 px-3 py-2 rounded-xl border-0 bg-transparent hover:bg-n-alpha-2 cursor-pointer text-start"
            @click="toggle(chat.id)"
          >
            <span
              class="grid place-content-center size-5 rounded-full border-2 flex-shrink-0"
              :class="selected.includes(chat.id) ? 'bg-n-brand border-n-brand text-white' : 'border-n-slate-7'"
            >
              <Icon v-if="selected.includes(chat.id)" icon="i-ph-check-bold" class="size-3" />
            </span>
            <Avatar
              :name="chat.meta?.sender?.name"
              :src="chat.meta?.sender?.thumbnail"
              :size="32"
            />
            <span class="flex flex-col min-w-0">
              <span class="text-sm font-medium text-n-slate-12 truncate">
                {{ chat.meta?.sender?.name }}
              </span>
              <span class="text-xs text-n-slate-10 truncate" dir="ltr">
                {{ chat.meta?.sender?.phone_number }}
              </span>
            </span>
          </button>
        </li>
        <li v-if="!candidates.length" class="py-8 text-center text-sm text-n-slate-10">
          {{ t('CONVERSATION.FORWARD.NO_CHATS') }}
        </li>
      </ul>
      <div class="flex items-center justify-between gap-3 px-5 py-3 border-t border-n-weak">
        <span class="text-xs text-n-slate-10">
          {{ t('CONVERSATION.FORWARD.SELECTED', { count: selected.length, max: MAX_TARGETS }) }}
        </span>
        <Button
          :label="t('CONVERSATION.FORWARD.SEND')"
          icon="i-ph-paper-plane-right-fill"
          sm
          :disabled="!selected.length"
          :is-loading="isSending"
          @click="send"
        />
      </div>
    </div>
  </div>
</template>
