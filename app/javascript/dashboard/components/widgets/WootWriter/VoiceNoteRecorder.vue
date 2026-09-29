<script setup>
// Elkheta: WhatsApp-style voice note recorder.
// Record → pause → listen to what you have so far → resume (appends) → send or delete.
// Uses one continuous MediaRecorder session, so paused/resumed parts form one file.
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import getUuid from 'widget/helpers/uuid';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { convertAudio } from './utils/audioConversionUtils';

const props = defineProps({
  audioRecordFormat: { type: String, required: true },
});

const emit = defineEmits([
  'finishRecord',
  'recordError',
  'cancel',
  'recorderProgressChanged',
]);

const { t } = useI18n();

const AUDIO_EXTENSION_MAP = {
  'audio/ogg': 'ogg',
  'audio/mp3': 'mp3',
  'audio/mpeg': 'mp3',
  'audio/wav': 'wav',
  'audio/webm': 'webm',
};
const BAR_COUNT = 48;

const status = ref('starting'); // starting | recording | paused | finishing
const elapsedMs = ref(0);
const levels = ref(Array(BAR_COUNT).fill(0.05));
const isPreviewPlaying = ref(false);
const previewProgress = ref(0);

let stream = null;
let mediaRecorder = null;
let chunks = [];
let audioContext = null;
let analyser = null;
let rafId = null;
let tickTimer = null;
let segmentStartedAt = 0;
let previewAudio = null;
let previewUrl = null;
let flushResolver = null;

const timeLabel = computed(() => {
  const total = Math.floor(elapsedMs.value / 1000);
  const minutes = Math.floor(total / 60);
  const seconds = String(total % 60).padStart(2, '0');
  return `${minutes}:${seconds}`;
});

const pickMimeType = () => {
  const wanted =
    props.audioRecordFormat === 'audio/ogg'
      ? ['audio/ogg;codecs=opus', 'audio/webm;codecs=opus', 'audio/webm']
      : ['audio/webm;codecs=opus', 'audio/webm', 'audio/ogg;codecs=opus'];
  return wanted.find(type => MediaRecorder.isTypeSupported?.(type)) || '';
};

const startTicking = () => {
  segmentStartedAt = Date.now();
  const base = elapsedMs.value;
  tickTimer = setInterval(() => {
    elapsedMs.value = base + (Date.now() - segmentStartedAt);
    emit('recorderProgressChanged', timeLabel.value);
  }, 200);
};

const stopTicking = () => {
  clearInterval(tickTimer);
  tickTimer = null;
};

const drawLevels = () => {
  if (!analyser) return;
  const data = new Uint8Array(analyser.fftSize);
  analyser.getByteTimeDomainData(data);
  let peak = 0;
  for (let i = 0; i < data.length; i += 1) {
    peak = Math.max(peak, Math.abs(data[i] - 128) / 128);
  }
  levels.value = [...levels.value.slice(1), Math.max(0.05, Math.min(1, peak * 2.2))];
  rafId = requestAnimationFrame(drawLevels);
};

const stopDrawing = () => {
  cancelAnimationFrame(rafId);
  rafId = null;
};

const releaseDevices = () => {
  stopDrawing();
  stopTicking();
  stream?.getTracks().forEach(track => track.stop());
  stream = null;
  audioContext?.close();
  audioContext = null;
  analyser = null;
};

const clearPreview = () => {
  previewAudio?.pause();
  previewAudio = null;
  if (previewUrl) URL.revokeObjectURL(previewUrl);
  previewUrl = null;
  isPreviewPlaying.value = false;
  previewProgress.value = 0;
};

const start = async () => {
  try {
    stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const mimeType = pickMimeType();
    mediaRecorder = new MediaRecorder(stream, mimeType ? { mimeType } : {});
    mediaRecorder.ondataavailable = event => {
      if (event.data?.size) chunks.push(event.data);
      if (flushResolver) {
        flushResolver();
        flushResolver = null;
      }
    };
    mediaRecorder.start(250);

    audioContext = new AudioContext();
    analyser = audioContext.createAnalyser();
    analyser.fftSize = 512;
    audioContext.createMediaStreamSource(stream).connect(analyser);

    status.value = 'recording';
    startTicking();
    drawLevels();
  } catch (error) {
    releaseDevices();
    emit('recordError', { error });
  }
};

const flushData = () =>
  new Promise(resolve => {
    flushResolver = resolve;
    try {
      mediaRecorder.requestData();
    } catch {
      resolve();
    }
    setTimeout(resolve, 400);
  });

const pause = async () => {
  if (status.value !== 'recording') return;
  mediaRecorder.pause();
  stopTicking();
  stopDrawing();
  status.value = 'paused';
  await flushData();
};

const resume = () => {
  if (status.value !== 'paused') return;
  clearPreview();
  mediaRecorder.resume();
  status.value = 'recording';
  startTicking();
  drawLevels();
};

const togglePreview = () => {
  if (status.value !== 'paused' || !chunks.length) return;
  if (!previewAudio) {
    previewUrl = URL.createObjectURL(
      new Blob(chunks, { type: mediaRecorder.mimeType || chunks[0].type })
    );
    previewAudio = new Audio(previewUrl);
    previewAudio.addEventListener('timeupdate', () => {
      const duration = elapsedMs.value / 1000 || 1;
      previewProgress.value = Math.min(1, previewAudio.currentTime / duration);
    });
    previewAudio.addEventListener('ended', () => {
      isPreviewPlaying.value = false;
      previewProgress.value = 0;
    });
  }
  if (isPreviewPlaying.value) {
    previewAudio.pause();
    isPreviewPlaying.value = false;
  } else {
    previewAudio.play();
    isPreviewPlaying.value = true;
  }
};

// Stops recording and emits the finished file. Resolves with the file (or null).
const finish = () =>
  new Promise(resolve => {
    if (!mediaRecorder || status.value === 'finishing') {
      resolve(null);
      return;
    }
    status.value = 'finishing';
    clearPreview();
    mediaRecorder.onstop = async () => {
      releaseDevices();
      try {
        const recorded = new Blob(chunks, {
          type: mediaRecorder.mimeType || chunks[0]?.type || 'audio/webm',
        });
        const audioBlob = await convertAudio(recorded, props.audioRecordFormat);
        const audioType = audioBlob.type || props.audioRecordFormat;
        const ext = AUDIO_EXTENSION_MAP[audioType] || 'mp3';
        const file = new File([audioBlob], `${getUuid()}.${ext}`, {
          type: audioType,
        });
        const payload = { name: file.name, type: file.type, size: file.size, file };
        emit('finishRecord', payload);
        resolve(payload);
      } catch (error) {
        emit('recordError', { error });
        resolve(null);
      }
    };
    if (mediaRecorder.state === 'inactive') {
      mediaRecorder.onstop();
    } else {
      mediaRecorder.stop();
    }
  });

const cancel = () => {
  clearPreview();
  if (mediaRecorder && mediaRecorder.state !== 'inactive') {
    mediaRecorder.onstop = null;
    mediaRecorder.stop();
  }
  releaseDevices();
  chunks = [];
  emit('cancel');
};

onMounted(start);

onUnmounted(() => {
  clearPreview();
  if (mediaRecorder && mediaRecorder.state !== 'inactive' && status.value !== 'finishing') {
    mediaRecorder.onstop = null;
    mediaRecorder.stop();
  }
  releaseDevices();
});

// Kept compatible with the old recorder's API used by ReplyBox
const stopRecording = () => finish();
const playPause = () => togglePreview();

defineExpose({ finish, cancel, pause, resume, stopRecording, playPause });
</script>

<template>
  <div class="flex items-center gap-2 w-full h-10 select-none">
    <button
      type="button"
      class="grid place-content-center size-8 rounded-full border-0 bg-transparent text-n-slate-11 hover:text-n-ruby-9 cursor-pointer"
      :title="t('CONVERSATION.VOICE_NOTE.DELETE')"
      @click="cancel"
    >
      <Icon icon="i-ph-trash" class="size-5" />
    </button>

    <button
      v-if="status === 'paused'"
      type="button"
      class="grid place-content-center size-8 rounded-full border-0 bg-transparent text-n-slate-12 cursor-pointer"
      :title="t('CONVERSATION.VOICE_NOTE.LISTEN')"
      @click="togglePreview"
    >
      <Icon
        :icon="isPreviewPlaying ? 'i-ph-pause-fill' : 'i-ph-play-fill'"
        class="size-5"
      />
    </button>
    <span
      v-else
      class="size-2.5 mx-2.5 rounded-full bg-n-ruby-9 animate-pulse flex-shrink-0"
    />

    <div class="flex-1 flex items-center gap-[2px] h-8 overflow-hidden min-w-0">
      <span
        v-for="(level, index) in levels"
        :key="index"
        class="flex-1 min-w-[2px] max-w-[4px] rounded-full transition-[height] duration-100"
        :class="
          status === 'paused' && index / levels.length <= previewProgress
            ? 'bg-n-brand'
            : 'bg-n-slate-9'
        "
        :style="{ height: `${Math.round(level * 100)}%` }"
      />
    </div>

    <span class="tabular-nums text-sm text-n-slate-11 w-10 text-end">
      {{ timeLabel }}
    </span>

    <button
      v-if="status === 'recording'"
      type="button"
      class="grid place-content-center size-8 rounded-full border-0 bg-transparent text-n-slate-12 hover:text-n-brand cursor-pointer"
      :title="t('CONVERSATION.VOICE_NOTE.PAUSE')"
      @click="pause"
    >
      <Icon icon="i-ph-pause-circle" class="size-6" />
    </button>
    <button
      v-else-if="status === 'paused'"
      type="button"
      class="grid place-content-center size-8 rounded-full border-0 bg-transparent text-n-ruby-9 cursor-pointer"
      :title="t('CONVERSATION.VOICE_NOTE.RESUME')"
      @click="resume"
    >
      <Icon icon="i-ph-microphone-fill" class="size-5" />
    </button>
    <Icon
      v-else
      icon="i-ph-circle-notch"
      class="size-5 animate-spin text-n-slate-10"
    />
  </div>
</template>
