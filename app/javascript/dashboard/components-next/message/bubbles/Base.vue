<script setup>
import { computed } from 'vue';

import MessageMeta from '../MessageMeta.vue';
import CaptainGenerationDetails from '../CaptainGenerationDetails.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  MESSAGE_TYPES,
  MESSAGE_VARIANTS,
  ORIENTATION,
  SENDER_TYPES,
} from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

const {
  variant,
  orientation,
  inReplyTo,
  shouldGroupWithNext,
  groupWithPrevious,
  currentUserId,
  id,
  sender,
  senderType,
} = useMessageContext();
const { t } = useI18n();

const isCaptainMessage = computed(
  () =>
    (sender.value?.type ?? senderType.value) === SENDER_TYPES.CAPTAIN_ASSISTANT
);

// Elkheta: variants drawn as WhatsApp bubbles
const WHATSAPP_STYLE_VARIANTS = [
  MESSAGE_VARIANTS.AGENT,
  MESSAGE_VARIANTS.USER,
  MESSAGE_VARIANTS.BOT,
  MESSAGE_VARIANTS.TEMPLATE,
];

const isWhatsAppStyle = computed(() =>
  WHATSAPP_STYLE_VARIANTS.includes(variant.value)
);

const metaColorClass = computed(() => {
  if (variant.value === MESSAGE_VARIANTS.PRIVATE) return 'text-n-amber-12/50';
  if (isWhatsAppStyle.value) {
    return orientation.value === ORIENTATION.RIGHT
      ? 'text-n-wa-meta-out'
      : 'text-n-wa-meta';
  }
  return 'text-n-slate-11';
});

const emailMetaClass = computed(() =>
  variant.value === MESSAGE_VARIANTS.EMAIL ? 'px-3 pb-3' : ''
);

const varaintBaseMap = {
  [MESSAGE_VARIANTS.AGENT]: 'bg-n-wa-out text-n-wa-text',
  [MESSAGE_VARIANTS.PRIVATE]:
    'bg-n-solid-amber text-n-amber-12 [&_.prosemirror-mention-node]:font-semibold',
  [MESSAGE_VARIANTS.USER]: 'bg-n-wa-in text-n-wa-text',
  [MESSAGE_VARIANTS.ACTIVITY]: 'bg-n-alpha-1 text-n-slate-11 text-sm',
  [MESSAGE_VARIANTS.BOT]: 'bg-n-wa-out text-n-wa-text',
  [MESSAGE_VARIANTS.TEMPLATE]: 'bg-n-wa-out text-n-wa-text',
  [MESSAGE_VARIANTS.ERROR]: 'bg-n-ruby-4 text-n-ruby-12',
  [MESSAGE_VARIANTS.EMAIL]: 'w-full',
  [MESSAGE_VARIANTS.UNSUPPORTED]:
    'bg-n-solid-amber/70 border border-dashed border-n-amber-12 text-n-amber-12',
};

const orientationMap = {
  [ORIENTATION.LEFT]:
    'left-bubble rounded-xl ltr:rounded-bl-sm rtl:rounded-br-sm',
  [ORIENTATION.RIGHT]:
    'right-bubble rounded-xl ltr:rounded-br-sm rtl:rounded-bl-sm',
  [ORIENTATION.CENTER]: 'rounded-md',
};

const flexOrientationClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'justify-start',
    [ORIENTATION.RIGHT]: 'justify-end',
    [ORIENTATION.CENTER]: 'justify-center',
  };

  return map[orientation.value];
});

// Elkheta: WhatsApp bubble shape. The first message of a group gets a tail.
const whatsAppShapeMap = {
  [ORIENTATION.LEFT]: {
    base: 'wa-bubble wa-in rounded-lg',
    tail: 'wa-tail ltr:rounded-tl-none rtl:rounded-tr-none',
  },
  [ORIENTATION.RIGHT]: {
    base: 'wa-bubble wa-out rounded-lg',
    tail: 'wa-tail ltr:rounded-tr-none rtl:rounded-tl-none',
  },
};

const messageClass = computed(() => {
  const classToApply = [varaintBaseMap[variant.value]];
  const whatsAppShape = whatsAppShapeMap[orientation.value];

  if (isWhatsAppStyle.value && whatsAppShape) {
    classToApply.push(whatsAppShape.base);
    if (!groupWithPrevious?.value) classToApply.push(whatsAppShape.tail);
  } else if (variant.value !== MESSAGE_VARIANTS.ACTIVITY) {
    classToApply.push(orientationMap[orientation.value]);
  } else {
    classToApply.push('rounded-lg');
  }

  return classToApply;
});

const scrollToMessage = () => {
  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, {
    messageId: inReplyTo.value.id,
  });
};

const shouldShowMeta = computed(
  () =>
    !props.hideMeta &&
    !shouldGroupWithNext.value &&
    variant.value !== MESSAGE_VARIANTS.ACTIVITY
);

const replyToPreview = computed(() => {
  if (!inReplyTo) return '';

  const { content, attachments } = inReplyTo.value;

  if (content) return new MessageFormatter(content).formattedMessage;
  if (attachments?.length) {
    const firstAttachment = attachments[0];
    const fileType = firstAttachment.fileType ?? firstAttachment.file_type;

    return t(`CHAT_LIST.ATTACHMENTS.${fileType}.CONTENT`);
  }

  return t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND');
});

// Elkheta: show who wrote the quoted message, like WhatsApp.
const replyToSender = computed(() => {
  const reply = inReplyTo?.value;
  if (!reply) return null;

  const messageType = reply.messageType ?? reply.message_type;
  const replySender = reply.sender ?? {};
  const attributes = reply.contentAttributes ?? reply.content_attributes ?? {};
  const isFromUs =
    messageType === MESSAGE_TYPES.OUTGOING ||
    messageType === MESSAGE_TYPES.TEMPLATE;

  if (isFromUs) {
    const isMe =
      (replySender.id && replySender.id === currentUserId?.value) ||
      attributes.externalEcho ||
      attributes.external_echo;
    if (isMe) return { name: t('CONVERSATION.REPLY_YOU'), isUs: true };
  }

  const name =
    replySender.availableName ??
    replySender.available_name ??
    replySender.name;
  if (!name) return null;

  return { name, isUs: isFromUs };
});
</script>

<template>
  <div
    class="text-sm min-w-0"
    :class="[
      messageClass,
      {
        'max-w-lg': variant !== MESSAGE_VARIANTS.EMAIL,
      },
    ]"
  >
    <div
      v-if="inReplyTo"
      class="px-2 py-1.5 -mx-1 mb-1.5 rounded-md cursor-pointer bg-n-wa-quote/5 dark:bg-n-wa-quote/20 border-s-4"
      :class="
        replyToSender?.isUs ? 'border-n-wa-accent' : 'border-n-iris-9'
      "
      @click="scrollToMessage"
    >
      <div
        v-if="replyToSender"
        class="text-xs font-semibold mb-0.5 truncate"
        :class="replyToSender.isUs ? 'text-n-wa-accent' : 'text-n-iris-11'"
      >
        {{ replyToSender.name }}
      </div>
      <div
        v-dompurify-html="replyToPreview"
        class="prose prose-bubble line-clamp-2 opacity-80"
      />
    </div>
    <slot />
    <template v-if="shouldShowMeta">
      <CaptainGenerationDetails
        v-if="isCaptainMessage"
        :message-id="id"
        class="mt-2"
      >
        <template #meta>
          <MessageMeta :class="[emailMetaClass, metaColorClass]" />
        </template>
      </CaptainGenerationDetails>
      <MessageMeta
        v-else-if="isWhatsAppStyle"
        :class="metaColorClass"
        class="mt-0.5 justify-end !text-[11px] leading-4"
      />
      <MessageMeta
        v-else
        :class="[flexOrientationClass, emailMetaClass, metaColorClass]"
        class="mt-2"
      />
    </template>
  </div>
</template>
