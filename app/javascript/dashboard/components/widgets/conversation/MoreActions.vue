<script setup>
import { computed, onUnmounted } from 'vue';
import { useToggle } from '@vueuse/core';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { emitter } from 'shared/helpers/mitt';
import EmailTranscriptModal from './EmailTranscriptModal.vue';
import ChatSummaryModal from './ChatSummaryModal.vue';
import ChatToolsAPI from 'dashboard/api/chatTools';
import ResolveAction from '../../buttons/ResolveAction.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

import {
  CMD_MUTE_CONVERSATION,
  CMD_SEND_TRANSCRIPT,
  CMD_UNMUTE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

// No props needed as we're getting currentChat from the store directly
const store = useStore();
const { t } = useI18n();

const [showEmailActionsModal, toggleEmailModal] = useToggle(false);
const [showActionsDropdown, toggleDropdown] = useToggle(false);
const [showSummaryModal, toggleSummaryModal] = useToggle(false);

const currentChat = computed(() => store.getters.getSelectedChat);

const actionMenuItems = computed(() => {
  // Elkheta: AI summary and WhatsApp-style chat export first
  const items = [
    {
      icon: 'i-ph-sparkle',
      label: t('CONVERSATION.CHAT_TOOLS.SUMMARIZE'),
      action: 'summarize',
      value: 'summarize',
    },
    {
      icon: 'i-ph-export',
      label: t('CONVERSATION.CHAT_TOOLS.EXPORT'),
      action: 'export',
      value: 'export',
    },
  ];

  if (!currentChat.value.muted) {
    items.push({
      icon: 'i-lucide-volume-off',
      label: t('CONTACT_PANEL.MUTE_CONTACT'),
      action: 'mute',
      value: 'mute',
    });
  } else {
    items.push({
      icon: 'i-lucide-volume-1',
      label: t('CONTACT_PANEL.UNMUTE_CONTACT'),
      action: 'unmute',
      value: 'unmute',
    });
  }

  items.push({
    icon: 'i-lucide-share',
    label: t('CONTACT_PANEL.SEND_TRANSCRIPT'),
    action: 'send_transcript',
    value: 'send_transcript',
  });

  return items;
});

// Elkheta: download the whole chat as a WhatsApp-style .txt file
const exportChat = async () => {
  try {
    const { data } = await ChatToolsAPI.exportChat(currentChat.value.id);
    const name = currentChat.value.meta?.sender?.name || currentChat.value.id;
    const link = document.createElement('a');
    link.href = URL.createObjectURL(data);
    link.download = `Elkheta chat - ${name}.txt`;
    link.click();
    setTimeout(() => URL.revokeObjectURL(link.href), 1000);
  } catch {
    useAlert(t('CONVERSATION.CHAT_TOOLS.EXPORT_ERROR'));
  }
};

const handleActionClick = ({ action }) => {
  toggleDropdown(false);

  if (action === 'summarize') toggleSummaryModal(true);
  if (action === 'export') exportChat();

  if (action === 'mute') {
    store.dispatch('muteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
  } else if (action === 'unmute') {
    store.dispatch('unmuteConversation', currentChat.value.id);
    useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
  } else if (action === 'send_transcript') {
    toggleEmailModal();
  }
};

// These functions are needed for the event listeners
const mute = () => {
  store.dispatch('muteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.MUTED_SUCCESS'));
};

const unmute = () => {
  store.dispatch('unmuteConversation', currentChat.value.id);
  useAlert(t('CONTACT_PANEL.UNMUTED_SUCCESS'));
};

emitter.on(CMD_MUTE_CONVERSATION, mute);
emitter.on(CMD_UNMUTE_CONVERSATION, unmute);
emitter.on(CMD_SEND_TRANSCRIPT, toggleEmailModal);

onUnmounted(() => {
  emitter.off(CMD_MUTE_CONVERSATION, mute);
  emitter.off(CMD_UNMUTE_CONVERSATION, unmute);
  emitter.off(CMD_SEND_TRANSCRIPT, toggleEmailModal);
});
</script>

<template>
  <div class="relative flex items-center gap-2 actions--container">
    <ResolveAction
      :conversation-id="currentChat.id"
      :status="currentChat.status"
    />
    <div
      v-on-clickaway="() => toggleDropdown(false)"
      class="relative flex items-center group"
    >
      <ButtonV4
        v-tooltip="$t('CONVERSATION.HEADER.MORE_ACTIONS')"
        size="sm"
        variant="ghost"
        color="slate"
        icon="i-lucide-more-vertical"
        class="rounded-md group-hover:bg-n-alpha-2"
        @click="toggleDropdown()"
      />
      <DropdownMenu
        v-if="showActionsDropdown"
        :menu-items="actionMenuItems"
        class="mt-1 ltr:right-0 rtl:left-0 top-full"
        @action="handleActionClick"
      />
    </div>
    <Teleport to="body">
      <ChatSummaryModal
        v-if="showSummaryModal"
        :conversation-id="currentChat.id"
        :contact-name="currentChat.meta?.sender?.name"
        @close="toggleSummaryModal(false)"
      />
    </Teleport>
    <EmailTranscriptModal
      v-if="showEmailActionsModal"
      :show="showEmailActionsModal"
      :current-chat="currentChat"
      @cancel="toggleEmailModal"
    />
  </div>
</template>
