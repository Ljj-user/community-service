<script setup lang="ts">
import { getHallSummary } from '@/api/modules/hall'

definePage({
  meta: {
    title: '大厅',
    auth: true,
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()
const summary = reactive({
  myPublishedCount: 0,
  myCompletedCount: 0,
  inProgressCount: 0,
  receivedEvaluationCount: 0,
  receivedAvgRating: 0,
})

const name = computed(() => appAuthStore.user?.realName || appAuthStore.user?.username || appAuthStore.account || '社区用户')
const communityText = computed(() => appAuthStore.user?.communityName || '未绑定社区')

function onPublishRequest() {
  router.push('/hall-publish')
}

function onTakeTask() {
  router.push('/hall-take')
}

function goOverview(kind: string) {
  router.push({
    path: '/hall-overview',
    query: { kind },
  })
}

function onStatTap(ev: Event) {
  const el = ev.currentTarget as HTMLElement
  el.classList.remove('stat-mini--pop')
  void el.offsetWidth
  el.classList.add('stat-mini--pop')
}

function onStatKeydown(ev: KeyboardEvent) {
  if (ev.key !== 'Enter' && ev.key !== ' ')
    return
  ev.preventDefault()
  onStatTap(ev)
}

function onStatAnimEnd(ev: AnimationEvent) {
  if (!ev.animationName.includes('stat-pop'))
    return
  ;(ev.currentTarget as HTMLElement).classList.remove('stat-mini--pop')
}

onMounted(() => {
  appAuthStore.hydrateUser()
  getHallSummary().then((res) => {
    if (res.code === 200 && res.data) {
      summary.myPublishedCount = Number(res.data.myPublishedCount || 0)
      summary.myCompletedCount = Number(res.data.myCompletedCount || 0)
      summary.inProgressCount = Number(res.data.inProgressCount || 0)
      summary.receivedEvaluationCount = Number(res.data.receivedEvaluationCount || 0)
      summary.receivedAvgRating = Number(res.data.receivedAvgRating || 0)
    }
  }).catch(() => {})
})
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="hall-page">
      <div class="hero-info-card">
        <div class="hero-main">
          <div class="ph-title">
            社区服务大厅
          </div>
          <div class="ph-sub">
            {{ name }} · {{ communityText }}
          </div>
        </div>
        <div class="hero-stats" role="group" aria-label="服务数据">
          <div
            class="stat-mini stat-done"
            tabindex="0"
            role="group"
            aria-label="已完成任务数量"
            @click="onStatTap"
            @keydown="onStatKeydown"
            @animationend="onStatAnimEnd"
          >
            <span class="stat-mini-label">已完成</span>
            <span class="stat-mini-value">{{ summary.myCompletedCount }}</span>
            <span class="stat-mini-hint">任务数</span>
          </div>
          <div
            class="stat-mini stat-published"
            tabindex="0"
            role="group"
            aria-label="已发布需求数量"
            @click="onStatTap"
            @keydown="onStatKeydown"
            @animationend="onStatAnimEnd"
          >
            <span class="stat-mini-label">已发布</span>
            <span class="stat-mini-value">{{ summary.myPublishedCount }}</span>
            <span class="stat-mini-hint">需求数</span>
          </div>
        </div>
      </div>

      <div class="feature-grid">
        <button class="feature-card publish" @click="onPublishRequest">
          <div class="icon">+</div>
          <div class="f-title">发布需求</div>
          <div class="f-sub">向所在社区发布待协助事项</div>
        </button>
        <button class="feature-card task" @click="onTakeTask">
          <div class="icon">✓</div>
          <div class="f-title">接取任务</div>
          <div class="f-sub">在社区需求中认领可执行任务</div>
        </button>
      </div>

      <section class="my-section">
        <h3>我的服务概览</h3>
        <div class="my-grid">
          <button class="my-card" @click="goOverview('publish-history')">
            <div class="title-row">
              <span>我的发布历史</span>
              <span class="tag">历史</span>
            </div>
            <p>累计 {{ summary.myPublishedCount }} 条，查看我在社区发起过的所有需求。</p>
          </button>
          <button class="my-card" @click="goOverview('in-progress')">
            <div class="title-row">
              <span>进行中的单子</span>
              <span class="tag in-progress">进行中</span>
            </div>
            <p>当前 {{ summary.inProgressCount }} 条，正在服务或等待确认。</p>
          </button>
          <button class="my-card" @click="goOverview('reviews')">
            <div class="title-row">
              <span>评价与反馈</span>
              <span class="tag">评价</span>
            </div>
            <p>已收到 {{ summary.receivedEvaluationCount }} 条评价，平均 {{ summary.receivedAvgRating.toFixed(1) }} 分。</p>
          </button>
          <button class="my-card" @click="goOverview('stats')">
            <div class="title-row">
              <span>服务统计</span>
              <span class="tag">统计</span>
            </div>
            <p>累计时长、完成次数、常见服务类型一览。</p>
          </button>
        </div>
      </section>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.hall-page { min-height: 100%; background: #f4f6f8; padding: 14px; }
.hero-info-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 14px;
  border-radius: 16px;
  background: #fff;
  border: 1px solid #e5e7eb;
}
.hero-main { min-width: 0; flex: 1; }
.ph-title { font-size: 20px; font-weight: 900; color: #111827; line-height: 1.2; }
.ph-sub { margin-top: 5px; color: #374151; font-weight: 700; font-size: 13px; line-height: 1.4; }
.hero-stats { display: flex; flex-direction: column; gap: 6px; flex-shrink: 0; width: 76px; }
.stat-mini {
  border: 0;
  border-radius: 11px;
  padding: 6px 8px;
  text-align: left;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
  user-select: none;
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.1);
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 1px;
  transform-origin: center;
}
.stat-mini:focus-visible {
  outline: 2px solid rgba(99, 102, 241, 0.55);
  outline-offset: 2px;
}
.stat-published:focus-visible {
  outline-color: rgba(16, 185, 129, 0.65);
}
.stat-done {
  background: linear-gradient(145deg, #6366f1 0%, #4f46e5 48%, #4338ca 100%);
  color: #fff;
}
.stat-published {
  background: linear-gradient(145deg, #10b981 0%, #059669 50%, #047857 100%);
  color: #fff;
}
.stat-mini-label { font-size: 10px; font-weight: 700; opacity: 0.92; letter-spacing: 0.02em; }
.stat-mini-value { font-size: 18px; font-weight: 900; line-height: 1.1; font-variant-numeric: tabular-nums; }
.stat-mini-hint { font-size: 9px; opacity: 0.85; font-weight: 600; }

@keyframes stat-pop {
  0% { transform: scale(1); }
  32% { transform: scale(0.9); }
  62% { transform: scale(1.06); }
  100% { transform: scale(1); }
}
.stat-mini.stat-mini--pop {
  animation: stat-pop 0.4s cubic-bezier(0.34, 1.5, 0.55, 1) forwards;
}

.feature-grid { margin-top: 10px; display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }
.feature-card { border: 0; border-radius: 14px; padding: 14px; color: #fff; text-align: left; }
.feature-card .icon { width: 28px; height: 28px; border-radius: 999px; background: rgba(255,255,255,.2); display: inline-flex; align-items: center; justify-content: center; font-weight: 900; }
.feature-card .f-title { margin-top: 10px; font-size: 18px; font-weight: 900; }
.feature-card .f-sub { margin-top: 5px; font-size: 12px; opacity: .95; line-height: 1.4; }
.feature-card.publish { background: linear-gradient(135deg, #10b981, #047857); }
.feature-card.task { background: linear-gradient(135deg, #3b82f6, #1d4ed8); }

.my-section { margin-top: 16px; }
.my-section h3 { margin: 0 0 10px; font-size: 16px; font-weight: 900; color: #111827; }
.my-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }
.my-card { background: #fff; border-radius: 14px; border: 1px solid #e5e7eb; padding: 10px; font-size: 12px; color: #4b5563; }
.my-card { text-align: left; cursor: pointer; }
.title-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px; }
.title-row span:first-child { font-weight: 800; color: #111827; }
.tag { font-size: 10px; padding: 2px 6px; border-radius: 999px; background: #eef2ff; color: #4f46e5; font-weight: 700; }
.tag.in-progress { background: #ecfdf5; color: #047857; }
.my-card p { margin: 0; }

:global(.dark) .hall-page { background: #111827; }
:global(.dark) .hero-info-card {
  background: #1f2937;
  border-color: #374151;
}
:global(.dark) .ph-title,
:global(.dark) .my-section h3 { color: #f3f4f6; }
:global(.dark) .ph-sub { color: #9ca3af; }
:global(.dark) .stat-mini { box-shadow: 0 2px 10px rgba(0, 0, 0, 0.35); }
:global(.dark) .my-card { background: #1f2937; border-color: #374151; color: #9ca3af; }
</style>

