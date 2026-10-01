import { onMounted, onUnmounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const RETRY_GAP_MS = 15000;

// Elkheta: the inboxes (Admin numbers) list is loaded once when the dashboard opens.
// If that request fails (e.g. while the server restarts during a deploy), screens lose
// the inbox: no number name, and message ticks fall back to a "Sending" clock.
// Reload the list after a reconnect, and whenever an open chat's inbox is missing.
export function useInboxesSelfHeal() {
  const store = useStore();
  const selectedChat = useMapGetter('getSelectedChat');
  let lastTry = 0;

  const reload = () => {
    if (Date.now() - lastTry < RETRY_GAP_MS) return;
    lastTry = Date.now();
    store.dispatch('inboxes/get');
  };

  watch(
    () => selectedChat.value?.inbox_id,
    inboxId => {
      if (inboxId && !store.getters['inboxes/getInboxById'](inboxId)?.id) {
        reload();
      }
    },
    { immediate: true }
  );

  const onReconnect = () => {
    lastTry = 0;
    reload();
  };
  onMounted(() => emitter.on(BUS_EVENTS.WEBSOCKET_RECONNECT, onReconnect));
  onUnmounted(() => emitter.off(BUS_EVENTS.WEBSOCKET_RECONNECT, onReconnect));
}
