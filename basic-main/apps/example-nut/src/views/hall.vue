<script setup lang="ts">
import { getMyClaimRecords, getMyPublishHistory, getHallSummary, type ServiceClaimVO } from '@/api/modules/hall'
import { completeClaimService, confirmClaimService, getServiceRequestDetail, type ServiceRequestVO } from '@/api/modules/serviceRequests'

definePage({
  meta: {
    title: '任务',
    auth: true,
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()
const loading = ref(false)
const activeTab = ref<'joined' | 'published'>('joined')
const joinedRows = ref<ServiceClaimVO[]>([])
const publishedRows = ref<ServiceRequestVO[]>([])
const summary = reactive({
  myPublishedCount: 0,
  inProgressCount: 0,
})
const claimDetailVisible = ref(false)
const claimDetailLoading = ref(false)
const completeLoading = ref(false)
const claimDetail = ref<ServiceRequestVO | null>(null)
const selectedClaim = ref<ServiceClaimVO | null>(null)
const selectedPublished = ref<ServiceRequestVO | null>(null)

const name = computed(() => appAuthStore.user?.realName || appAuthStore.user?.username || appAuthStore.account || '社区用户')
const communityText = computed(() => appAuthStore.user?.communityName || '未绑定社区')
const avatarUrl = computed(() => appAuthStore.user?.avatarUrl || '')

function onTakeTask() {
  const raw = String(appAuthStore.user?.skillTags || '').trim()
  let hasSkills = false
  if (raw) {
    try {
      const arr = JSON.parse(raw)
      hasSkills = Array.isArray(arr) && arr.some(x => String(x).trim())
    }
    catch {
      hasSkills = raw.split(',').some(x => x.trim())
    }
  }
  if (!hasSkills) {
    window.alert('请先完善技能信息后再办理“我要帮忙”')
    router.push('/profile-edit')
    return
  }
  router.push('/hall-take')
}

function onPublishRequest() {
  router.push('/hall-publish')
}

function goOverview(kind: 'reviews' | 'stats') {
  router.push({
    path: '/hall-overview',
    query: { kind },
  })
}

function goAiAssistant() {
  router.push('/ai-assistant')
}

function openListTab(tab: 'joined' | 'published') {
  activeTab.value = tab
}

async function withTimeout<T>(promise: Promise<T>, timeoutMs = 4000): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | null = null
  try {
    return await Promise.race([
      promise,
      new Promise<T>((_, reject) => {
        timer = setTimeout(() => reject(new Error('timeout')), timeoutMs)
      }),
    ])
  }
  finally {
    if (timer) clearTimeout(timer)
  }
}

async function loadData() {
  loading.value = true
  try {
    await withTimeout(appAuthStore.hydrateUser(), 1500).catch(() => null)
    const [summaryRet, joinedRet, pubRet] = await Promise.allSettled([
      withTimeout(getHallSummary(), 6000),
      withTimeout(getMyClaimRecords(1, 20), 6000),
      withTimeout(getMyPublishHistory(1, 20), 6000),
    ])
    const summaryRes = summaryRet.status === 'fulfilled' ? summaryRet.value : null
    const joinedRes = joinedRet.status === 'fulfilled' ? joinedRet.value : null
    const pubRes = pubRet.status === 'fulfilled' ? pubRet.value : null

    if (summaryRes?.code === 200 && summaryRes.data) {
      summary.myPublishedCount = Number(summaryRes.data.myPublishedCount || 0)
      summary.inProgressCount = Number(summaryRes.data.inProgressCount || 0)
    }
    const joinedList = joinedRes?.code === 200 ? (joinedRes.data?.records || []) : []
    joinedRows.value = joinedList.filter((x: any) => [1, 4].includes(Number(x?.claimStatus)))
    publishedRows.value = pubRes?.code === 200 ? (pubRes.data?.records || []) : []
  }
  catch (e: any) {
    // 任务页兜底：任何接口失败都不阻断页面渲染
    joinedRows.value = []
    publishedRows.value = []
    window.console?.warn?.('hall.loadData failed:', e?.message || e)
  }
  finally {
    loading.value = false
  }
}

function fmtTime(v?: string) {
  if (!v) return '暂无时间'
  return v.replace('T', ' ').slice(0, 16)
}

function claimStatusText(v?: number) {
  if (v === 4) return '待确认'
  if (v === 2) return '已完成'
  if (v === 5) return '已申诉'
  return '进行中'
}

function claimStatusClass(v?: number) {
  if (v === 4) return 'state-pending'
  if (v === 2) return 'state-done'
  if (v === 5) return 'state-risk'
  return 'state-going'
}

function requestStatusText(v?: number) {
  if (v === 0) return '待审核'
  if (v === 1) return '已发布'
  if (v === 2) return '进行中'
  if (v === 3) return '已完成'
  if (v === 5) return '待确认'
  if (v === 4) return '已取消'
  return '未知'
}

function requestStatusClass(v?: number) {
  if (v === 3) return 'state-done'
  if (v === 2) return 'state-going'
  if (v === 5) return 'state-pending'
  if (v === 4) return 'state-risk'
  return 'state-pending'
}

function requestStatusCode(v?: number) {
  if (v === 0) return 'CREATED'
  if (v === 1) return 'APPROVED'
  if (v === 2) return 'IN_PROGRESS'
  if (v === 3) return 'COMPLETED'
  if (v === 5) return 'PENDING_CONFIRM'
  if (v === 4) return 'CANCELLED'
  return 'CREATED'
}

function requestStep(v?: number) {
  if (v === 0) return 0
  if (v === 1) return 1
  if (v === 2) return 2
  return 3
}

async function openClaimDetail(row: ServiceClaimVO) {
  if (!row?.requestId) return
  selectedPublished.value = null
  selectedClaim.value = row
  claimDetailVisible.value = true
  claimDetailLoading.value = true
  claimDetail.value = null
  try {
    const res = await getServiceRequestDetail(Number(row.requestId))
    if (res.code !== 200) throw new Error(res.message || '加载详情失败')
    claimDetail.value = res.data
  }
  catch {
    claimDetail.value = null
  }
  finally {
    claimDetailLoading.value = false
  }
}

async function openPublishedDetail(row: ServiceRequestVO) {
  if (!row?.id) return
  selectedPublished.value = row
  selectedClaim.value = null
  claimDetailVisible.value = true
  claimDetailLoading.value = true
  claimDetail.value = null
  try {
    const res = await getServiceRequestDetail(Number(row.id))
    if (res.code !== 200) throw new Error(res.message || '加载详情失败')
    claimDetail.value = res.data
  }
  catch {
    claimDetail.value = null
  }
  finally {
    claimDetailLoading.value = false
  }
}

function onCloseDetailPopup() {
  claimDetailVisible.value = false
  selectedClaim.value = null
  selectedPublished.value = null
}

async function onConfirmCompleteFromDetail() {
  const claimId = Number(selectedPublished.value?.latestClaimId || claimDetail.value?.latestClaimId || 0)
  if (!claimId || completeLoading.value) return
  completeLoading.value = true
  try {
    const res = await confirmClaimService({ claimId })
    if (res.code !== 200) {
      window.alert(res.message || '确认失败')
      return
    }
    window.alert('已确认完成，请进行评价')
    claimDetailVisible.value = false
    await loadData()
    router.push({ path: '/service-evaluate', query: { claimId: String(claimId) } })
  }
  catch (e: any) {
    window.alert(e?.message || '确认失败')
  }
  finally {
    completeLoading.value = false
  }
}

async function onCompleteCurrentClaim() {
  const claim = selectedClaim.value
  if (!claim?.id || Number(claim.claimStatus) !== 1 || completeLoading.value) return
  const hoursInput = window.prompt('请输入服务时长（小时），例如 1.5', '1')
  if (hoursInput == null) return
  const serviceHours = Number(hoursInput)
  if (!Number.isFinite(serviceHours) || serviceHours <= 0) {
    window.alert('服务时长必须大于 0')
    return
  }
  const completionNote = window.prompt('可填写完成说明（选填）', '服务已按约完成') || ''
  completeLoading.value = true
  try {
    const res = await completeClaimService({
      claimId: Number(claim.id),
      serviceHours,
      completionNote,
    })
    if (res.code !== 200) {
      window.alert(res.message || '提交完成失败')
      return
    }
    window.alert('已提交完成，等待需求方确认（24小时无异议自动完成）')
    claimDetailVisible.value = false
    await loadData()
  }
  catch (e: any) {
    window.alert(e?.message || '提交完成失败')
  }
  finally {
    completeLoading.value = false
  }
}

onMounted(loadData)
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="task-page">
      <div class="hero">
        <div class="hero-left">
          <h3>任务中心</h3>
          <p>{{ name }} · {{ communityText }}</p>
        </div>
        <div class="hero-avatar">
          <img v-if="avatarUrl" :src="avatarUrl" alt="avatar">
          <FmIcon v-else name="i-carbon:user-avatar-filled-alt" />
        </div>
      </div>

      <div class="action-grid">
        <button type="button" class="action-card help" @click="onTakeTask">
          <div class="title">我要帮忙</div>
          <div class="sub">我参与办理</div>
        </button>
        <button type="button" class="action-card publish" @click="onPublishRequest">
          <div class="title">我要发布</div>
          <div class="sub">我发布的事项</div>
        </button>
        <button type="button" class="action-card neutral" @click="goOverview('reviews')">
          <div class="title">评价</div>
          <div class="sub">查看办理评价</div>
        </button>
        <button type="button" class="action-card neutral" @click="goOverview('stats')">
          <div class="title">服务统计</div>
          <div class="sub">查看办理进度</div>
        </button>
      </div>
      <button type="button" class="ai-entry" @click="goAiAssistant">
        AI助手：一句话生成需求 + 常见问题问答
      </button>

      <div class="tabs">
        <button :class="{ active: activeTab === 'joined' }" @click="openListTab('joined')">
          我参与的办理（{{ summary.inProgressCount }}）
        </button>
        <button :class="{ active: activeTab === 'published' }" @click="openListTab('published')">
          我发布的事项（{{ summary.myPublishedCount }}）
        </button>
      </div>

      <div v-if="loading" class="status">加载中...</div>
      <div v-else-if="activeTab === 'joined'" class="list">
        <article v-for="r in joinedRows" :key="r.id" class="card card-clickable" @click="openClaimDetail(r)">
          <div class="card-head">
            <h4>{{ r.requestTitle || '服务任务' }}</h4>
            <span class="state-pill" :class="claimStatusClass(r.claimStatus)">{{ claimStatusText(r.claimStatus) }}</span>
          </div>
          <p>{{ r.requestAddress || '本社区' }}</p>
          <small>认领时间：{{ fmtTime(r.claimAt || r.createdAt) }}</small>
        </article>
        <p v-if="joinedRows.length === 0" class="empty">暂无参与中的任务</p>
      </div>
      <div v-else class="list">
        <article v-for="r in publishedRows" :key="r.id" class="card card-clickable" @click="openPublishedDetail(r)">
          <div class="card-head">
            <h4>{{ r.serviceType }}</h4>
            <span class="state-pill" :class="requestStatusClass(r.status)">{{ requestStatusText(r.status) }}</span>
          </div>
          <p>{{ r.serviceAddress || '本社区' }}</p>
          <small>发布时间：{{ fmtTime(r.publishedAt || r.createdAt) }}</small>
        </article>
        <p v-if="publishedRows.length === 0" class="empty">暂无已发布需求</p>
      </div>

      <NutPopup
        v-if="claimDetailVisible"
        v-model:visible="claimDetailVisible"
        position="bottom"
        round
        closeable
        :close-on-click-overlay="true"
        @click-overlay="onCloseDetailPopup"
        class="order-popup"
      >
        <div class="claim-drawer">
          <div class="drawer-handle" />
          <h3>订单详情</h3>
          <div v-if="claimDetailLoading" class="status">加载中...</div>
          <div v-else-if="claimDetail" class="detail-content">
            <div class="status-row">
              <span class="state-code">{{ requestStatusCode(claimDetail.status) }}</span>
              <span class="state-text">{{ requestStatusText(claimDetail.status) }}</span>
            </div>
            <div class="steps">
              <div v-for="(s, idx) in ['发布', '审核', '进行中', '完成']" :key="s" class="step" :class="{ active: idx <= requestStep(claimDetail.status) }">
                <span class="dot">{{ idx + 1 }}</span>
                <span class="txt">{{ s }}</span>
              </div>
            </div>
            <p><b>服务类型：</b>{{ claimDetail.serviceType }}</p>
            <p><b>地址：</b>{{ claimDetail.serviceAddress || '-' }}</p>
            <p><b>需求状态：</b>{{ requestStatusText(claimDetail.status) }}</p>
            <p><b>认领状态：</b>{{ claimStatusText(selectedClaim?.claimStatus || selectedPublished?.latestClaimStatus) }}</p>
            <p><b>认领时间：</b>{{ fmtTime(selectedClaim?.claimAt || selectedClaim?.createdAt) }}</p>
            <p><b>说明：</b>{{ claimDetail.description || '暂无说明' }}</p>
            <NutButton
              v-if="selectedClaim && Number(selectedClaim.claimStatus) === 1"
              block
              type="primary"
              :loading="completeLoading"
              @click="onCompleteCurrentClaim"
            >
              {{ completeLoading ? '提交中...' : '完成服务' }}
            </NutButton>
            <NutButton
              v-else-if="!selectedClaim && (Number(selectedPublished?.latestClaimStatus) === 4 || Number(claimDetail.status) === 5)"
              block
              type="primary"
              :loading="completeLoading"
              @click="onConfirmCompleteFromDetail"
            >
              {{ completeLoading ? '确认中...' : '确认完成' }}
            </NutButton>
          </div>
        </div>
      </NutPopup>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.task-page { min-height: 100%; background: var(--m-color-bg); padding: var(--m-space-page); }
.hero { background: var(--m-color-card); border: 1px solid var(--m-color-border); border-radius: var(--m-radius-card); padding: 12px; box-shadow: var(--m-shadow-card); display: flex; align-items: center; justify-content: space-between; gap: 10px; }
.hero-left { min-width: 0; }
.hero h3 { margin: 0; font-size: var(--m-font-title); font-weight: 800; color: var(--m-color-text); }
.hero p { margin: 4px 0 0; font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.hero-avatar { width: 42px; height: 42px; border-radius: 999px; overflow: hidden; background: #ecfdf5; color: #047857; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; flex-shrink: 0; border: 1px solid #bbf7d0; }
.hero-avatar img { width: 100%; height: 100%; object-fit: cover; display: block; }
.action-grid { margin-top: var(--m-space-block); display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.action-card { border-radius: var(--m-radius-card); padding: 14px; text-align: left; border: 1px solid var(--m-color-border); background: var(--m-color-card); color: var(--m-color-text); box-shadow: var(--m-shadow-card); }
.action-card .title { font-size: 16px; font-weight: 800; }
.action-card .sub { margin-top: 4px; font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.action-card.help { border-left: 4px solid #2f9e63; }
.action-card.publish { border-left: 4px solid #3aa86e; }
.action-card.neutral { border-left: 4px solid #4b5563; }
.ai-entry { margin-top: 10px; width: 100%; border: 1px solid #bbf7d0; background: #f0fdf4; color: #166534; border-radius: var(--m-radius-card); padding: 12px; font-size: 13px; font-weight: 700; text-align: left; }
.tabs { margin-top: 12px; display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.tabs button { border: 1px solid var(--m-color-border); background: var(--m-color-card); border-radius: 10px; padding: 8px; color: var(--m-color-subtext); font-size: var(--m-font-sub); }
.tabs button.active { background: var(--m-color-primary-soft); border-color: var(--m-color-primary); color: var(--m-color-primary); font-weight: 800; }
.status { margin-top: 10px; color: var(--m-color-subtext); font-size: var(--m-font-body); }
.list { margin-top: 10px; display: grid; gap: 8px; }
.card { border-radius: var(--m-radius-card); border: 1px solid var(--m-color-border); background: var(--m-color-card); padding: 10px; box-shadow: var(--m-shadow-card); }
.card-clickable { cursor: pointer; }
.card-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.state-pill { font-size: 10px; font-weight: 700; border-radius: 999px; padding: 3px 8px; }
.state-going { background: #dbeafe; color: #1d4ed8; }
.state-pending { background: #fef3c7; color: #92400e; }
.state-done { background: #dcfce7; color: #166534; }
.state-risk { background: #fee2e2; color: #b91c1c; }
.card h4 { margin: 0; font-size: 14px; color: var(--m-color-text); }
.card p { margin: 6px 0 4px; font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.card small { color: var(--m-color-muted); font-size: 11px; }
.empty { margin: 12px 0; text-align: center; color: var(--m-color-muted); font-size: var(--m-font-sub); }

.claim-drawer { padding: 10px 16px 20px; background: var(--m-color-card); border-top-left-radius: 24px; border-top-right-radius: 24px; }
.order-popup :deep(.nut-popup) {
  width: min(100vw, 430px) !important;
  left: 50% !important;
  right: auto !important;
  transform: translateX(-50%) !important;
}
.order-popup :deep(.nut-popup-content) {
  width: 100% !important;
}
.claim-drawer {
  width: min(100vw, 430px);
  margin: 0 auto;
  box-sizing: border-box;
}
.drawer-handle { width: 42px; height: 4px; border-radius: 4px; background: var(--m-color-border); margin: 0 auto 10px; }
.claim-drawer h3 { margin: 0 0 10px; font-size: 18px; font-weight: 900; }
.detail-content p { margin: 0 0 8px; font-size: 13px; color: var(--m-color-subtext); }
.status-row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.state-code { font-size: 11px; font-weight: 800; color: var(--m-color-primary); background: var(--m-color-primary-soft); border: 1px solid var(--m-color-border); padding: 2px 8px; border-radius: 999px; }
.state-text { font-size: 12px; color: var(--m-color-muted); }
.steps { display: grid; grid-template-columns: repeat(4, 1fr); gap: 6px; margin: 10px 0 12px; }
.step { text-align: center; color: #94a3b8; }
.step .dot { display: inline-flex; width: 22px; height: 22px; align-items: center; justify-content: center; border-radius: 999px; border: 1px solid #cbd5e1; font-size: 11px; font-weight: 700; }
.step .txt { display: block; margin-top: 3px; font-size: 11px; }
.step.active { color: #047857; }
.step.active .dot { background: #10b981; color: #fff; border-color: #10b981; }

</style>

