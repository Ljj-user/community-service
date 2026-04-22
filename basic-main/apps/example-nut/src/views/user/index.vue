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
        <div class="func-item">
          <div class="func-icon bg-orange"><FmIcon name="mdi:clipboard-list-outline" /></div>
          <span>我的任务</span>
        </div>
        <div class="func-item" role="button" tabindex="0" @click="router.push('/profile-edit')">
          <div class="func-icon bg-blue"><FmIcon name="mdi:account-edit-outline" /></div>
          <span>完善资料</span>
        </div>
        <div class="func-item">
          <div class="func-icon bg-blue"><FmIcon name="mdi:account-group-outline" /></div>
          <span>亲情绑定</span>
        </div>
        <div class="func-item">
          <div class="func-icon bg-purple"><FmIcon name="mdi:certificate-outline" /></div>
          <span>时长证明</span>
        </div>
        <div class="func-item">
          <div class="func-icon bg-green"><FmIcon name="mdi:storefront-outline" /></div>
          <span>积分商城</span>
        </div>
      </section>

      <section class="medal-panel">
        <h3>我的荣誉勋章</h3>
        <div class="medal-row">
          <div class="medal active-yellow">
            <FmIcon name="mdi:medal-outline" />
            <span>核心支柱</span>
          </div>
          <div class="medal active-green">
            <FmIcon name="mdi:leaf" />
            <span>初露头角</span>
          </div>
          <div class="medal active-blue">
            <FmIcon name="mdi:heart-outline" />
            <span>热心邻里</span>
          </div>
          <div class="medal">
            <FmIcon name="mdi:shield-star-outline" />
            <span>社区先锋</span>
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

.medal-panel { background: transparent; border: 0; border-radius: 0; padding: 2px 0 0; }
.medal-panel h3 { margin: 0 0 10px; font-size: 15px; font-weight: 900; }
.medal-row { display: flex; gap: 10px; overflow-x: auto; }
.medal { width: 68px; height: 68px; border-radius: 999px; border: 2px solid #e5e7eb; flex-shrink: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; color: #9ca3af; font-size: 9px; font-weight: 700; background: transparent; }
.medal :deep(svg) { font-size: 22px; margin-bottom: 2px; }
.active-yellow { border-color: #facc15; color: #ca8a04; }
.active-green { border-color: #4ade80; color: #16a34a; }
.active-blue { border-color: #60a5fa; color: #2563eb; }

.settings-drawer { padding: 10px 16px 20px; background: #fff; border-top-left-radius: 24px; border-top-right-radius: 24px; }
.drawer-handle { width: 42px; height: 4px; border-radius: 4px; background: #d1d5db; margin: 0 auto 10px; }
.settings-drawer h3 { margin: 0 0 10px; font-size: 18px; font-weight: 900; }
.setting-item { width: 100%; border: 1px solid #e5e7eb; background: #fff; color: #374151; border-radius: 12px; padding: 12px; display: inline-flex; align-items: center; justify-content: center; gap: 8px; font-weight: 800; margin-bottom: 8px; }
.setting-item.danger { border-color: #fee2e2; background: #fff1f2; color: #be123c; margin-bottom: 0; }

:global(.dark) .profile-page { background: #111827; }
:global(.dark) .top-header h2 { color: #f3f4f6; }
:global(.dark) .setting-btn { background: #1f2937; color: #d1d5db; }
:global(.dark) .func-item { color: #d1d5db; }
:global(.dark) .medal-panel h3 { color: #f3f4f6; }
:global(.dark) .medal { border-color: #374151; color: #9ca3af; }
:global(.dark) .settings-drawer { background: #1f2937; }
:global(.dark) .settings-drawer h3 { color: #f3f4f6; }
:global(.dark) .setting-item { background: #111827; border-color: #374151; color: #e5e7eb; }
</style>
