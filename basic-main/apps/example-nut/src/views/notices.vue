<script setup lang="ts">
import { listUserAnnouncements, type AnnouncementVO } from '@/api/modules/announcements'

definePage({
  meta: {
    title: '社区公告',
    auth: true,
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()

const loading = ref(false)
const error = ref('')
const rows = ref<AnnouncementVO[]>([])

const communityHint = computed(() => appAuthStore.user?.communityName || '未绑定社区')

function fmtTime(v?: string) {
  if (!v) return '—'
  return v.replace('T', ' ').slice(0, 19)
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    await appAuthStore.hydrateUser()
    const res = await listUserAnnouncements(1, 50)
    if (res.code !== 200) throw new Error(res.message || '加载失败')
    rows.value = res.data.records || []
  }
  catch (e: any) {
    error.value = e?.message || '加载失败'
    rows.value = []
  }
  finally {
    loading.value = false
  }
}

function onBack() {
  router.back()
}

onMounted(load)
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="notice-page">
      <header class="top">
        <button class="back-btn" @click="onBack">
          <FmIcon name="i-carbon:arrow-left" />
        </button>
        <h2>社区公告</h2>
      </header>

      <p class="sub-hint">
        当前账户：{{ communityHint }} · 展示全体公告与推送至您所在社区的公告
      </p>

      <div v-if="loading" class="status">
        加载中...
      </div>
      <div v-else-if="error" class="status err">
        {{ error }}
      </div>
      <div v-else class="list">
        <article v-for="n in rows" :key="n.id" class="item">
          <div class="dot" />
          <div class="content">
            <div class="title">
              {{ n.title }}
            </div>
            <div class="meta">
              {{ fmtTime(n.publishedAt || n.createdAt) }}
              <span v-if="n.publisherName"> · {{ n.publisherName }}</span>
            </div>
          </div>
        </article>
        <p v-if="rows.length === 0" class="empty">
          暂无公告。请管理员在后台发布（状态需为「已发布」）。
        </p>
      </div>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.notice-page { height: 100%; background: #f4f6f8; padding: 10px 12px; }
.top { display: flex; align-items: center; gap: 10px; padding: 6px 0 10px; }
.back-btn { border: 0; background: #fff; width: 34px; height: 34px; border-radius: 999px; display: inline-flex; align-items: center; justify-content: center; }
.top h2 { margin: 0; font-size: 18px; font-weight: 900; }
.sub-hint { margin: 0 0 10px; font-size: 12px; color: #6b7280; line-height: 1.4; }
.status { color: #6b7280; font-size: 13px; }
.status.err { color: #dc2626; }
.list { display: grid; gap: 8px; }
.item { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px; display: grid; grid-template-columns: 8px 1fr; gap: 10px; }
.dot { width: 6px; height: 6px; border-radius: 999px; margin-top: 6px; background: #10b981; }
.content { min-width: 0; }
.title { font-size: 14px; color: #111827; font-weight: 700; }
.meta { margin-top: 6px; font-size: 12px; color: #9ca3af; }
.empty { text-align: center; color: #9ca3af; font-size: 13px; margin: 24px 8px; }

:global(.dark) .notice-page { background: #111827; }
:global(.dark) .back-btn,
:global(.dark) .item { background: #1f2937; border-color: #374151; }
:global(.dark) .top h2,
:global(.dark) .title { color: #f3f4f6; }
:global(.dark) .sub-hint,
:global(.dark) .status,
:global(.dark) .meta,
:global(.dark) .empty { color: #9ca3af; }
:global(.dark) .status.err { color: #f87171; }
</style>
