<script setup lang="ts">
const props = withDefaults(defineProps<{
  helpTitle?: string
  helpSub?: string
  publishTitle?: string
  publishSub?: string
}>(), {
  helpTitle: '爱心传递',
  helpSub: '传递社区温暖',
  publishTitle: '我有难处',
  publishSub: '邻里帮忙一把',
})

const emit = defineEmits<{
  help: []
  publish: []
}>()
</script>

<template>
  <div class="quick-grid">
    <button class="quick-item help" type="button" @click="emit('help')">
      <span class="q-ico solid" aria-hidden="true">
        <FmIcon name="mdi:hand-heart-outline" />
      </span>
      <div class="qa-title tone-light">{{ props.helpTitle }}</div>
      <div class="qa-sub tone-light">{{ props.helpSub }}</div>
    </button>

    <button class="quick-item publish" type="button" @click="emit('publish')">
      <span class="q-ico subtle" aria-hidden="true">
        <FmIcon name="mdi:account-voice" />
      </span>
      <div class="qa-title tone-ink">{{ props.publishTitle }}</div>
      <div class="qa-sub tone-muted">{{ props.publishSub }}</div>
    </button>
  </div>
</template>

<style scoped>
.quick-grid {
  margin-top: 12px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.quick-item {
  appearance: none;
  border-radius: 18px;
  min-height: 128px;
  padding: 14px 14px 16px;
  text-align: left;
  cursor: pointer;
  display: grid;
  align-content: start;
  gap: 6px;
  overflow: hidden;
  transition: transform 180ms cubic-bezier(0.22, 1, 0.36, 1), box-shadow 180ms cubic-bezier(0.22, 1, 0.36, 1);
  box-shadow:
    0 1px 0 rgba(255, 255, 255, 0.35) inset,
    0 8px 18px rgba(15, 23, 42, 0.07);
}
.quick-item:active { transform: translateY(1px); }

.q-ico {
  width: 38px;
  height: 38px;
  border-radius: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}
.q-ico.solid {
  color: rgba(255, 255, 255, 0.95);
  background: rgba(255, 255, 255, 0.18);
  border: 1px solid rgba(255, 255, 255, 0.24);
}
.q-ico.subtle {
  background: #eefbf2;
  border: 1px solid rgba(16, 185, 129, 0.25);
  color: #16a34a;
}

.qa-title {
  margin-top: 4px;
  font-size: 18px;
  font-weight: 900;
  letter-spacing: 0;
  line-height: 1.22;
  display: block;
  max-width: 100%;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  text-shadow: none;
  background: none !important;
}
.qa-sub {
  margin-top: 2px;
  font-size: 12px;
  font-weight: 700;
  line-height: 1.45;
  display: block;
  max-width: 100%;
  text-shadow: none;
  background: none !important;
}
.tone-light { color: #ffffff; }
.tone-ink { color: #0f172a; }
.tone-muted { color: #475569; }

.quick-item.help {
  border: 0;
  background: linear-gradient(135deg, #16a34a 0%, #10b981 100%);
}
.quick-item.publish {
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.94) 0%, rgba(248, 250, 249, 0.98) 100%);
  border: 1px solid rgba(15, 23, 42, 0.08);
  box-shadow:
    0 1px 0 rgba(255, 255, 255, 0.74) inset,
    0 10px 20px rgba(15, 23, 42, 0.06);
}

:global(.dark) .quick-item.publish { background: #1f2937; border-color: #374151; }
:global(.dark) .tone-ink { color: #f3f4f6; }
:global(.dark) .tone-muted { color: #9ca3af; }
:global(.dark) .q-ico.subtle { background: rgba(16, 185, 129, 0.18); border-color: rgba(16, 185, 129, 0.25); color: #86efac; }
</style>
