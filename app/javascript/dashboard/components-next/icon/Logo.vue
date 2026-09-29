<script setup>
// Elkheta: the Elkheta Class mark (the dark bar turns light in dark mode)
import { useAttrs } from 'vue';

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();
</script>

<template>
  <img
    v-bind="attrs"
    src="/brand-assets/logo_mark.svg"
    alt="Elkheta Class"
    class="dark:hidden"
  />
  <img
    v-bind="attrs"
    src="/brand-assets/logo_mark_dark.svg"
    alt="Elkheta Class"
    class="hidden dark:block"
  />
</template>
