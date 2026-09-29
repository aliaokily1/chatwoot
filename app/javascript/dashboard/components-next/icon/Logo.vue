<script setup>
// Elkheta: the Elkheta Class mark (the dark bar turns light in dark mode).
// Paths are bound (not static) so Vite serves them from /public instead of bundling them.
import { useAttrs } from 'vue';

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();
const LIGHT_MARK = '/brand-assets/logo_mark.svg';
const DARK_MARK = '/brand-assets/logo_mark_dark.svg';
</script>

<template>
  <img v-bind="attrs" :src="LIGHT_MARK" alt="Elkheta Class" class="dark:hidden" />
  <img
    v-bind="attrs"
    :src="DARK_MARK"
    alt="Elkheta Class"
    class="hidden dark:block"
  />
</template>
