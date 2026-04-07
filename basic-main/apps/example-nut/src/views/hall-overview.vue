<script setup lang="ts">
import {
  getHallSummary,
  getMyClaimRecords,
  getMyPublishHistory,
  getMyReceivedReviews,
  getMyReviewHistory,
} from '@/api/modules/hall'
import type { ServiceRequestVO } from '@/api/modules/serviceRequests'

definePage({
  meta: {
    title: '服务概览',
    auth: true,
  },
})

const route = useRoute()
const router = useRouter()
const loading = ref(false)
const error = ref('')
/** 列表接口单页条数（与后端分页一致） */
const PAGE_SIZE = 10
const page = reactive({
  current: 1,
  size: PAGE_SIZE,
})
const total = ref(0)
const publishRows = ref<ServiceRequestVO[]>([])
const claimRows = ref<any[]>([])
const reviewMode = ref<'received' | 'history'>('received')
const reviewRows = ref<any[]>([])
const stats = reactive({
  myPublishedCount: 0,
  myCompletedCount: 0,
  inProgressCount: 0,
  receivedEvaluationCount: 0,
  receivedAvgRating: 0,
})

const titleMap: Record<string, string> = {
  'publish-history': '我的发布历史',
  'in-progress': '进行中的单子',
  'reviews': '评价与反馈',
  'stats': '服务统计',
}

const kind = computed(() => (route.query.kind as string) || 'publish-history')
const pageTitle = computed(() => titleMap[kind.value] || '服务概览')
const totalPages = computed(() => Math.max(1, Math.ceil(total.value / page.size)))

function fmtTime(v?: string) {
  if (!v) return '暂无时间'
  return v.replace('T', ' ').slice(0, 16)
}

const FIXED_COMMUNITY = '幸福小区'

/** 拼接地址：固定社区名弱化，门牌略清晰（同小区可见，整体仍不抢眼） */
function addressParts(addr?: string | null) {
  if (!addr?.trim())
    return { community: '', detail: '', fallback: true as const }
  const s = addr.trim()
  if (s.startsWith(FIXED_COMMUNITY))
    return { community: FIXED_COMMUNITY, detail: s.slice(FIXED_COMMUNITY.length), fallback: false as const }
  return { community: '', detail: s, fallback: false as const }
}

/** 与首页需求卡片一致：服务类型标签配色 */
function tagClass(type: string) {
  if (!type) return 'tag-green'
  if (type.includes('陪')) return 'tag-red'
  if (type.includes('买') || type.includes('跑腿')) return 'tag-orange'
  if (type.includes('维修')) return 'tag-blue'
  if (type.includes('教') || type.includes('育')) return 'tag-indigo'
  if (type.includes('助老')) return 'tag-purple'
  return 'tag-green'
}

function publishStatusText(v: number) {
  if (v === 2) return '已完成'
  if (v === 1) return '进行中'
  return '待处理'
}

function publishStatusClass(v: number) {
  if (v === 2) return 'status-done'
  if (v === 1) return 'status-going'
  return 'status-pending'
}

function scoreText(v?: number) {
  const n = Number(v || 0)
  if (n >= 4.5) return '优秀'
  if (n >= 3.5) return '良好'
  if (n > 0) return '合格'
  return '暂无评分'
}

function resetPage() {
  page.current = 1
  total.value = 0
}

function onSwitchReviewMode(mode: 'received' | 'history') {
  reviewMode.value = mode
  resetPage()
  loadData()
}

async function loadData() {
  loading.value = true
  error.value = ''
  publishRows.value = []
  claimRows.value = []
  reviewRows.value = []
  try {
    if (kind.value === 'publish-history') {
      const res = await getMyPublishHistory(page.current, page.size)
      if (res.code !== 200) throw new Error(res.message || '加载失败')
      publishRows.value = res.data.records || []
      total.value = Number(res.data.total || 0)
      return
    }
    if (kind.value === 'in-progress') {
      const res = await getMyClaimRecords(page.current, page.size)
      if (res.code !== 200) throw new Error(res.message || '加载失败')
      const records = (res.data.records || []).filter((item: any) => Number(item.claimStatus) === 1)
      claimRows.value = records
      total.value = Number(res.data.total || records.length)
      return
    }
    if (kind.value === 'reviews') {
      const res = reviewMode.value === 'received'
        ? await getMyReceivedReviews(page.current, page.size)
        : await getMyReviewHistory(page.current, page.size)
      if (res.code !== 200) throw new Error(res.message || '加载失败')
      reviewRows.value = res.data.records || []
      total.value = Number(res.data.total || 0)
      return
    }
    const statRes = await getHallSummary()
    if (statRes.code !== 200) throw new Error(statRes.message || '加载失败')
    stats.myPublishedCount = Number(statRes.data.myPublishedCount || 0)
    stats.myCompletedCount = Number(statRes.data.myCompletedCount || 0)
    stats.inProgressCount = Number(statRes.data.inProgressCount || 0)
    stats.receivedEvaluationCount = Number(statRes.data.receivedEvaluationCount || 0)
    stats.receivedAvgRating = Number(statRes.data.receivedAvgRating || 0)
  }
  catch (e: any) {
    error.value = e?.message || '加载失败'
  }
  finally {
    loading.value = false
  }
}

function onPrev() {
  if (page.current <= 1) return
  page.current -= 1
  loadData()
}

function onNext() {
  if (page.current >= totalPages.value) return
  page.current += 1
  loadData()
}

watch(() => route.query.kind, () => {
  resetPage()
  if (kind.value !== 'reviews') {
    reviewMode.value = 'received'
  }
  loadData()
}, { immediate: true })
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page">
      <header class="top">
        <button class="back" @click="router.back()">
          返回
        </button>
        <h2>{{ pageTitle }}</h2>
      </header>

      <div class="panel">
        <div v-if="kind === 'reviews'" class="switch-row">
          <button :class="{ active: reviewMode === 'received' }" @click="onSwitchReviewMode('received')">
            我收到的评价
          </button>
          <button :class="{ active: reviewMode === 'history' }" @click="onSwitchReviewMode('history')">
            我发出的评价
          </button>
        </div>

        <div v-if="loading" class="status status-bar">
          加载中...
        </div>
        <div v-else-if="error" class="status status-bar error">
          {{ error }}
        </div>

        <div v-else-if="kind === 'stats'" class="stats-grid">
          <div class="stat-item stat-tone-emerald">
            <span class="label">累计发布</span>
            <strong>{{ stats.myPublishedCount }}</strong>
            <small>互助发起活跃度</small>
          </div>
          <div class="stat-item stat-tone-green">
            <span class="label">已完成任务</span>
            <strong>{{ stats.myCompletedCount }}</strong>
            <small>履约表现稳定</small>
          </div>
          <div class="stat-item stat-tone-cyan">
            <span class="label">进行中任务</span>
            <strong>{{ stats.inProgressCount }}</strong>
            <small>当前服务进度</small>
          </div>
          <div class="stat-item stat-tone-lime">
            <span class="label">收到评价</span>
            <strong>{{ stats.receivedEvaluationCount }}</strong>
            <small>社区反馈沉淀</small>
          </div>
          <div class="stat-item stat-tone-amber">
            <span class="label">平均评分</span>
            <strong>{{ stats.receivedAvgRating.toFixed(1) }}</strong>
            <small>服务口碑指数</small>
          </div>
        </div>

        <template v-else>
          <div class="panel-scroll">
            <div v-if="kind === 'publish-history'" class="list publish-list">
              <article v-for="item in publishRows" :key="item.id" class="card publish-card">
                <div class="row-head">
                  <h4>{{ item.serviceType }} · {{ item.serviceAddress }}</h4>
                  <span class="publish-status" :class="publishStatusClass(Number(item.status || 0))">
                    {{ publishStatusText(Number(item.status || 0)) }}
                  </span>
                </div>
                <p>{{ item.description || '暂无描述' }}</p>
                <small>发布时间 {{ fmtTime(item.publishedAt || item.createdAt) }}</small>
              </article>
              <p v-if="publishRows.length === 0" class="empty">暂无发布记录</p>
            </div>

            <div v-else-if="kind === 'in-progress'" class="list in-progress-list">
              <article v-for="item in claimRows" :key="item.id" class="claim-card">
                <div class="claim-card-top">
                  <span class="biz-tag" :class="tagClass(item.requestTitle || '')">{{ item.requestTitle || '服务' }}</span>
                  <span class="claim-pill">进行中</span>
                </div>
                <div class="claim-address-line">
                  <FmIcon name="i-carbon:location" class="claim-address-ico" aria-hidden="true" />
                  <span class="claim-address-txt">
                    <template v-for="p in [addressParts(item.requestAddress)]" :key="item.id">
                      <template v-if="p.fallback">同小区服务地点</template>
                      <template v-else-if="p.community">
                        <span class="claim-comm-prefix">{{ p.community }}</span><span class="claim-comm-detail">{{ p.detail }}</span>
                      </template>
                      <template v-else>{{ p.detail }}</template>
                    </template>
                  </span>
                </div>
                <p class="claim-desc">
                  {{ item.completionNote || '任务进行中，等待服务完成后提交时长。' }}
                </p>
                <div class="claim-foot">
                  <span class="claim-time">
                    <FmIcon name="i-carbon:time" aria-hidden="true" />
                    认领于 {{ fmtTime(item.claimAt || item.createdAt) }}
                  </span>
                </div>
              </article>
              <p v-if="claimRows.length === 0" class="empty in-progress-empty">暂无进行中的任务</p>
            </div>

            <div v-else-if="kind === 'reviews'" class="list review-list">
              <article v-for="item in reviewRows" :key="item.id" class="card review-card">
                <div class="row-head">
                  <h4>
                    {{ item.serviceType || '服务任务' }} · {{ item.serviceAddress || '未知地址' }}
                  </h4>
                  <span class="score-badge">{{ Number(item.rating || 0).toFixed(1) }} ★</span>
                </div>
                <p>{{ item.content || '暂无文字评价' }}</p>
                <small>
                  {{ reviewMode === 'received' ? `评价人 ${item.residentName || '居民用户'}` : `被评人 ${item.volunteerName || '志愿者用户'}` }}
                  · {{ fmtTime(item.createdAt) }}
                </small>
                <div class="score-tip">
                  {{ scoreText(item.rating) }}
                </div>
              </article>
              <p v-if="reviewRows.length === 0" class="empty">暂无评价数据</p>
            </div>
          </div>

          <div class="pager">
            <button :disabled="page.current <= 1" @click="onPrev">
              上一页
            </button>
            <span class="pager-info">第 {{ page.current }} / {{ totalPages }} 页 · 每页 {{ PAGE_SIZE }} 条 · 共 {{ total }} 条</span>
            <button :disabled="page.current >= totalPages" @click="onNext">
              下一页
            </button>
          </div>
        </template>
      </div>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.page {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #f4f6f8;
  padding: 14px;
  box-sizing: border-box;
}
.top { flex-shrink: 0; display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
.back { border: 0; border-radius: 8px; background: #fff; padding: 6px 10px; }
.top h2 { margin: 0; font-size: 18px; font-weight: 900; }
.panel {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 12px;
  color: #4b5563;
  line-height: 1.6;
}
.panel-scroll {
  flex: 1;
  min-height: 0;
  overflow-x: hidden;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}
.switch-row { flex-shrink: 0; display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 10px; }
.status-bar { flex-shrink: 0; }
.switch-row button { border: 1px solid #d1d5db; background: #fff; border-radius: 10px; padding: 8px; color: #4b5563; }
.switch-row button.active { background: #ecfdf5; border-color: #10b981; color: #047857; font-weight: 800; }
.status { color: #6b7280; }
.status.error { color: #dc2626; }
.list { display: grid; gap: 10px; }
.card { border: 1px solid #e5e7eb; border-radius: 10px; padding: 10px; background: #fff; }
.card h4 { margin: 0; color: #111827; font-size: 14px; }
.card p { margin: 6px 0; font-size: 13px; }
.card small { color: #6b7280; }
.row-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }
.empty { color: #9ca3af; text-align: center; margin: 14px 0; }
.publish-list,
.review-list { gap: 12px; }
.publish-card,
.review-card {
  position: relative;
  border-radius: 14px;
  border: 1px solid #dcfce7;
  padding: 12px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.05);
}
.publish-card { background: linear-gradient(160deg, #ffffff 10%, #f0fdf4 94%); }
.review-card { background: linear-gradient(160deg, #ffffff 10%, #ecfeff 94%); border-color: #bae6fd; }
.publish-card::before,
.review-card::before {
  content: '';
  position: absolute;
  right: -26px;
  top: -30px;
  width: 82px;
  height: 82px;
  border-radius: 999px;
}
.publish-card::before { background: rgba(16, 185, 129, 0.14); }
.review-card::before { background: rgba(14, 165, 233, 0.14); }
.publish-status,
.score-badge {
  position: relative;
  z-index: 1;
  flex-shrink: 0;
  font-size: 11px;
  font-weight: 800;
  border-radius: 999px;
  padding: 3px 9px;
}
.publish-status.status-done { background: #dcfce7; color: #166534; }
.publish-status.status-going { background: #dbeafe; color: #1d4ed8; }
.publish-status.status-pending { background: #fef3c7; color: #92400e; }
.score-badge { background: #cffafe; color: #155e75; }
.score-tip {
  margin-top: 8px;
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.7);
  border: 1px solid #e5e7eb;
  padding: 2px 8px;
  font-size: 11px;
  color: #0f766e;
  font-weight: 700;
}

/* —— 进行中的单子：与发布/评价卡片同系渐变 + 左侧强调条 —— */
.in-progress-list { gap: 12px; }
.claim-card {
  position: relative;
  background: linear-gradient(160deg, #ffffff 8%, #ecfdf5 96%);
  border-radius: 14px;
  padding: 14px 14px 12px 16px;
  border: 1px solid #a7f3d0;
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.06);
  overflow: hidden;
}
.claim-card::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 5px;
  border-radius: 14px 0 0 14px;
  background: linear-gradient(180deg, #059669, #10b981, #34d399);
}
.claim-card::after {
  content: '';
  position: absolute;
  right: -28px;
  top: -30px;
  width: 88px;
  height: 88px;
  border-radius: 999px;
  background: rgba(16, 185, 129, 0.14);
  pointer-events: none;
}
.claim-card-top {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 10px;
  padding-left: 2px;
}
.biz-tag {
  font-size: 12px;
  padding: 5px 11px;
  border-radius: 999px;
  font-weight: 800;
  white-space: nowrap;
  letter-spacing: 0.02em;
}
.tag-red { background: #fef2f2; color: #dc2626; }
.tag-orange { background: #fff7ed; color: #ea580c; }
.tag-blue { background: #eff6ff; color: #2563eb; }
.tag-purple { background: #faf5ff; color: #9333ea; }
.tag-indigo { background: #eef2ff; color: #4338ca; }
.tag-green { background: #ecfdf5; color: #059669; }
.claim-pill {
  flex-shrink: 0;
  font-size: 10px;
  font-weight: 800;
  padding: 4px 9px;
  border-radius: 999px;
  color: #fff;
  background: linear-gradient(135deg, #059669, #10b981);
  box-shadow: 0 2px 6px rgba(16, 185, 129, 0.25);
}
.claim-address-line {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: flex-start;
  gap: 6px;
  margin-bottom: 10px;
  padding-left: 2px;
}
.claim-address-ico {
  flex-shrink: 0;
  font-size: 14px;
  color: #cbd5e1;
  margin-top: 1px;
}
.claim-address-txt {
  font-size: 12px;
  line-height: 1.45;
  color: #94a3b8;
  font-weight: 500;
  word-break: break-all;
}
.claim-comm-prefix {
  font-size: 11px;
  font-weight: 500;
  color: #cbd5e1;
  margin-right: 1px;
}
.claim-comm-detail {
  font-size: 12px;
  color: #94a3b8;
  font-weight: 500;
}
.claim-desc {
  position: relative;
  z-index: 1;
  margin: 0 0 12px;
  padding-left: 2px;
  font-size: 13px;
  line-height: 1.55;
  color: #64748b;
}
.claim-foot {
  position: relative;
  z-index: 1;
  padding-left: 2px;
  padding-top: 2px;
  border-top: 1px dashed #e2e8f0;
}
.claim-time {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #9ca3af;
}
.claim-time :deep(svg) {
  font-size: 13px;
  opacity: 0.85;
}
.in-progress-empty {
  padding: 28px 12px;
  font-size: 13px;
}
.pager {
  flex-shrink: 0;
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 6px;
  align-items: center;
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid #f1f5f9;
}
.pager-info {
  font-size: 10px;
  color: #6b7280;
  text-align: center;
  line-height: 1.35;
  min-width: 0;
}
.pager button { border: 1px solid #d1d5db; background: #fff; border-radius: 8px; padding: 6px 10px; font-size: 13px; }
.pager button:disabled { opacity: .45; }
.stats-grid { flex-shrink: 0; display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }
.stat-item {
  position: relative;
  border: 1px solid #d1fae5;
  border-radius: 14px;
  padding: 12px 12px 10px;
  background: linear-gradient(160deg, #ffffff 10%, #f0fdf4 92%);
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.05);
}
.stat-item::before {
  content: '';
  position: absolute;
  right: -30px;
  top: -32px;
  width: 86px;
  height: 86px;
  border-radius: 999px;
  background: rgba(16, 185, 129, 0.15);
}
.stat-item .label {
  position: relative;
  z-index: 1;
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.66);
  color: #065f46;
  font-size: 12px;
  font-weight: 700;
}
.stat-item strong {
  position: relative;
  z-index: 1;
  display: block;
  margin-top: 8px;
  color: #064e3b;
  font-size: 24px;
  line-height: 1.05;
}
.stat-item small {
  position: relative;
  z-index: 1;
  display: block;
  margin-top: 6px;
  color: #059669;
  font-size: 11px;
  font-weight: 600;
}
.stat-tone-emerald { background: linear-gradient(160deg, #ffffff 12%, #ecfdf5 95%); border-color: #bbf7d0; }
.stat-tone-green { background: linear-gradient(160deg, #ffffff 12%, #f0fdf4 95%); border-color: #dcfce7; }
.stat-tone-cyan { background: linear-gradient(160deg, #ffffff 12%, #ecfeff 95%); border-color: #a5f3fc; }
.stat-tone-lime { background: linear-gradient(160deg, #ffffff 12%, #f7fee7 95%); border-color: #d9f99d; }
.stat-tone-amber { background: linear-gradient(160deg, #ffffff 12%, #fffbeb 95%); border-color: #fde68a; }
.stat-tone-cyan::before { background: rgba(6, 182, 212, 0.14); }
.stat-tone-lime::before { background: rgba(132, 204, 22, 0.14); }
.stat-tone-amber::before { background: rgba(245, 158, 11, 0.16); }

:global(.dark) .page { background: #111827; }
:global(.dark) .back,
:global(.dark) .panel,
:global(.dark) .card,
:global(.dark) .switch-row button,
:global(.dark) .pager button,
:global(.dark) .stat-item { background: #1f2937; border-color: #374151; color: #d1d5db; }
:global(.dark) .top h2,
:global(.dark) .card h4,
:global(.dark) .stat-item strong { color: #f3f4f6; }
:global(.dark) .claim-card {
  background: linear-gradient(160deg, #0f172a 8%, #052e26 96%);
  border-color: #14532d;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
}
:global(.dark) .claim-card::before {
  background: linear-gradient(180deg, #059669, #10b981, #34d399);
}
:global(.dark) .claim-card::after {
  background: rgba(16, 185, 129, 0.12);
  opacity: 0.9;
}
:global(.dark) .tag-red { background: rgba(220, 38, 38, 0.15); color: #fca5a5; }
:global(.dark) .tag-orange { background: rgba(234, 88, 12, 0.15); color: #fdba74; }
:global(.dark) .tag-blue { background: rgba(37, 99, 235, 0.15); color: #93c5fd; }
:global(.dark) .tag-purple { background: rgba(147, 51, 234, 0.15); color: #d8b4fe; }
:global(.dark) .tag-indigo { background: rgba(67, 56, 202, 0.2); color: #a5b4fc; }
:global(.dark) .tag-green { background: rgba(5, 150, 105, 0.2); color: #6ee7b7; }
:global(.dark) .claim-address-txt { color: #64748b; }
:global(.dark) .claim-comm-prefix { color: #475569; }
:global(.dark) .claim-comm-detail { color: #64748b; }
:global(.dark) .claim-desc { color: #9ca3af; }
:global(.dark) .claim-foot { border-top-color: #374151; }
:global(.dark) .claim-time { color: #6b7280; }
:global(.dark) .claim-address-ico { color: #475569; }
:global(.dark) .card small,
:global(.dark) .status,
:global(.dark) .stat-item .label,
:global(.dark) .empty { color: #9ca3af; }
:global(.dark) .switch-row button.active { background: #065f46; border-color: #10b981; color: #ecfdf5; }
:global(.dark) .pager { border-top-color: #374151; }
:global(.dark) .pager-info { color: #9ca3af; }
:global(.dark) .stat-item small { color: #6b7280; }
::global(.dark) .stat-item {
  border-color: #374151;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
}
::global(.dark) .stat-item::before { opacity: .6; }
::global(.dark) .stat-tone-emerald { background: linear-gradient(160deg, #0f172a 12%, #052e26 95%); }
::global(.dark) .stat-tone-green { background: linear-gradient(160deg, #0f172a 12%, #112b21 95%); }
::global(.dark) .stat-tone-cyan { background: linear-gradient(160deg, #0f172a 12%, #082f39 95%); }
::global(.dark) .stat-tone-lime { background: linear-gradient(160deg, #0f172a 12%, #1f2f13 95%); }
::global(.dark) .stat-tone-amber { background: linear-gradient(160deg, #0f172a 12%, #3b2b11 95%); }
::global(.dark) .stat-item .label {
  background: rgba(2, 6, 23, 0.5);
  color: #d1fae5;
}
::global(.dark) .stat-item small { color: #86efac; }
::global(.dark) .publish-card {
  background: linear-gradient(160deg, #0f172a 12%, #052e26 95%);
  border-color: #14532d;
}
::global(.dark) .review-card {
  background: linear-gradient(160deg, #0f172a 12%, #082f39 95%);
  border-color: #164e63;
}
::global(.dark) .publish-status.status-done { background: rgba(34, 197, 94, 0.2); color: #86efac; }
::global(.dark) .publish-status.status-going { background: rgba(59, 130, 246, 0.2); color: #93c5fd; }
::global(.dark) .publish-status.status-pending { background: rgba(245, 158, 11, 0.2); color: #fcd34d; }
::global(.dark) .score-badge { background: rgba(6, 182, 212, 0.2); color: #67e8f9; }
::global(.dark) .score-tip {
  background: rgba(2, 6, 23, 0.45);
  border-color: #334155;
  color: #a7f3d0;
}
</style>

