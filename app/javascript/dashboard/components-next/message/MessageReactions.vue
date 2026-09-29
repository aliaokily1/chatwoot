<script setup>
// Elkheta: reactions shown under a bubble (student + our side), like WhatsApp.
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  reactions: { type: Object, default: () => ({}) },
});
const emit = defineEmits(['removeMine']);
const { t } = useI18n();

const items = computed(() =>
  [
    props.reactions?.contact?.emoji && {
      key: 'contact',
      emoji: props.reactions.contact.emoji,
      label: t('CONVERSATION.REACTIONS.FROM_CONTACT'),
    },
    props.reactions?.business?.emoji && {
      key: 'business',
      emoji: props.reactions.business.emoji,
      label: t('CONVERSATION.REACTIONS.FROM_US'),
    },
  ].filter(Boolean)
);
</script>

<template>
  <div
    v-if="items.length"
    class="flex items-center gap-0.5 px-1.5 h-6 rounded-full bg-n-solid-1 border border-n-weak shadow-sm"
  >
    <button
      v-for="item in items"
      :key="item.key"
      type="button"
      class="text-sm leading-none border-0 bg-transparent p-0"
      :class="item.key === 'business' ? 'cursor-pointer' : 'cursor-default'"
      :title="item.key === 'business' ? t('CONVERSATION.REACTIONS.REMOVE_MINE') : item.label"
      @click="item.key === 'business' && emit('removeMine')"
    >
      <span class="wa-emoji-text">{{ item.emoji }}</span>
    </button>
  </div>
</template>

<style scoped>
.wa-emoji-text {
  font-family: 'Noto Color Emoji', sans-serif;
}
</style>
