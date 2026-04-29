<script setup lang="ts">
import { getMyAiRecords, markAiRecordApplied, type AiAnalysisRecord } from '@/api/modules/ai'
import { listUserAnnouncements, type AnnouncementVO } from '@/api/modules/announcements'
import MainTopBar from '@/components/MainTopBar.vue'
import ThreeSectionPage from '@/components/ThreeSectionPage.vue'
import { saveAiDemandDraft } from '@/utils/aiDraft'

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

const loading = ref(false)
const aiRows = ref<AiAnalysisRecord[]>([])
const announcements = ref<AnnouncementVO[]>([])

function onOpenAi() {
  router.push('/ai-assistant')
}

function onChangeCommunity() {
  router.push('/join-community')
}

function fmtTime(v?: string) {
  if (!v) return '刚刚'
  return v.replace('T', ' ').slice(5, 16)
}

function parseDraft(row: AiAnalysisRecord) {
  try {
    const parsed = JSON.parse(String(row.resultJson || '{}'))
    return parsed?.orderDraft || null
  }
  catch {
    return null
  }
}

async function loadData() {
  loading.value = true
  try {
    const [aiRes, annRes] = await Promise.all([
      getMyAiRecords(1, 6),
      listUserAnnouncements(1, 6),
    ])
    aiRows.value = (aiRes.data?.records || []).filter(x => x.resultMode === 'DEMAND_DRAFT')
    announcements.value = annRes.data?.records || []
  }
  finally {
    loading.value = false
  }
}

async function continueDraft(row: AiAnalysisRecord) {
  const draft = parseDraft(row)
  if (!draft) {
    router.push('/ai-assistant')
    return
  }
  saveAiDemandDraft({
    analysisRecordId: row.id,
    inputText: row.inputText,
    draft,
  })
  try {
    await markAiRecordApplied(row.id)
  }
  catch {}
  router.push('/hall-publish')
}

function openAnnouncement(item: AnnouncementVO) {
  router.push({ path: '/notices', query: { id: String(item.id) } })
}

onMounted(loadData)
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

      <section class="section">
        <div class="section-title">
          <h3>AI 助手提醒</h3>
          <span @click="router.push('/ai-assistant')">去对话</span>
        </div>
        <article
          v-for="item in aiRows"
          :key="`ai-${item.id}`"
          class="notice-card clickable"
          @click="continueDraft(item)"
        >
          <span class="notice-icon accent-ai">
            <FmIcon name="mdi:robot-outline" />
          </span>
          <span class="notice-main">
            <b>草稿已生成</b>
            <small>{{ item.inputText || '有一条可继续填写的求助草稿' }}</small>
          </span>
          <time>{{ fmtTime(item.createdAt) }}</time>
        </article>
        <div v-if="!loading && !aiRows.length" class="empty-hint">
          还没有新的 AI 提醒
        </div>
      </section>

      <section class="section">
        <div class="section-title">
          <h3>社区公告</h3>
          <span @click="router.push('/notices')">查看全部</span>
        </div>
        <article
          v-for="item in announcements"
          :key="`ann-${item.id}`"
          class="notice-card clickable"
          @click="openAnnouncement(item)"
        >
          <span class="notice-icon accent-notice">
            <FmIcon name="mdi:bullhorn-outline" />
          </span>
          <span class="notice-main">
            <b>{{ item.title }}</b>
            <small>{{ item.publisherName || '社区发布' }}</small>
          </span>
          <time>{{ fmtTime(item.publishedAt || item.createdAt) }}</time>
        </article>
        <div v-if="!loading && !announcements.length" class="empty-hint">
          当前没有新的公告
        </div>
      </section>

      <section class="section">
        <div class="section-title">
          <h3>最近会话</h3>
          <span class="section-note">演示</span>
        </div>
        <article class="chat-card">
          <img src="https://picsum.photos/seed/chat-a/120/120" alt="社区管家">
          <span class="chat-main">
            <b>社区管家</b>
            <small>私信功能本轮不做，这里保留展示位。</small>
          </span>
          <time>演示</time>
        </article>
        <article class="chat-card">
          <img src="https://picsum.photos/seed/chat-b/120/120" alt="邻里互助">
          <span class="chat-main">
            <b>邻里互助</b>
            <small>接单、完成、评价消息已经并入真实业务流。</small>
          </span>
          <time>演示</time>
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

.section {
  display: grid;
  gap: 8px;
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

.clickable {
  cursor: pointer;
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
  color: #334155;
}

.notice-main {
  min-width: 0;
  display: grid;
  gap: 4px;
}

.notice-main b {
  font-size: 14px;
  color: #111827;
}

.notice-main small {
  color: #64748b;
  font-size: 12px;
  line-height: 1.45;
}

.notice-card time,
.chat-card time {
  font-size: 11px;
  color: #94a3b8;
  white-space: nowrap;
}

.chat-card {
  padding: 12px;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
}

.chat-card img {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  object-fit: cover;
}

.chat-main {
  min-width: 0;
  display: grid;
  gap: 4px;
}

.chat-main b {
  font-size: 14px;
  color: #111827;
}

.chat-main small {
  font-size: 12px;
  line-height: 1.45;
  color: #64748b;
}

.empty-hint {
  border-radius: 14px;
  padding: 14px 12px;
  background: rgba(255, 255, 255, 0.72);
  color: #94a3b8;
  font-size: 12px;
  text-align: center;
}
</style>
