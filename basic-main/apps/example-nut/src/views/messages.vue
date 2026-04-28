<script setup lang="ts">
import MainTopBar from '@/components/MainTopBar.vue'
import ThreeSectionPage from '@/components/ThreeSectionPage.vue'

definePage({
  meta: {
    title: '消息',
    auth: true,
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()
const resolvedCommunityName = computed(() => appAuthStore.user?.communityName || '未绑定社区')
const headerDistance = computed(() => (appAuthStore.user?.communityName ? '已绑定' : '去绑定'))

function onOpenAi() {
  router.push('/ai-assistant')
}

function onChangeCommunity() {
  router.push('/join-community')
}

const importantNotices = [
  {
    icon: 'mdi:robot-outline',
    title: 'AI 助手提醒',
    desc: '你有 2 条服务建议可查看',
    time: '刚刚',
    accent: 'ai',
  },
  {
    icon: 'mdi:bullhorn-outline',
    title: '社区公告',
    desc: '本周六上午 9 点开展便民活动',
    time: '10 分钟前',
    accent: 'notice',
  },
] as const

const chats = [
  {
    name: '张阿姨',
    avatar: 'https://picsum.photos/seed/chat-a/120/120',
    text: '孩子，周末有空帮我看下电灯吗？',
    time: '12:20',
  },
  {
    name: '李叔',
    avatar: 'https://picsum.photos/seed/chat-b/120/120',
    text: '谢谢你上次送药，辛苦啦。',
    time: '昨天',
  },
  {
    name: '社区管家',
    avatar: 'https://picsum.photos/seed/chat-c/120/120',
    text: '你提交的志愿记录已通过。',
    time: '周五',
  },
] as const
</script>

<template>
  <AppPageLayout :navbar="false" tabbar tabbar-class="m-mobile-tabbar-float">
    <ThreeSectionPage page-class="msg-page m-mobile-page-bg" content-class="msg-content">
      <template #header>
        <MainTopBar
          :community-name="resolvedCommunityName"
          :distance-text="headerDistance"
          right-action="ai"
          @change-community="onChangeCommunity"
          @right="onOpenAi"
        />
      </template>

      <label class="search-wrap">
        <FmIcon name="mdi:magnify" />
        <input type="text" placeholder="搜索联系人或消息">
      </label>

      <section class="section">
        <div class="section-title">
          <h3>重要通知</h3>
          <span>查看全部</span>
        </div>
        <article
          v-for="n in importantNotices"
          :key="n.title"
          class="notice-card"
        >
          <span class="notice-icon" :class="`accent-${n.accent}`">
            <FmIcon :name="n.icon" />
          </span>
          <span class="notice-main">
            <b>{{ n.title }}</b>
            <small>{{ n.desc }}</small>
          </span>
          <time>{{ n.time }}</time>
        </article>
      </section>

      <section class="section">
        <div class="section-title">
          <h3>邻里会话</h3>
          <span class="section-note">演示</span>
        </div>
        <article
          v-for="chat in chats"
          :key="chat.name"
          class="chat-card"
        >
          <img :src="chat.avatar" :alt="chat.name">
          <span class="chat-main">
            <b>{{ chat.name }}</b>
            <small>{{ chat.text }}</small>
          </span>
          <time>{{ chat.time }}</time>
        </article>
      </section>

      <div class="safe-space" />
    </ThreeSectionPage>
  </AppPageLayout>
</template>

<style scoped>
.msg-page {
  min-height: 100%;
  background:
    radial-gradient(120% 84% at 50% -10%, #fafcfb 0%, #f4f7f6 62%, #eff3f2 100%);
}
.msg-content {
  padding: 10px 12px 0;
  display: grid;
  gap: 14px;
  align-content: start;
}
.search-wrap {
  width: 100%;
  height: 46px;
  border-radius: 16px;
  margin-bottom: 6px;
  background: color-mix(in srgb, #ffffff 86%, transparent);
  border: 1px solid rgba(255, 255, 255, 0.74);
  backdrop-filter: blur(10px) saturate(160%);
  -webkit-backdrop-filter: blur(10px) saturate(160%);
  box-shadow:
    0 1px 0 rgba(255, 255, 255, 0.9) inset,
    0 10px 22px rgba(15, 23, 42, 0.08);
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 14px;
  color: #9ca3af;
}
.search-wrap input {
  width: 100%;
  border: 0;
  background: transparent;
  outline: none;
  font-size: 14px;
  color: #111827;
}
.section {
  display: grid;
  gap: 8px;
}
.section + .section {
  margin-top: 6px;
}
.section-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2px;
}
.section-title h3 {
  margin: 0;
  font-size: 17px;
  font-weight: 800;
  color: #111827;
}
.section-title span {
  font-size: 12px;
  font-weight: 700;
  color: #16a34a;
}
.section-note {
  font-size: 11px;
  font-weight: 800;
  padding: 4px 10px;
  border-radius: 999px;
  background: #ecfdf5;
  color: #047857;
  border: 1px solid rgba(16, 185, 129, 0.22);
}
.notice-card,
.chat-card {
  border-radius: 16px;
  background: color-mix(in srgb, #ffffff 86%, transparent);
  border: 1px solid rgba(255, 255, 255, 0.74);
  backdrop-filter: blur(10px) saturate(160%);
  -webkit-backdrop-filter: blur(10px) saturate(160%);
  box-shadow:
    0 1px 0 rgba(255, 255, 255, 0.9) inset,
    0 10px 22px rgba(15, 23, 42, 0.08);
}
.notice-card {
  padding: 10px 12px;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 10px;
}
.notice-icon {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
}
.accent-ai {
  background: #eefbf2;
  color: #16a34a;
}
.accent-notice {
  background: #f4f6f8;
  color: #4b5563;
}
.notice-main,
.chat-main {
  display: grid;
  min-width: 0;
}
.notice-main b,
.chat-main b {
  font-size: 14px;
  color: #111827;
}
.notice-main small,
.chat-main small {
  font-size: 12px;
  color: #6b7280;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.notice-card time,
.chat-card time {
  font-size: 11px;
  color: #9ca3af;
}
.chat-card {
  padding: 10px 12px;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 10px;
  cursor: default;
}
.chat-card img {
  width: 38px;
  height: 38px;
  border-radius: 999px;
  object-fit: cover;
}
.safe-space {
  height: 24px;
}

:global(.dark) .msg-page {
  background: #111827;
}
:global(.dark) .search-wrap,
:global(.dark) .notice-card,
:global(.dark) .chat-card {
  background: color-mix(in srgb, #1f2937 84%, transparent);
  border-color: #374151;
}
:global(.dark) .search-wrap input,
:global(.dark) .section-title h3,
:global(.dark) .notice-main b,
:global(.dark) .chat-main b {
  color: #f3f4f6;
}
:global(.dark) .notice-main small,
:global(.dark) .chat-main small,
:global(.dark) .notice-card time,
:global(.dark) .chat-card time {
  color: #9ca3af;
}
</style>

