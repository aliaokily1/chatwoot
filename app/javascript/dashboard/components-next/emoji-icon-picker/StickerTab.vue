<script setup>
// Elkheta: WhatsApp-style sticker tab — Recent · Favourites · All, search,
// "Create" tile, favourite/delete on hover, click to send.
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import StickersAPI from 'dashboard/api/stickers';
import StickerCreator from './StickerCreator.vue';

const emit = defineEmits(['send', 'busy']);
const { t } = useI18n();

const RECENT_KEY = 'elkheta.recentStickers';
const MAX_RECENT = 24;

const stickers = ref([]);
const isLoading = ref(true);
const view = ref('all'); // recent | favourites | all
const search = ref('');
const showCreator = ref(false);
// Tell the panel to stay open while the sticker maker is on screen
watch(showCreator, value => emit('busy', value));

const readRecent = () => {
  try {
    return JSON.parse(localStorage.getItem(RECENT_KEY) || '[]');
  } catch {
    return [];
  }
};
const recentIds = ref(readRecent());

const load = async () => {
  isLoading.value = true;
  try {
    const { data } = await StickersAPI.get();
    stickers.value = data;
    if (recentIds.value.length) view.value = 'recent';
  } catch {
    useAlert(t('CONVERSATION.STICKERS.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(load);

const visibleStickers = computed(() => {
  let list = stickers.value;
  if (view.value === 'favourites') list = list.filter(s => s.favorite);
  if (view.value === 'recent') {
    const byId = new Map(list.map(s => [s.id, s]));
    list = recentIds.value.map(id => byId.get(id)).filter(Boolean);
  }
  const term = search.value.trim().toLowerCase();
  if (term) list = list.filter(s => (s.name || '').toLowerCase().includes(term));
  return list;
});

const rememberRecent = id => {
  recentIds.value = [id, ...recentIds.value.filter(x => x !== id)].slice(0, MAX_RECENT);
  try {
    localStorage.setItem(RECENT_KEY, JSON.stringify(recentIds.value));
  } catch {
    /* best effort */
  }
};

const sendSticker = sticker => {
  rememberRecent(sticker.id);
  emit('send', sticker);
};

const toggleFavorite = async sticker => {
  const next = !sticker.favorite;
  sticker.favorite = next;
  try {
    await (next ? StickersAPI.favorite(sticker.id) : StickersAPI.unfavorite(sticker.id));
  } catch {
    sticker.favorite = !next;
  }
};

const removeSticker = async sticker => {
  // eslint-disable-next-line no-alert
  if (!window.confirm(t('CONVERSATION.STICKERS.DELETE_CONFIRM'))) return;
  try {
    await StickersAPI.delete(sticker.id);
    stickers.value = stickers.value.filter(s => s.id !== sticker.id);
  } catch (error) {
    useAlert(
      error?.response?.status === 403
        ? t('CONVERSATION.STICKERS.DELETE_FORBIDDEN')
        : t('CONVERSATION.STICKERS.DELETE_ERROR')
    );
  }
};

const onCreated = sticker => {
  showCreator.value = false;
  stickers.value = [sticker, ...stickers.value.filter(s => s.id !== sticker.id)];
  view.value = 'all';
  useAlert(t('CONVERSATION.STICKERS.CREATED'));
};

const views = [
  { id: 'recent', icon: 'i-ph-clock-counter-clockwise' },
  { id: 'favourites', icon: 'i-ph-star' },
  { id: 'all', icon: 'i-ph-sticker' },
];
</script>

<template>
  <div class="flex flex-col flex-1 min-h-0">
    <div class="flex items-center gap-1 px-3 pt-2">
      <button
        v-for="item in views"
        :key="item.id"
        type="button"
        :title="t(`CONVERSATION.STICKERS.VIEWS.${item.id.toUpperCase()}`)"
        class="relative grid place-content-center size-9 rounded-lg border-0 bg-transparent cursor-pointer"
        :class="view === item.id ? 'text-n-slate-12' : 'text-n-slate-10 hover:text-n-slate-12'"
        @click="view = item.id"
      >
        <Icon :icon="item.icon" class="size-5" />
        <span
          v-if="view === item.id"
          class="absolute -bottom-0.5 inset-x-2 h-0.5 rounded-full bg-n-brand"
        />
      </button>
    </div>
    <div class="px-3 py-2">
      <label
        class="flex items-center gap-2 h-9 px-3 rounded-full border border-n-strong focus-within:border-n-brand bg-n-surface-1"
      >
        <Icon icon="i-ph-magnifying-glass" class="size-4 text-n-slate-10" />
        <input
          v-model="search"
          type="text"
          class="!m-0 !p-0 !h-auto !border-0 !bg-transparent !shadow-none !outline-none flex-1 text-sm"
          :placeholder="t('CONVERSATION.STICKERS.SEARCH')"
        />
      </label>
    </div>
    <div class="flex-1 overflow-y-auto px-3 pb-2">
      <div class="grid grid-cols-4 gap-2">
        <button
          v-if="view === 'all' && !search"
          type="button"
          class="aspect-square rounded-xl border border-dashed border-n-strong bg-n-alpha-1 grid place-content-center gap-1 text-n-slate-11 hover:text-n-slate-12 hover:border-n-brand cursor-pointer"
          @click="showCreator = true"
        >
          <Icon icon="i-ph-plus" class="size-6 mx-auto" />
          <span class="text-xs">{{ t('CONVERSATION.STICKERS.CREATE') }}</span>
        </button>
        <div
          v-for="sticker in visibleStickers"
          :key="sticker.id"
          class="group relative aspect-square rounded-xl hover:bg-n-alpha-2"
        >
          <button
            type="button"
            class="size-full grid place-content-center border-0 bg-transparent cursor-pointer p-1.5"
            :title="sticker.name || ''"
            @click="sendSticker(sticker)"
          >
            <img
              :src="sticker.url"
              :alt="sticker.name || 'sticker'"
              loading="lazy"
              class="max-w-full max-h-full object-contain select-none"
              draggable="false"
            />
          </button>
          <button
            type="button"
            class="absolute top-1 end-1 size-6 rounded-full grid place-content-center border-0 bg-n-solid-1/90 cursor-pointer"
            :class="sticker.favorite ? 'text-amber-500' : 'text-n-slate-10 opacity-0 group-hover:opacity-100'"
            :title="t('CONVERSATION.STICKERS.FAVOURITE')"
            @click.stop="toggleFavorite(sticker)"
          >
            <Icon :icon="sticker.favorite ? 'i-ph-star-fill' : 'i-ph-star'" class="size-3.5" />
          </button>
          <button
            type="button"
            class="absolute top-1 start-1 size-6 rounded-full grid place-content-center border-0 bg-n-solid-1/90 text-n-slate-10 hover:text-n-ruby-9 opacity-0 group-hover:opacity-100 cursor-pointer"
            :title="t('CONVERSATION.STICKERS.DELETE')"
            @click.stop="removeSticker(sticker)"
          >
            <Icon icon="i-ph-trash" class="size-3.5" />
          </button>
        </div>
      </div>
      <p
        v-if="!isLoading && !visibleStickers.length && (view !== 'all' || search)"
        class="py-8 text-center text-sm text-n-slate-10"
      >
        {{
          view === 'favourites'
            ? t('CONVERSATION.STICKERS.EMPTY_FAVOURITES')
            : view === 'recent'
              ? t('CONVERSATION.STICKERS.EMPTY_RECENT')
              : t('CONVERSATION.STICKERS.NO_RESULTS')
        }}
      </p>
      <p
        v-if="!isLoading && !stickers.length && view === 'all' && !search"
        class="pt-3 text-center text-xs text-n-slate-10"
      >
        {{ t('CONVERSATION.STICKERS.EMPTY_LIBRARY') }}
      </p>
    </div>
    <Teleport to="body">
      <StickerCreator
        v-if="showCreator"
        @close="showCreator = false"
        @created="onCreated"
      />
    </Teleport>
  </div>
</template>
