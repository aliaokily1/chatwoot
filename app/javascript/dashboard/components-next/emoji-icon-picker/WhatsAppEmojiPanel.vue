<script setup>
// Elkheta: WhatsApp-style emoji panel — opens above the composer, category tabs,
// search, Google Noto Color Emoji (same look as in messages),
// and bottom tabs for Emoji / GIF / Stickers.
import { computed, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import StickerTab from './StickerTab.vue';
import emojiGroups from 'shared/components/emoji/emojisGroup.json';
import {
  addRecentEmoji,
  getRecentEmojis,
} from 'shared/components/emoji/pickerHelper';

defineProps({
  // Elkheta: reaction picker uses emojis only (no GIF / sticker tabs)
  emojiOnly: { type: Boolean, default: false },
});
const emit = defineEmits(['select', 'sendSticker', 'busy']);

const { t } = useI18n();

const CATEGORY_META = {
  'Smileys & Emotion': { key: 'SMILEYS', icon: 'i-ph-smiley' },
  'People & Body': { key: 'PEOPLE', icon: 'i-ph-hand-waving' },
  'Animals & Nature': { key: 'ANIMALS', icon: 'i-ph-dog' },
  'Food & Drink': { key: 'FOOD', icon: 'i-ph-coffee' },
  'Travel & Places': { key: 'TRAVEL', icon: 'i-ph-car' },
  Activities: { key: 'ACTIVITIES', icon: 'i-ph-soccer-ball' },
  Objects: { key: 'OBJECTS', icon: 'i-ph-lightbulb' },
  Symbols: { key: 'SYMBOLS', icon: 'i-ph-hash' },
  Flags: { key: 'FLAGS', icon: 'i-ph-flag' },
};

const RECENT_ID = '__recent__';
const activeBottomTab = ref('emoji');
const search = ref('');
const recentEmojis = ref(getRecentEmojis());
const scrollRef = ref(null);
const activeCategory = ref(
  recentEmojis.value.length ? RECENT_ID : emojiGroups[0].name
);

const categoryLabel = name =>
  name === RECENT_ID
    ? t('CONVERSATION.EMOJI_PANEL.RECENT')
    : t(`CONVERSATION.EMOJI_PANEL.CATEGORIES.${CATEGORY_META[name].key}`);

const tabs = computed(() => [
  { id: RECENT_ID, icon: 'i-ph-clock-counter-clockwise' },
  ...emojiGroups.map(group => ({
    id: group.name,
    icon: CATEGORY_META[group.name]?.icon || 'i-ph-smiley',
  })),
]);

const sections = computed(() => {
  const term = search.value.trim().toLowerCase();
  if (term) {
    const matches = emojiGroups.flatMap(group =>
      group.emojis.filter(
        emoji =>
          emoji.name.toLowerCase().includes(term) ||
          emoji.slug.replaceAll('_', ' ').includes(term)
      )
    );
    return [{ id: 'search', title: '', emojis: matches }];
  }
  const recent = recentEmojis.value.length
    ? [
        {
          id: RECENT_ID,
          title: categoryLabel(RECENT_ID),
          emojis: recentEmojis.value,
        },
      ]
    : [];
  return [
    ...recent,
    ...emojiGroups.map(group => ({
      id: group.name,
      title: categoryLabel(group.name),
      emojis: group.emojis,
    })),
  ];
});

const selectEmoji = emoji => {
  recentEmojis.value = addRecentEmoji(emoji);
  emit('select', { value: emoji.emoji });
};

const scrollToCategory = async id => {
  search.value = '';
  activeCategory.value = id;
  await nextTick();
  const target = scrollRef.value?.querySelector(`[data-section="${id}"]`);
  if (target) scrollRef.value.scrollTo({ top: target.offsetTop - 4 });
};

const onScroll = () => {
  const container = scrollRef.value;
  if (!container || search.value) return;
  const headings = container.querySelectorAll('[data-section]');
  let current = activeCategory.value;
  headings.forEach(heading => {
    if (heading.offsetTop - container.scrollTop <= 24) {
      current = heading.dataset.section;
    }
  });
  activeCategory.value = current;
};
</script>

<template>
  <div
    class="wa-emoji-panel absolute bottom-full mb-2 start-0 z-50 flex flex-col w-[26rem] max-w-[calc(100vw-2rem)] h-[22rem] rounded-2xl bg-n-solid-1 border border-n-weak shadow-2xl overflow-hidden"
    @click.stop
  >
    <template v-if="activeBottomTab === 'emoji'">
      <div class="flex items-center justify-between px-3 pt-2">
        <button
          v-for="tab in tabs"
          v-show="tab.id !== RECENT_ID || recentEmojis.length"
          :key="tab.id"
          type="button"
          :title="categoryLabel(tab.id)"
          class="relative grid place-content-center size-9 rounded-lg border-0 bg-transparent cursor-pointer"
          :class="
            activeCategory === tab.id
              ? 'text-n-slate-12'
              : 'text-n-slate-10 hover:text-n-slate-12'
          "
          @click="scrollToCategory(tab.id)"
        >
          <Icon :icon="tab.icon" class="size-5" />
          <span
            v-if="activeCategory === tab.id"
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
            :placeholder="t('CONVERSATION.EMOJI_PANEL.SEARCH')"
          />
        </label>
      </div>
      <div
        ref="scrollRef"
        class="flex-1 overflow-y-auto px-2 pb-2 relative"
        @scroll.passive="onScroll"
      >
        <template v-for="section in sections" :key="section.id">
          <p
            v-if="section.title"
            :data-section="section.id"
            class="px-1.5 pt-2 pb-1 mb-0 text-xs font-medium text-n-slate-11"
          >
            {{ section.title }}
          </p>
          <div class="grid grid-cols-9 gap-0.5">
            <button
              v-for="emoji in section.emojis"
              :key="`${section.id}-${emoji.slug}`"
              type="button"
              :title="emoji.name"
              class="grid place-content-center h-10 rounded-lg border-0 bg-transparent cursor-pointer hover:bg-n-alpha-2 text-2xl leading-none"
              @click="selectEmoji(emoji)"
            >
              <span class="wa-emoji-glyph select-none">{{ emoji.emoji }}</span>
            </button>
          </div>
          <p
            v-if="section.id === 'search' && !section.emojis.length"
            class="py-8 text-center text-sm text-n-slate-10"
          >
            {{ t('CONVERSATION.EMOJI_PANEL.NO_RESULTS') }}
          </p>
        </template>

      </div>
    </template>

    <StickerTab
      v-else-if="activeBottomTab === 'sticker'"
      @send="sticker => emit('sendSticker', sticker)"
      @busy="value => emit('busy', value)"
    />
    <div
      v-else
      class="flex-1 grid place-content-center gap-2 text-center text-sm text-n-slate-10 px-8"
    >
      <Icon
        :icon="activeBottomTab === 'gif' ? 'i-ph-gif' : 'i-ph-sticker'"
        class="size-10 mx-auto text-n-slate-8"
      />
      {{
        activeBottomTab === 'gif'
          ? t('CONVERSATION.EMOJI_PANEL.GIF_SOON')
          : t('CONVERSATION.EMOJI_PANEL.STICKERS_SOON')
      }}
    </div>

    <div v-if="!emojiOnly" class="flex justify-center pb-2 pt-1">
      <div
        class="flex items-center rounded-full border border-n-weak overflow-hidden"
      >
        <button
          v-for="tab in ['emoji', 'gif', 'sticker']"
          :key="tab"
          type="button"
          class="h-9 w-16 grid place-content-center border-0 cursor-pointer"
          :class="
            activeBottomTab === tab
              ? 'bg-n-alpha-2 text-n-slate-12'
              : 'bg-transparent text-n-slate-10 hover:text-n-slate-12'
          "
          @click="activeBottomTab = tab"
        >
          <span v-if="tab === 'gif'" class="text-xs font-semibold">GIF</span>
          <Icon
            v-else
            :icon="tab === 'emoji' ? 'i-ph-smiley' : 'i-ph-sticker'"
            class="size-5"
          />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.wa-emoji-glyph {
  font-family: 'Noto Color Emoji', sans-serif;
  font-size: 1.625rem;
  line-height: 1;
}
</style>
