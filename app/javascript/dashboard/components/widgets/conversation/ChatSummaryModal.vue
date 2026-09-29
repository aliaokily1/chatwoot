<script setup>
// Elkheta: "Summarize with AI" — what the student said, what the Admin said,
// what was agreed and what to focus on next.
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import Icon from 'next/icon/Icon.vue';
import Button from 'next/button/Button.vue';
import ChatToolsAPI from 'dashboard/api/chatTools';
import MessageApi from 'dashboard/api/inbox/message';

const props = defineProps({
  conversationId: { type: Number, required: true },
  contactName: { type: String, default: '' },
});
const emit = defineEmits(['close']);
const { t, locale } = useI18n();

const summary = ref(null);
const isLoading = ref(false);
const error = ref('');
const isSaving = ref(false);

const SECTIONS = [
  { key: 'student_said', icon: 'i-ph-student', label: 'STUDENT_SAID' },
  { key: 'admin_said', icon: 'i-ph-chalkboard-teacher', label: 'ADMIN_SAID' },
  { key: 'agreed', icon: 'i-ph-handshake', label: 'AGREED' },
  { key: 'focus_next', icon: 'i-ph-target', label: 'FOCUS_NEXT' },
];

const isEmpty = computed(
  () =>
    summary.value &&
    !summary.value.overview &&
    SECTIONS.every(({ key }) => !summary.value[key]?.length)
);

const load = async () => {
  isLoading.value = true;
  error.value = '';
  try {
    const { data } = await ChatToolsAPI.summarize(
      props.conversationId,
      locale.value
    );
    summary.value = data;
  } catch (e) {
    const code = e?.response?.data?.error;
    error.value =
      code === 'not_configured'
        ? t('CONVERSATION.CHAT_TOOLS.NOT_CONFIGURED')
        : code || t('CONVERSATION.CHAT_TOOLS.SUMMARY_ERROR');
  } finally {
    isLoading.value = false;
  }
};

const asText = () => {
  const lines = [`✨ ${t('CONVERSATION.CHAT_TOOLS.SUMMARY_TITLE')}`];
  if (summary.value.overview) lines.push(summary.value.overview);
  SECTIONS.forEach(({ key, label }) => {
    const points = summary.value[key] || [];
    if (!points.length) return;
    lines.push('', `${t(`CONVERSATION.CHAT_TOOLS.${label}`)}:`);
    points.forEach(point => lines.push(`• ${point}`));
  });
  return lines.join('\n');
};

const copy = async () => {
  await copyTextToClipboard(asText());
  useAlert(t('CONVERSATION.CHAT_TOOLS.COPIED'));
};

const saveAsNote = async () => {
  isSaving.value = true;
  try {
    await MessageApi.create({
      conversationId: props.conversationId,
      message: asText(),
      private: true,
    });
    useAlert(t('CONVERSATION.CHAT_TOOLS.NOTE_SAVED'));
    emit('close');
  } catch {
    useAlert(t('CONVERSATION.CHAT_TOOLS.NOTE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

onMounted(load);
</script>

<template>
  <div
    class="fixed inset-0 z-[200] grid place-items-center bg-n-alpha-black1 backdrop-blur-sm p-4"
    @click.self="emit('close')"
  >
    <div
      class="w-full max-w-lg max-h-[85vh] flex flex-col rounded-2xl bg-n-solid-1 border border-n-weak shadow-2xl overflow-hidden"
    >
      <div
        class="flex items-center gap-3 px-5 py-3 border-b border-n-weak"
      >
        <span
          class="grid place-content-center size-8 rounded-full bg-n-brand/10 text-n-brand flex-shrink-0"
        >
          <Icon icon="i-ph-sparkle-fill" class="size-4" />
        </span>
        <div class="flex flex-col min-w-0 flex-1">
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            {{ t('CONVERSATION.CHAT_TOOLS.SUMMARY_TITLE') }}
          </h3>
          <span v-if="contactName" class="text-xs text-n-slate-10 truncate">
            {{ contactName }}
          </span>
        </div>
        <Button icon="i-lucide-x" slate ghost sm @click="emit('close')" />
      </div>

      <div class="flex-1 overflow-y-auto px-5 py-4">
        <div v-if="isLoading" class="flex flex-col gap-4">
          <p class="flex items-center gap-2 text-sm text-n-slate-11 m-0">
            <Icon
              icon="i-ph-sparkle-fill"
              class="size-4 text-n-brand animate-pulse"
            />
            {{ t('CONVERSATION.CHAT_TOOLS.READING') }}
          </p>
          <div
            v-for="row in 4"
            :key="row"
            class="flex flex-col gap-2 animate-pulse"
          >
            <span class="h-3 w-1/3 rounded bg-n-alpha-2" />
            <span class="h-3 w-full rounded bg-n-alpha-2" />
            <span class="h-3 w-4/5 rounded bg-n-alpha-2" />
          </div>
        </div>

        <div
          v-else-if="error"
          class="flex flex-col items-center gap-3 py-8 text-center"
        >
          <Icon icon="i-ph-warning-circle" class="size-8 text-n-slate-9" />
          <p class="text-sm text-n-slate-11 m-0 max-w-sm">{{ error }}</p>
          <Button
            :label="t('CONVERSATION.CHAT_TOOLS.RETRY')"
            icon="i-ph-arrow-clockwise"
            slate
            faded
            sm
            @click="load"
          />
        </div>

        <p
          v-else-if="isEmpty"
          class="py-8 text-center text-sm text-n-slate-10 m-0"
        >
          {{ t('CONVERSATION.CHAT_TOOLS.EMPTY') }}
        </p>

        <div v-else-if="summary" class="flex flex-col gap-4">
          <p
            v-if="summary.overview"
            class="m-0 px-4 py-3 rounded-xl bg-n-brand/10 text-sm leading-relaxed text-n-slate-12"
            dir="auto"
          >
            {{ summary.overview }}
          </p>
          <section
            v-for="section in SECTIONS"
            :key="section.key"
            class="flex flex-col gap-1.5"
          >
            <h4
              class="flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-n-slate-10 m-0"
            >
              <Icon :icon="section.icon" class="size-4 text-n-brand" />
              {{ t(`CONVERSATION.CHAT_TOOLS.${section.label}`) }}
            </h4>
            <ul
              v-if="summary[section.key]?.length"
              class="m-0 ps-6 flex flex-col gap-1 list-disc marker:text-n-brand"
            >
              <li
                v-for="(point, index) in summary[section.key]"
                :key="index"
                class="text-sm leading-relaxed text-n-slate-12"
                dir="auto"
              >
                {{ point }}
              </li>
            </ul>
            <p v-else class="m-0 ps-6 text-sm text-n-slate-9">
              {{ t('CONVERSATION.CHAT_TOOLS.NOTHING') }}
            </p>
          </section>
        </div>
      </div>

      <div
        v-if="summary && !isLoading && !error && !isEmpty"
        class="flex items-center justify-end gap-2 px-5 py-3 border-t border-n-weak"
      >
        <Button
          :label="t('CONVERSATION.CHAT_TOOLS.COPY')"
          icon="i-ph-copy"
          slate
          faded
          sm
          @click="copy"
        />
        <Button
          :label="t('CONVERSATION.CHAT_TOOLS.SAVE_NOTE')"
          icon="i-ph-note-pencil"
          sm
          :is-loading="isSaving"
          @click="saveAsNote"
        />
      </div>
    </div>
  </div>
</template>
