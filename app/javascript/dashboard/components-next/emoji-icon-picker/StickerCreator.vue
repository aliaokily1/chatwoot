<script setup>
// Elkheta: make a WhatsApp sticker from any image — zoom/move, caption text,
// remove a white background — and save it as a 512×512 WebP (≤ 100 KB).
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import StickersAPI from 'dashboard/api/stickers';

const emit = defineEmits(['close', 'created']);
const { t } = useI18n();

const SIZE = 512;
const MAX_BYTES = 100 * 1024;

const canvasRef = ref(null);
const fileInput = ref(null);
const image = ref(null);
const zoom = ref(1);
const offset = ref({ x: 0, y: 0 });
const caption = ref('');
const captionPosition = ref('bottom');
const captionColor = ref('#FFFFFF');
const removeWhite = ref(false);
const whiteThreshold = ref(235);
const name = ref('');
const isSaving = ref(false);
const errorMessage = ref('');
let drag = null;

const hasImage = computed(() => !!image.value);

const loadFile = file => {
  if (!file || !file.type.startsWith('image/')) return;
  const url = URL.createObjectURL(file);
  const img = new Image();
  img.onload = () => {
    image.value = img;
    zoom.value = 1;
    offset.value = { x: 0, y: 0 };
    URL.revokeObjectURL(url);
  };
  img.src = url;
};

const onPick = event => loadFile(event.target.files?.[0]);
const onDrop = event => loadFile(event.dataTransfer?.files?.[0]);
const onPaste = event => {
  const item = [...(event.clipboardData?.items || [])].find(i =>
    i.type.startsWith('image/')
  );
  if (item) loadFile(item.getAsFile());
};

const draw = () => {
  const canvas = canvasRef.value;
  if (!canvas) return;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  ctx.clearRect(0, 0, SIZE, SIZE);
  const img = image.value;
  if (!img) return;

  // "contain" fit, then user zoom + pan
  const scale = Math.min(SIZE / img.width, SIZE / img.height) * zoom.value;
  const w = img.width * scale;
  const h = img.height * scale;
  const x = (SIZE - w) / 2 + offset.value.x;
  const y = (SIZE - h) / 2 + offset.value.y;
  ctx.drawImage(img, x, y, w, h);

  if (removeWhite.value) {
    const data = ctx.getImageData(0, 0, SIZE, SIZE);
    const px = data.data;
    const limit = whiteThreshold.value;
    for (let i = 0; i < px.length; i += 4) {
      if (px[i] >= limit && px[i + 1] >= limit && px[i + 2] >= limit) {
        px[i + 3] = 0;
      }
    }
    ctx.putImageData(data, 0, 0);
  }

  const text = caption.value.trim();
  if (text) {
    ctx.font = `700 64px 'Readex Pro', 'IBM Plex Sans Arabic', sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = captionPosition.value === 'top' ? 'top' : 'bottom';
    ctx.lineJoin = 'round';
    ctx.lineWidth = 12;
    ctx.strokeStyle = captionColor.value === '#FFFFFF' ? '#111B21' : '#FFFFFF';
    ctx.fillStyle = captionColor.value;
    const ty = captionPosition.value === 'top' ? 24 : SIZE - 24;
    ctx.strokeText(text, SIZE / 2, ty, SIZE - 40);
    ctx.fillText(text, SIZE / 2, ty, SIZE - 40);
  }
};

watch(
  [image, zoom, offset, caption, captionPosition, captionColor, removeWhite, whiteThreshold],
  () => nextTick(draw),
  { deep: true }
);

const startDrag = event => {
  if (!hasImage.value) return;
  drag = { x: event.clientX, y: event.clientY, start: { ...offset.value } };
};
const moveDrag = event => {
  if (!drag) return;
  const rect = canvasRef.value.getBoundingClientRect();
  const ratio = SIZE / rect.width;
  offset.value = {
    x: drag.start.x + (event.clientX - drag.x) * ratio,
    y: drag.start.y + (event.clientY - drag.y) * ratio,
  };
};
const endDrag = () => {
  drag = null;
};

const toWebp = quality =>
  new Promise(resolve => {
    canvasRef.value.toBlob(blob => resolve(blob), 'image/webp', quality);
  });

const save = async () => {
  if (!hasImage.value || isSaving.value) return;
  errorMessage.value = '';
  isSaving.value = true;
  try {
    draw();
    let blob = null;
    for (const quality of [0.92, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35]) {
      // eslint-disable-next-line no-await-in-loop
      blob = await toWebp(quality);
      if (blob && blob.size <= MAX_BYTES) break;
    }
    if (!blob || blob.type !== 'image/webp') {
      errorMessage.value = t('CONVERSATION.STICKERS.CREATE_UNSUPPORTED');
      return;
    }
    if (blob.size > MAX_BYTES) {
      errorMessage.value = t('CONVERSATION.STICKERS.TOO_BIG');
      return;
    }
    const file = new File([blob], 'sticker.webp', { type: 'image/webp' });
    const { data } = await StickersAPI.upload(file, name.value.trim());
    emit('created', data);
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.error || t('CONVERSATION.STICKERS.CREATE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

window.addEventListener('mousemove', moveDrag);
window.addEventListener('mouseup', endDrag);
onBeforeUnmount(() => {
  window.removeEventListener('mousemove', moveDrag);
  window.removeEventListener('mouseup', endDrag);
});
</script>

<template>
  <div
    class="fixed inset-0 z-[200] grid place-items-center bg-n-alpha-black1 backdrop-blur-sm p-4"
    @click.self="emit('close')"
    @paste="onPaste"
  >
    <div
      class="w-full max-w-3xl rounded-2xl bg-n-solid-1 border border-n-weak shadow-2xl overflow-hidden"
      @click.stop
    >
      <div class="flex items-center justify-between px-5 py-3 border-b border-n-weak">
        <h3 class="text-base font-semibold text-n-slate-12 m-0">
          {{ t('CONVERSATION.STICKERS.CREATE_TITLE') }}
        </h3>
        <Button icon="i-lucide-x" slate ghost sm @click="emit('close')" />
      </div>

      <div class="grid md:grid-cols-[1fr_16rem] gap-5 p-5">
        <div
          class="relative aspect-square w-full max-w-[26rem] mx-auto rounded-xl overflow-hidden border border-n-weak wa-checker"
          @dragover.prevent
          @drop.prevent="onDrop"
        >
          <canvas
            ref="canvasRef"
            :width="SIZE"
            :height="SIZE"
            class="w-full h-full"
            :class="hasImage ? 'cursor-move' : ''"
            @mousedown.prevent="startDrag"
          />
          <button
            v-if="!hasImage"
            type="button"
            class="absolute inset-0 grid place-content-center gap-2 text-center text-n-slate-11 border-0 bg-transparent cursor-pointer"
            @click="fileInput.click()"
          >
            <Icon icon="i-ph-image-square" class="size-12 mx-auto text-n-slate-9" />
            <span class="text-sm">{{ t('CONVERSATION.STICKERS.PICK_IMAGE') }}</span>
            <span class="text-xs text-n-slate-10">{{ t('CONVERSATION.STICKERS.PICK_HINT') }}</span>
          </button>
          <input
            ref="fileInput"
            type="file"
            accept="image/*"
            class="hidden"
            @change="onPick"
          />
        </div>

        <div class="flex flex-col gap-4 text-sm">
          <label class="flex flex-col gap-1.5">
            <span class="text-n-slate-11">{{ t('CONVERSATION.STICKERS.ZOOM') }}</span>
            <input
              v-model.number="zoom"
              type="range"
              min="0.3"
              max="3"
              step="0.05"
              :disabled="!hasImage"
              class="accent-n-brand"
            />
          </label>

          <label class="flex flex-col gap-1.5">
            <span class="text-n-slate-11">{{ t('CONVERSATION.STICKERS.TEXT') }}</span>
            <input
              v-model="caption"
              type="text"
              maxlength="30"
              :placeholder="t('CONVERSATION.STICKERS.TEXT_PLACEHOLDER')"
              class="!mb-0"
            />
          </label>
          <div class="flex gap-2">
            <button
              v-for="pos in ['top', 'bottom']"
              :key="pos"
              type="button"
              class="flex-1 h-8 rounded-lg border-0 cursor-pointer text-xs"
              :class="captionPosition === pos ? 'bg-n-brand/15 text-n-blue-11' : 'bg-n-alpha-2 text-n-slate-11'"
              @click="captionPosition = pos"
            >
              {{ t(`CONVERSATION.STICKERS.TEXT_${pos.toUpperCase()}`) }}
            </button>
            <button
              v-for="color in ['#FFFFFF', '#111B21', '#F7D633']"
              :key="color"
              type="button"
              class="size-8 rounded-full border-2 cursor-pointer"
              :class="captionColor === color ? 'border-n-brand' : 'border-n-weak'"
              :style="{ backgroundColor: color }"
              @click="captionColor = color"
            />
          </div>

          <label class="flex items-center gap-2 cursor-pointer">
            <input v-model="removeWhite" type="checkbox" :disabled="!hasImage" class="!m-0" />
            <span class="text-n-slate-12">{{ t('CONVERSATION.STICKERS.REMOVE_WHITE') }}</span>
          </label>
          <input
            v-if="removeWhite"
            v-model.number="whiteThreshold"
            type="range"
            min="180"
            max="254"
            class="accent-n-brand"
          />

          <label class="flex flex-col gap-1.5">
            <span class="text-n-slate-11">{{ t('CONVERSATION.STICKERS.NAME') }}</span>
            <input
              v-model="name"
              type="text"
              maxlength="60"
              :placeholder="t('CONVERSATION.STICKERS.NAME_PLACEHOLDER')"
              class="!mb-0"
            />
          </label>

          <p v-if="errorMessage" class="text-n-ruby-11 text-xs m-0">{{ errorMessage }}</p>

          <div class="flex gap-2 mt-auto">
            <Button
              v-if="hasImage"
              :label="t('CONVERSATION.STICKERS.CHANGE_IMAGE')"
              slate
              faded
              sm
              class="flex-1"
              @click="fileInput.click()"
            />
            <Button
              :label="t('CONVERSATION.STICKERS.SAVE')"
              sm
              class="flex-1"
              :disabled="!hasImage"
              :is-loading="isSaving"
              @click="save"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.wa-checker {
  background-color: rgb(var(--slate-3));
  background-image:
    linear-gradient(45deg, rgb(var(--slate-5)) 25%, transparent 25%),
    linear-gradient(-45deg, rgb(var(--slate-5)) 25%, transparent 25%),
    linear-gradient(45deg, transparent 75%, rgb(var(--slate-5)) 75%),
    linear-gradient(-45deg, transparent 75%, rgb(var(--slate-5)) 75%);
  background-size: 20px 20px;
  background-position: 0 0, 0 10px, 10px -10px, -10px 0;
}
</style>
