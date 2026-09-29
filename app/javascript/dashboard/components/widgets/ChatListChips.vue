<script setup>
// Elkheta: WhatsApp-style filter chips above the chat list
// (All · Unread · Favourites · personal lists · +)
import { nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  activeChip: { type: [String, Number], default: 'all' },
  unreadCount: { type: Number, default: 0 },
  favouritesList: { type: Object, default: null },
  customLists: { type: Array, default: () => [] },
});

const emit = defineEmits(['change', 'createList', 'deleteList']);

const { t } = useI18n();
const isCreating = ref(false);
const newListName = ref('');
const nameInput = ref(null);

const chipClass = key =>
  props.activeChip === key
    ? 'bg-n-wa-accent/15 text-n-wa-accent'
    : 'bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3 hover:text-n-slate-12';

const startCreate = async () => {
  isCreating.value = true;
  await nextTick();
  nameInput.value?.focus();
};

const finishCreate = () => {
  const name = newListName.value.trim();
  if (name) emit('createList', name);
  newListName.value = '';
  isCreating.value = false;
};

const cancelCreate = () => {
  newListName.value = '';
  isCreating.value = false;
};

const confirmDelete = list => {
  // eslint-disable-next-line no-alert
  if (window.confirm(t('CHAT_LIST.CHIPS.DELETE_CONFIRM', { name: list.name }))) {
    emit('deleteList', list);
  }
};
</script>

<template>
  <div
    class="flex items-center gap-2 px-3 py-2 overflow-x-auto flex-shrink-0 [scrollbar-width:none]"
  >
    <button
      type="button"
      class="chip"
      :class="chipClass('all')"
      @click="emit('change', 'all')"
    >
      {{ t('CHAT_LIST.CHIPS.ALL') }}
    </button>
    <button
      type="button"
      class="chip"
      :class="chipClass('unread')"
      @click="emit('change', 'unread')"
    >
      {{ t('CHAT_LIST.CHIPS.UNREAD') }}
      <span v-if="unreadCount" class="text-xs opacity-80">
        {{ unreadCount }}
      </span>
    </button>
    <button
      v-if="favouritesList"
      type="button"
      class="chip"
      :class="chipClass(favouritesList.id)"
      @click="emit('change', favouritesList.id)"
    >
      {{ t('CHAT_LIST.CHIPS.FAVOURITES') }}
    </button>
    <button
      v-for="list in customLists"
      :key="list.id"
      type="button"
      class="chip"
      :class="chipClass(list.id)"
      @click="emit('change', list.id)"
    >
      {{ list.name }}
      <span
        v-if="activeChip === list.id"
        role="button"
        class="grid place-content-center rounded-full size-4 hover:bg-n-alpha-3"
        :title="t('CHAT_LIST.CHIPS.DELETE_LIST')"
        @click.stop="confirmDelete(list)"
      >
        <Icon icon="i-lucide-x" class="size-3" />
      </span>
    </button>
    <input
      v-if="isCreating"
      ref="nameInput"
      v-model="newListName"
      type="text"
      maxlength="40"
      class="!h-7 !w-32 !mb-0 !px-3 !py-0 !text-sm !rounded-full flex-shrink-0"
      :placeholder="t('CHAT_LIST.CHIPS.LIST_NAME')"
      @keydown.enter.prevent="finishCreate"
      @keydown.esc.prevent="cancelCreate"
      @blur="finishCreate"
    />
    <button
      v-else
      type="button"
      class="chip !px-2"
      :class="chipClass('__new__')"
      :title="t('CHAT_LIST.CHIPS.NEW_LIST')"
      @click="startCreate"
    >
      <Icon icon="i-lucide-plus" class="size-4" />
    </button>
  </div>
</template>

<style scoped>
.chip {
  @apply h-7 px-3 rounded-full text-sm font-medium whitespace-nowrap flex items-center gap-1.5 flex-shrink-0 border-0 cursor-pointer transition-colors;
}
</style>
