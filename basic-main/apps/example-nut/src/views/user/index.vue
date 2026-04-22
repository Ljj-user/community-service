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
    honorNote?: string
  }
} | null>(null)

const name = computed(() => appAuthStore.user?.realName || appAuthStore.user?.username || appAuthStore.account || '邻里用户')
/** sys_region.name，由后端根据 community_id 关联查询 */
const locationText = computed(() => appAuthStore.user?.communityName || '未绑定社区')
/** sys_user.time_coins */
const timeCoins = computed(() => Number(appAuthStore.user?.timeCoins ?? 0))
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
        <div class="card-bubble" />
        <div class="card-top">
          <div>
            <p class="small-label">贡献积分</p>
            <h2>{{ creditScore }}</h2>
          </div>
          <div class="credit-badge">
            <FmIcon name="i-carbon:shield" />
            <span>信用分 {{ creditScore }}</span>
          </div>
        </div>
        <div class="card-bottom">
          <div>
            <p class="small-label">累计公益时长</p>
            <p class="strong">{{ totalHoursText }}</p>
          </div>
          <div>
            <p class="small-label">服务评价</p>
            <p class="strong">{{ rankText }}</p>
          </div>
        </div>
        <div class="card-user">
          {{ name }} · {{ locationText }}
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

    <NutPopup v-model:visible="showSettings" position="bottom" round>
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
.profile-page { padding: 14px; background: #f3f4f6; min-height: 100%; display: grid; gap: 14px; align-content: start; }
.top-header { display: flex; align-items: center; justify-content: space-between; }
.top-header h2 { margin: 0; font-size: 20px; font-weight: 900; color: #1f2937; }
.setting-btn { width: 34px; height: 34px; border: 0; border-radius: 999px; background: #fff; color: #6b7280; font-size: 22px; display: inline-flex; align-items: center; justify-content: center; }
.bank-card { background: linear-gradient(135deg, #065f46, #10b981); border-radius: 22px; padding: 16px; color: #fff; position: relative; overflow: hidden; }
.card-bubble { position: absolute; right: -24px; bottom: -24px; width: 120px; height: 120px; border-radius: 999px; background: rgba(255,255,255,.12); }
.card-top { display: flex; justify-content: space-between; align-items: flex-start; }
.small-label { margin: 0; font-size: 12px; color: rgba(255,255,255,.82); }
.bank-card h2 { margin: 2px 0 0; font-size: 34px; line-height: 1.1; font-weight: 900; }
.credit-badge { display: inline-flex; gap: 4px; align-items: center; background: rgba(255,255,255,.2); border-radius: 10px; padding: 6px 10px; font-size: 12px; font-weight: 700; }
.card-bottom { margin-top: 14px; display: flex; justify-content: space-between; }
.strong { margin: 3px 0 0; font-weight: 900; }
.card-user { margin-top: 10px; font-size: 12px; opacity: .9; }

.func-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
.func-item { display: flex; flex-direction: column; align-items: center; gap: 4px; font-size: 11px; color: #4b5563; }
.func-icon { width: 46px; height: 46px; border-radius: 14px; display: inline-flex; align-items: center; justify-content: center; font-size: 24px; }
.bg-orange { background: #fff7ed; color: #f97316; }
.bg-blue { background: #eff6ff; color: #3b82f6; }
.bg-purple { background: #faf5ff; color: #a855f7; }
.bg-green { background: #ecfdf5; color: #10b981; }
.func-item small { font-size: 10px; color: #6b7280; }

.medal-panel { background: transparent; border: 0; border-radius: 0; padding: 2px 0 0; }
.medal-panel h3 { margin: 0 0 10px; font-size: 15px; font-weight: 900; }
.medal-row { display: flex; gap: 10px; overflow-x: auto; }
.medal { width: 68px; height: 68px; border-radius: 999px; border: 2px solid #e5e7eb; flex-shrink: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #9ca3af; font-size: 9px; font-weight: 700; background: transparent; }
.medal :deep(svg) { font-size: 22px; margin-bottom: 2px; }
.active-yellow { border-color: #facc15; color: #ca8a04; }
.active-green { border-color: #4ade80; color: #16a34a; }
.active-blue { border-color: #60a5fa; color: #2563eb; }

.medal-modal { padding: 16px; background: #fff; border-radius: 16px; }
.medal-modal-head { display: flex; align-items: center; gap: 8px; }
.medal-modal-head :deep(svg) { font-size: 22px; color: #f59e0b; }
.medal-modal-head h4 { margin: 0; font-size: 16px; font-weight: 900; color: #111827; }
.medal-modal-status { margin: 12px 0 8px; font-size: 13px; font-weight: 800; }
.medal-modal-status.acquired { color: #16a34a; }
.medal-modal-status.not-yet { color: #9ca3af; }
.medal-modal-desc { margin: 0; line-height: 1.7; font-size: 13px; color: #4b5563; white-space: pre-wrap; }

.settings-drawer { padding: 10px 16px 20px; background: #fff; border-top-left-radius: 24px; border-top-right-radius: 24px; }
.drawer-handle { width: 42px; height: 4px; border-radius: 4px; background: #d1d5db; margin: 0 auto 10px; }
.settings-drawer h3 { margin: 0 0 10px; font-size: 18px; font-weight: 900; }
.setting-item { width: 100%; border: 1px solid #e5e7eb; background: #fff; color: #374151; border-radius: 12px; padding: 12px; display: inline-flex; align-items: center; justify-content: center; gap: 8px; font-weight: 800; margin-bottom: 8px; }
.setting-item.danger { border-color: #fee2e2; background: #fff1f2; color: #be123c; margin-bottom: 0; }

:global(.dark) .profile-page { background: #111827; }
:global(.dark) .top-header h2 { color: #f3f4f6; }
:global(.dark) .setting-btn { background: #1f2937; color: #d1d5db; }
:global(.dark) .func-item { color: #d1d5db; }
:global(.dark) .func-item small { color: #9ca3af; }
:global(.dark) .medal-panel h3 { color: #f3f4f6; }
:global(.dark) .medal { border-color: #374151; color: #9ca3af; }
:global(.dark) .settings-drawer { background: #1f2937; }
:global(.dark) .settings-drawer h3 { color: #f3f4f6; }
:global(.dark) .setting-item { background: #111827; border-color: #374151; color: #e5e7eb; }
:global(.dark) .medal-modal { background: #1f2937; }
:global(.dark) .medal-modal-head h4 { color: #f3f4f6; }
:global(.dark) .medal-modal-desc { color: #cbd5e1; }
</style>
