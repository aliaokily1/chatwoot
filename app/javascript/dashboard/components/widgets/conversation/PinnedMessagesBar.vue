<script setup>
// Elkheta: pinned messages at the top of the chat (CRM only — WhatsApp's API has no pin).
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import MessageActionsAPI from 'dashboard/api/messageActions';
import { useStore } from 'vuex';
import { applyPinnedIds } from 'dashboard/helper/elkhetaPins';

const props = defineProps({
  chat: { type: Object, required: true },
});
const { t } = useI18n();
const store = useStore();

const index = ref(0);
const pinnedIds = computed(() =>
  (props.chat?.additional_attributes?.pinned_message_ids || []).map(Number)
);
const current = computed(() => {
  if (!pinnedIds.value.length) return null;
  const id = pinnedIds.value[index.value % pinnedIds.value.length];
  const message = (props.chat.messages || []).find(m => m.id === id);
  return { id, message };
});

const preview = computed(() => {
  const message = current.value?.message;
  if (!message) return t('CONVERSATION.MESSAGE_ACTIONS.PINNED_MESSAGE');
  if (message.content) return message.content;
  const type = message.attachments?.[0]?.file_type;
  return type ? t(`CHAT_LIST.ATTACHMENTS.${type}.CONTENT`) : t('CONVERSATION.MESSAGE_ACTIONS.PINNED_MESSAGE');
});

const jump = () => {
  if (!current.value) return;
  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId: current.value.id });
  index.value += 1; // next click shows the next pin, like WhatsApp
};

const unpin = async () => {
  if (!current.value) return;
  try {
    const { data } = await MessageActionsAPI.unpin(
      props.chat.id,
      current.value.id
    );
    applyPinnedIds(store, props.chat.id, data?.pinned_message_ids);
  } catch {
    useAlert(t('CONVERSATION.MESSAGE_ACTIONS.PIN_ERROR'));
  }
};
</script>

<template>
  <div
    v-if="current"
    class="flex items-center gap-3 px-4 py-2 bg-n-solid-1 border-b border-n-weak"
  >
    <div class="flex flex-col gap-0.5 self-stretch py-0.5">
      <span
        v-for="(pinId, i) in pinnedIds"
        :key="pinId"
        class="w-0.5 flex-1 rounded-full"
        :class="i === index % pinnedIds.length ? 'bg-n-brand' : 'bg-n-slate-6'"
      />
    </div>
    <button
      type="button"
      class="flex-1 min-w-0 flex items-center gap-2 border-0 bg-transparent p-0 cursor-pointer text-start"
      @click="jump"
    >
      <Icon icon="i-ph-push-pin-fill" class="size-4 text-n-slate-10 flex-shrink-0" />
      <span class="text-sm text-n-slate-12 truncate" dir="auto">{{ preview }}</span>
    </button>
    <button
      type="button"
      class="grid place-content-center size-7 rounded-full border-0 bg-transparent text-n-slate-10 hover:text-n-slate-12 cursor-pointer"
      :title="t('CONVERSATION.MESSAGE_ACTIONS.UNPIN')"
      @click="unpin"
    >
      <Icon icon="i-ph-push-pin-slash" class="size-4" />
    </button>
  </div>
</template>
