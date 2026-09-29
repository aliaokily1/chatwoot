<script setup>
// Elkheta: WhatsApp-style hover actions next to a bubble — quick reaction bar
// (👍 ❤️ 😂 😮 😢 🙏 +) and the message menu (⌄).
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { onClickOutside } from '@vueuse/core';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import WhatsAppEmojiPanel from 'dashboard/components-next/emoji-icon-picker/WhatsAppEmojiPanel.vue';

defineProps({
  currentReaction: { type: String, default: '' },
  alignEnd: { type: Boolean, default: false },
});
const emit = defineEmits(['react', 'openMenu']);
const { t } = useI18n();

const QUICK_REACTIONS = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

const rootRef = ref(null);
const showBar = ref(false);
const showPicker = ref(false);

const close = () => {
  showBar.value = false;
  showPicker.value = false;
};

onClickOutside(rootRef, close);

const choose = emoji => {
  emit('react', emoji);
  close();
};

// Exposed so the context menu's "React" item can open the bar
defineExpose({
  openBar: () => {
    showBar.value = true;
  },
});
</script>

<template>
  <div
    ref="rootRef"
    class="relative flex items-center gap-0.5 self-center transition-opacity"
    :class="
      showBar || showPicker
        ? 'opacity-100'
        : 'opacity-0 group-hover/msg:opacity-100 focus-within:opacity-100'
    "
  >
    <button
      type="button"
      class="grid place-content-center size-7 rounded-full border-0 bg-n-solid-1/90 text-n-slate-11 hover:text-n-slate-12 shadow-sm cursor-pointer"
      :title="t('CONVERSATION.REACTIONS.REACT')"
      @click="showBar = !showBar"
    >
      <Icon icon="i-ph-smiley" class="size-4" />
    </button>
    <button
      type="button"
      class="grid place-content-center size-7 rounded-full border-0 bg-n-solid-1/90 text-n-slate-11 hover:text-n-slate-12 shadow-sm cursor-pointer"
      :title="t('CONVERSATION.REACTIONS.MORE')"
      @click="emit('openMenu', $event)"
    >
      <Icon icon="i-ph-caret-down" class="size-4" />
    </button>

    <div
      v-if="showBar"
      class="absolute bottom-full mb-2 z-40 flex items-center gap-1 px-2 py-1.5 rounded-full bg-n-solid-1 border border-n-weak shadow-xl"
      :class="alignEnd ? 'end-0' : 'start-0'"
    >
      <button
        v-for="emoji in QUICK_REACTIONS"
        :key="emoji"
        type="button"
        class="grid place-content-center size-9 rounded-full border-0 cursor-pointer text-2xl leading-none hover:scale-125 transition-transform"
        :class="currentReaction === emoji ? 'bg-n-brand/15' : 'bg-transparent'"
        @click="choose(currentReaction === emoji ? '' : emoji)"
      >
        <span class="wa-emoji-text">{{ emoji }}</span>
      </button>
      <button
        type="button"
        class="grid place-content-center size-9 rounded-full border-0 bg-n-alpha-2 text-n-slate-11 cursor-pointer"
        :title="t('CONVERSATION.REACTIONS.MORE_EMOJI')"
        @click="showPicker = !showPicker"
      >
        <Icon icon="i-ph-plus" class="size-4" />
      </button>
      <WhatsAppEmojiPanel
        v-if="showPicker"
        emoji-only
        @select="choose($event.value)"
      />
    </div>
  </div>
</template>

<style scoped>
.wa-emoji-text {
  font-family: 'Noto Color Emoji', sans-serif;
}
</style>
