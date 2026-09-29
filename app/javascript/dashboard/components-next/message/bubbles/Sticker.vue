<script setup>
// Elkheta: WhatsApp-style sticker — no bubble, transparent image, time below.
import { computed } from 'vue';
import MessageMeta from '../MessageMeta.vue';
import { useMessageContext } from '../provider.js';
import { ORIENTATION } from '../constants';

const { attachments, orientation } = useMessageContext();

const attachment = computed(() => attachments.value?.[0]);
const alignClass = computed(() =>
  orientation.value === ORIENTATION.RIGHT ? 'items-end' : 'items-start'
);
</script>

<template>
  <div class="flex flex-col gap-1" :class="alignClass" data-bubble-name="sticker">
    <img
      v-if="attachment?.dataUrl"
      :src="attachment.dataUrl"
      alt="sticker"
      class="skip-context-menu size-36 object-contain select-none drop-shadow-sm"
      draggable="false"
    />
    <MessageMeta
      class="px-2 py-0.5 rounded-full bg-n-wa-panel/80 text-n-slate-11 !text-[11px]"
    />
  </div>
</template>
