<script setup lang="ts">
import eventBus from '@/utils/eventBus'
import { getUserDashboardSummary } from '@/api/modules/userDashboard'

definePage({
  meta: {
    title: '个人中心',
    auth: true,
  },
})

const appAuthStore = useAppAuthStore()
const showSettings = ref(false)
const showMedalModal = ref(false)
const selectedMedal = ref<{
  title: string
  icon: string
  acquired: boolean
  desc: string
} | null>(null)
const router = useRouter()

const dashboard = ref<{
  panelType?: 'RESIDENT' | 'VOLUNTEER'
  resident?: { requestStatusCounts?: Record<string, number>; evaluationsGivenCount?: number }
  volunteer?: {
    totalServiceHours?: number | string | null
    averageRating?: number | string | null
    evaluationCount?: number
    creditScore?: number | string | null
    avgRating30d?: number | string | null
    completionRate30d?: number | string | null
    honorNote?: string
  }
} | null>(null)

const name = computed(() => appAuthStore.user?.realName || appAuthStore.user?.username || appAuthStore.account || '邻里用户')
/** sys_region.name，由后端根据 community_id 关联查询 */
const locationText = computed(() => appAuthStore.user?.communityName || '未绑定社区')
/** sys_user.points */
const creditScore = computed(() => Number(appAuthStore.user?.points ?? 0))

const rankText = computed(() => {
  const v = dashboard.value?.volunteer
  if (v?.averageRating != null && v.averageRating !== '') {
    const n = Number(v.averageRating)
    if (!Number.isNaN(n))
      return `均分 ${n.toFixed(1)} · 收到 ${v.evaluationCount ?? 0} 条`
  }
  if (dashboard.value?.panelType === 'RESIDENT') {
    const n = dashboard.value?.resident?.evaluationsGivenCount ?? 0
    return `已评价 ${n} 次`
  }
  return '—'
})

const totalHours = computed(() => {
  if (dashboard.value?.panelType === 'VOLUNTEER') {
    const h = dashboard.value.volunteer?.totalServiceHours
    if (h == null || h === '')
      return '0.00'
    return Number(h).toFixed(2)
  }
  /** 居民端看板暂无「作为志愿者」累计时长，显示占位 */
  return '—'
})

const totalHoursText = computed(() => {
  if (totalHours.value === '—')
    return '—'
  return `${totalHours.value} 小时`
})

const completionRateText = computed(() => {
  const rate = Number(dashboard.value?.volunteer?.completionRate30d ?? 0)
  if (Number.isNaN(rate)) return '0%'
  return `${(rate * 100).toFixed(0)}%`
})

const volunteerCredit = computed(() => {
  const v = dashboard.value?.volunteer?.creditScore
  const n = Number(v ?? 0)
  return Number.isNaN(n) ? 0 : n.toFixed(1)
})

const medals = [
  { title: '核心支柱', icon: 'mdi:medal-outline', acquired: true, className: 'active-yellow', desc: '近30天完成服务任务达到 10 单，并保持平均评分不低于 4.5。' },
  { title: '初露头角', icon: 'mdi:leaf', acquired: true, className: 'active-green', desc: '首次完成服务任务后自动获得，用于标识新手志愿者成长阶段。' },
  { title: '热心邻里', icon: 'mdi:heart-outline', acquired: true, className: 'active-blue', desc: '累计收到 5 条以上正向评价，且最近一次评价不低于 4 分。' },
  { title: '社区先锋', icon: 'mdi:shield-star-outline', acquired: false, className: '', desc: '在同一社区连续 3 周保持活跃服务，并参与至少 1 次紧急需求。' },
] as const

function onOpenMedal(medal: typeof medals[number]) {
  selectedMedal.value = {
    title: medal.title,
    icon: medal.icon,
    acquired: medal.acquired,
    desc: medal.desc,
  }
  showMedalModal.value = true
}

function onGotoTask() {
  router.push({ path: '/hall-overview', query: { kind: 'in-progress' } })
}

function onGotoMall() {
  router.push('/mall-404')
}

async function loadProfile() {
  await appAuthStore.hydrateUser()
  try {
    const res = await getUserDashboardSummary()
    if (res.code === 200 && res.data)
      dashboard.value = res.data
  }
  catch {
    dashboard.value = null
  }
}

onMounted(loadProfile)
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="profile-page">
      <div class="top-header">
        <h2>个人中心</h2>
        <button class="setting-btn" @click="showSettings = true">
          <FmIcon name="mdi:cog-outline" />
        </button>
      </div>

      <section class="bank-card">
        <div class="card-top">
          <div>
            <p class="small-label">账户信息</p>
            <h2>{{ name }}</h2>
            <p class="card-user">{{ locationText }}</p>
          </div>
          <div class="credit-badge">
            <FmIcon name="i-carbon:shield" />
            <span>信用分 {{ creditScore }}</span>
          </div>
        </div>
      </section>

      <section class="func-grid">
        <div class="func-item" role="button" tabindex="0" @click="onGotoTask">
          <div class="func-icon bg-orange"><FmIcon name="mdi:clipboard-list-outline" /></div>
          <span>我的任务</span>
        </div>
        <div class="func-item" role="button" tabindex="0" @click="router.push('/profile-edit')">
          <div class="func-icon bg-blue"><FmIcon name="mdi:account-edit-outline" /></div>
          <span>完善资料</span>
        </div>
        <div class="func-item">
          <div class="func-icon bg-purple"><FmIcon name="mdi:certificate-outline" /></div>
          <span>时长证明</span>
          <small>{{ totalHoursText }}</small>
        </div>
        <div class="func-item" role="button" tabindex="0" @click="onGotoMall">
          <div class="func-icon bg-green"><FmIcon name="mdi:storefront-outline" /></div>
          <span>积分商城</span>
        </div>
      </section>

      <section class="metric-card">
        <div class="metric-item">
          <span>志愿时长</span>
          <b>{{ totalHoursText }}</b>
        </div>
        <div class="metric-item">
          <span>完成率</span>
          <b>{{ completionRateText }}</b>
        </div>
        <div class="metric-item">
          <span>信用分</span>
          <b>{{ volunteerCredit }}</b>
        </div>
        <div class="metric-item metric-wide">
          <span>服务评价</span>
          <b>{{ rankText }}</b>
        </div>
      </section>

      <section class="medal-panel">
        <h3>我的荣誉勋章</h3>
        <div class="medal-row">
          <div
            v-for="m in medals"
            :key="m.title"
            class="medal"
            :class="m.className"
            role="button"
            tabindex="0"
            @click="onOpenMedal(m)"
          >
            <FmIcon :name="m.icon" />
            <span>{{ m.title }}</span>
          </div>
        </div>
      </section>
    </div>

    <NutPopup v-model:visible="showSettings" position="bottom" round class="settings-popup">
      <div class="settings-drawer">
        <div class="drawer-handle" />
        <h3>设置</h3>
        <button class="setting-item" @click="showSettings = false; eventBus.emit('global-app-setting-toggle')">
          <FmIcon name="mdi:tune-variant" />
          <span>应用配置</span>
        </button>
        <button class="setting-item danger" @click="appAuthStore.logout()">
          <FmIcon name="mdi:logout" />
          <span>退出登录</span>
        </button>
      </div>
    </NutPopup>

    <NutPopup
      v-model:visible="showMedalModal"
      position="center"
      round
      closeable
      :close-on-click-overlay="true"
      :style="{ width: 'min(88vw, 360px)' }"
    >
      <div v-if="selectedMedal" class="medal-modal">
        <div class="medal-modal-head">
          <FmIcon :name="selectedMedal.icon" />
          <h4>{{ selectedMedal.title }}</h4>
        </div>
        <p class="medal-modal-status" :class="selectedMedal.acquired ? 'acquired' : 'not-yet'">
          {{ selectedMedal.acquired ? '已获得' : '未获得' }}
        </p>
        <p class="medal-modal-desc">
          {{ selectedMedal.desc }}
        </p>
      </div>
    </NutPopup>
  </AppPageLayout>
</template>

<style scoped>
.profile-page { padding: var(--m-space-page); background: var(--m-color-bg); min-height: 100%; display: grid; gap: 12px; align-content: start; }
.top-header { display: flex; align-items: center; justify-content: space-between; }
.top-header h2 { margin: 0; font-size: 20px; font-weight: 800; color: var(--m-color-text); }
.setting-btn { width: 34px; height: 34px; border: 1px solid var(--m-color-border); border-radius: 999px; background: var(--m-color-card); color: var(--m-color-subtext); font-size: 22px; display: inline-flex; align-items: center; justify-content: center; }
.bank-card { background: var(--m-color-card); border-radius: var(--m-radius-card); padding: 14px; color: var(--m-color-text); position: relative; overflow: hidden; border: 1px solid var(--m-color-border); box-shadow: var(--m-shadow-card); }
.card-top { display: flex; justify-content: space-between; align-items: flex-start; }
.small-label { margin: 0; font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.bank-card h2 { margin: 2px 0 0; font-size: 20px; line-height: 1.2; font-weight: 800; color: var(--m-color-text); }
.credit-badge { display: inline-flex; gap: 4px; align-items: center; background: var(--m-color-primary-soft); color: var(--m-color-primary); border-radius: 10px; padding: 6px 10px; font-size: 12px; font-weight: 700; border: 1px solid var(--m-color-border); }
.card-user { margin-top: 8px; font-size: var(--m-font-sub); color: var(--m-color-muted); }

.func-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
.func-item { display: flex; flex-direction: column; align-items: center; gap: 4px; font-size: 11px; color: var(--m-color-subtext); }
.func-icon { width: 46px; height: 46px; border-radius: 12px; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; border: 1px solid var(--m-color-border); background: var(--m-color-card); color: var(--m-color-primary); }
.bg-orange, .bg-blue, .bg-purple, .bg-green { background: var(--m-color-card); color: var(--m-color-primary); }
.func-item small { font-size: 10px; color: var(--m-color-subtext); }

.metric-card {
  border-radius: 12px;
  border: 1px solid var(--m-color-border);
  background: var(--m-color-card);
  padding: 12px;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  box-shadow: 0 1px 4px rgba(15, 23, 42, .03);
}
.metric-item { text-align: center; }
.metric-item span { display: block; font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.metric-item b { display: block; margin-top: 4px; font-size: 16px; color: var(--m-color-text); }
.metric-wide { grid-column: 1 / -1; text-align: left; border-top: 1px dashed var(--m-color-border); margin-top: 4px; padding-top: 8px; }

.medal-panel { background: var(--m-color-card); border: 1px solid var(--m-color-border); border-radius: var(--m-radius-card); padding: 12px; box-shadow: var(--m-shadow-card); }
.medal-panel h3 { margin: 0 0 10px; font-size: 15px; font-weight: 900; }
.medal-row { display: flex; gap: 10px; overflow-x: auto; }
.medal { width: 68px; height: 68px; border-radius: 999px; border: 2px solid #e5e7eb; flex-shrink: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #9ca3af; font-size: 9px; font-weight: 700; background: transparent; }
.medal :deep(svg) { font-size: 22px; margin-bottom: 2px; }
.active-yellow { border-color: #facc15; color: #ca8a04; }
.active-green { border-color: #4ade80; color: #16a34a; }
.active-blue { border-color: #60a5fa; color: #2563eb; }

.medal-modal { padding: 16px; background: var(--m-color-card); border-radius: 16px; }
.medal-modal-head { display: flex; align-items: center; gap: 8px; }
.medal-modal-head :deep(svg) { font-size: 22px; color: #f59e0b; }
.medal-modal-head h4 { margin: 0; font-size: 16px; font-weight: 900; color: var(--m-color-text); }
.medal-modal-status { margin: 12px 0 8px; font-size: 13px; font-weight: 800; }
.medal-modal-status.acquired { color: #16a34a; }
.medal-modal-status.not-yet { color: #9ca3af; }
.medal-modal-desc { margin: 0; line-height: 1.7; font-size: 13px; color: var(--m-color-subtext); white-space: pre-wrap; }

.settings-drawer { padding: 10px 16px 20px; background: var(--m-color-card); border-top-left-radius: 24px; border-top-right-radius: 24px; }
.settings-drawer {
  width: min(100vw, 430px);
  margin: 0 auto;
  box-sizing: border-box;
}
.settings-popup :deep(.nut-popup) {
  width: min(100vw, 430px) !important;
  left: 50% !important;
  right: auto !important;
  transform: translateX(-50%) !important;
}
.settings-popup :deep(.nut-popup-content) {
  width: 100% !important;
}
.drawer-handle { width: 42px; height: 4px; border-radius: 4px; background: var(--m-color-border); margin: 0 auto 10px; }
.settings-drawer h3 { margin: 0 0 10px; font-size: 18px; font-weight: 900; }
.setting-item { width: 100%; border: 1px solid var(--m-color-border); background: var(--m-color-card); color: var(--m-color-text); border-radius: 12px; padding: 12px; display: inline-flex; align-items: center; justify-content: center; gap: 8px; font-weight: 800; margin-bottom: 8px; }
.setting-item.danger { border-color: #fee2e2; background: #fff1f2; color: #be123c; margin-bottom: 0; }

:global(.dark) .profile-page { background: #111827; }
:global(.dark) .top-header h2 { color: #f3f4f6; }
:global(.dark) .setting-btn { background: #1f2937; color: #d1d5db; }
:global(.dark) .func-item { color: #d1d5db; }
:global(.dark) .func-item small { color: #9ca3af; }
:global(.dark) .metric-card { background: #1f2937; border-color: #374151; }
:global(.dark) .metric-item span { color: #9ca3af; }
:global(.dark) .metric-item b { color: #f3f4f6; }
:global(.dark) .medal-panel h3 { color: #f3f4f6; }
:global(.dark) .medal { border-color: #374151; color: #9ca3af; }
:global(.dark) .settings-drawer { background: #1f2937; }
:global(.dark) .settings-drawer h3 { color: #f3f4f6; }
:global(.dark) .setting-item { background: #111827; border-color: #374151; color: #e5e7eb; }
:global(.dark) .medal-modal { background: #1f2937; }
:global(.dark) .medal-modal-head h4 { color: #f3f4f6; }
:global(.dark) .medal-modal-desc { color: #cbd5e1; }
</style>
