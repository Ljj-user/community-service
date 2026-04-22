<route lang="yaml">
meta:
  title: dashboard-home
  layout: default
  breadcrumb: []
</route>

<script setup lang="ts">
import {
  getDashboardPanel,
  type AdminDashboardPanel,
  getSupplyDemandTrend,
  getVolunteerTop,
  type TrendChart,
} from '~/api/dashboardStats'
import { serviceMonitorList } from '~/api/serviceMonitor'
import { getUserDashboardSummary, type UserDashboardSummary } from '~/api/userDashboard'
import ChinaHeatMap from '~/components/Charts/ChinaHeatMap.vue'

const { t, locale } = useI18n()
const message = useMessage()
const accountStore = useAccountStore()

const role = computed(() => accountStore.user?.role)
const identity = computed(() => accountStore.user?.identityType)

const loading = ref(false)
const adminPanel = ref<AdminDashboardPanel | null>(null)
const trend = ref<TrendChart | null>(null)
const volunteerTop = ref<{ name: string; count: number }[]>([])
const riskSplit = ref<{ unclaimed: number; unfinished: number }>({ unclaimed: 0, unfinished: 0 })
const userSummary = ref<UserDashboardSummary | null>(null)

const isSuperAdmin = computed(() => role.value === 1)
const isCommunityAdmin = computed(() => role.value === 2)
const isVolunteer = computed(() => role.value === 3 && identity.value === 2)
const isResident = computed(() => role.value === 3 && identity.value !== 2)
const hasAdminData = computed(() => {
  const s = adminPanel.value?.stats
  if (!s) return false
  return Number(s.totalRequests ?? 0) > 0
    || Number(s.totalUsers ?? 0) > 0
    || Number(s.totalServiceHours ?? 0) > 0
})

function dateLoc() {
  return locale.value === 'zn' ? 'zh-CN' : 'en-US'
}

function formatDt(iso?: string) {
  if (!iso) return '-'
  return new Date(iso).toLocaleString(dateLoc())
}

async function load() {
  loading.value = true
  try {
    if (role.value === 1 || role.value === 2) {
      const [res, trendRes, topRes, risk1, risk2] = await Promise.all([
        getDashboardPanel(),
        getSupplyDemandTrend(7),
        getVolunteerTop(30, 10),
        serviceMonitorList({ current: 1, size: 1, riskType: 1 }),
        serviceMonitorList({ current: 1, size: 1, riskType: 2 }),
      ])
      if (Number(res.code) === 200 && res.data) {
        adminPanel.value = res.data
      }
      else {
        message.error(res.message || t('community.unifiedDashboard.loadFail'))
      }
      if (trendRes.code === 200)
        trend.value = trendRes.data
      if (topRes.code === 200)
        volunteerTop.value = (topRes.data || []) as any
      riskSplit.value = {
        unclaimed: risk1.code === 200 ? (risk1.data?.total ?? 0) : 0,
        unfinished: risk2.code === 200 ? (risk2.data?.total ?? 0) : 0,
      }
    }
    else if (role.value === 3) {
      const res = await getUserDashboardSummary()
      if (Number(res.code) === 200 && res.data) {
        userSummary.value = res.data
      }
      else {
        message.error(res.message || t('community.unifiedDashboard.loadFail'))
      }
    }
  }
  catch (e: any) {
    message.error(e?.message || t('community.unifiedDashboard.loadFail'))
  }
  finally {
    loading.value = false
  }
}

onMounted(load)

const maxDemand = computed(() => {
  const list = adminPanel.value?.demandByServiceType ?? []
  if (!list.length) return 1
  return Math.max(...list.map(d => d.count), 1)
})

const adminFunnelSeries = computed(() => {
  if (!adminPanel.value?.stats) return []
  const s = adminPanel.value.stats as any
  return [
    { name: '待审核', value: s.pendingRequests ?? 0 },
    { name: '已发布', value: s.publishedRequests ?? 0 },
    { name: '已认领', value: s.claimedRequests ?? 0 },
    { name: '已完成', value: s.completedRequests ?? 0 },
  ]
})

const adminFunnelChartData = computed(() => {
  if (!adminFunnelSeries.value.length) return null
  return {
    labels: adminFunnelSeries.value.map(x => x.name),
    series: [
      { name: '需求数量', data: adminFunnelSeries.value.map(x => Number(x.value || 0)) },
    ],
  }
})

const trendChartData = computed(() => {
  const data = trend.value
  if (!data) return null
  return {
    labels: data.labels,
    series: [
      { name: '需求发布', data: data.demand },
      { name: '志愿者认领', data: data.supply },
    ],
  }
})

const trendIsAllZero = computed(() => {
  if (!trendChartData.value) return false
  const list = trendChartData.value.series.flatMap(s => s.data || [])
  return list.length > 0 && list.every(n => Number(n || 0) === 0)
})

const topBarData = computed(() => {
  const list = volunteerTop.value?.length ? volunteerTop.value : []
  if (!list.length) return null
  return {
    labels: list.map(x => x.name),
    series: [
      { name: '近30天服务时长（小时）', data: list.map(x => x.count) },
    ],
  }
})

const riskDonutData = computed(() => {
  const published = Number(adminPanel.value?.stats?.publishedRequests ?? 0)
  const claimed = Number(adminPanel.value?.stats?.claimedRequests ?? 0)
  const completed = Number(adminPanel.value?.stats?.completedRequests ?? 0)
  const unclaimed = Math.max(riskSplit.value.unclaimed, 0)
  const unfinished = Math.max(riskSplit.value.unfinished, 0)
  const normal = Math.max(published + claimed + completed - unclaimed - unfinished, 0)

  if (unclaimed + unfinished + normal <= 0) return []

  return [
    { name: '超时未认领', value: unclaimed },
    { name: '超时未完成', value: unfinished },
    { name: '正常流程', value: normal },
  ]
})

const riskDonutOptions = computed(() => ({
  legend: {
    position: 'bottom',
    horizontalAlign: 'center',
    floating: false,
  },
  grid: {
    padding: {
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    },
  },
  plotOptions: {
    pie: {
      startAngle: 0,
      endAngle: 360,
      offsetX: 0,
      offsetY: 0,
      customScale: 0.88,
      donut: {
        size: '62%',
        labels: {
          show: false,
        },
      },
    },
  },
}))
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between gap-3">
      <div>
        <h1 class="text-xl font-semibold">
          {{ t('community.unifiedDashboard.pageTitle') }}
        </h1>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ t('community.unifiedDashboard.pageSubtitle') }}
        </p>
      </div>
      <n-button size="small" type="primary" :loading="loading" @click="load">
        {{ t('community.globalDashboard.refresh') }}
      </n-button>
    </div>

    <n-spin :show="loading">
      <!-- 超级管理员 -->
      <div v-if="isSuperAdmin && adminPanel" class="space-y-4">
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          <Card title="平台覆盖规模">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.totalUsers ?? 0 }} 用户 / {{ adminPanel.stats.totalCommunities ?? 0 }} 社区
            </div>
            <p class="text-xs text-slate-500 mt-1">
              统计口径：未删除用户数、入驻社区数
            </p>
          </Card>
          <Card title="累计社会贡献">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.totalServiceHours ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              累计服务时长（小时）
            </p>
          </Card>
          <Card title="对接成功率">
            <div class="text-2xl font-semibold">
              {{ (((adminPanel.stats.matchRate ?? 0) || 0) * 100).toFixed(1) }}%
            </div>
            <p class="text-xs text-slate-500 mt-1">
              已完成 / 总需求
            </p>
          </Card>
          <Card title="系统风险指数">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.riskIndex ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              基于超时未认领/未完成估算（0-100）
            </p>
          </Card>
        </div>

        <div class="grid gap-4 lg:grid-cols-2">
          <Card title="需求类型画像（饼图）">
            <BaseChart
              v-if="adminPanel.demandByServiceType?.length"
              :data="adminPanel.demandByServiceType.map(x => ({ name: x.name, value: x.count }))"
              type="donut"
              :height="260"
            />
            <p v-else class="text-xs text-slate-500">暂无真实业务数据，请先导入初始化数据或产生服务记录。</p>
          </Card>

          <WelcomeCard />
        </div>

        <Card title="全城公益热力图（中国地图）">
          <ChinaHeatMap
            :data="(adminPanel.regionCoverage?.length ? adminPanel.regionCoverage.reduce((acc: any, it: any) => { acc[it.regionCode] = it.serviceCount; return acc }, {}) : {})"
            :height="460"
          />
          <p v-if="!adminPanel.regionCoverage?.length" class="text-xs text-slate-500 mt-2">
            当前暂无已完成服务数据，热力图待产生数据后自动更新。
          </p>
        </Card>

        <div class="grid gap-4 lg:grid-cols-2">
          <Card title="服务对接全链路漏斗">
            <BaseChart
              v-if="adminFunnelChartData"
              :data="adminFunnelChartData"
              type="bar"
              :height="360"
              :options="{ plotOptions: { bar: { horizontal: true } } }"
            />
            <p v-else class="text-xs text-slate-500">暂无漏斗数据。</p>
          </Card>
          <Card title="系统操作风险分布">
            <BaseChart
              v-if="riskDonutData.length"
              :data="riskDonutData"
              type="donut"
              :height="360"
              :options="riskDonutOptions"
            />
            <p v-else class="text-xs text-slate-500">暂无风险分布数据。</p>
            <p class="text-xs text-slate-400 mt-2">风险分布建议结合「监控」页统计口径进一步细化。</p>
          </Card>
        </div>

        <Card title="供需趋势对比线">
          <BaseChart v-if="trendChartData" :data="trendChartData" type="line" :height="260" />
          <p v-else class="text-xs text-slate-500">暂无趋势数据。</p>
          <p v-if="trendIsAllZero" class="text-xs text-slate-500 mt-2">最近统计周期内发布/认领均为 0，曲线将贴近 0 轴。</p>
        </Card>

        <!-- 去除旧模块：近期服务排期 / 重复漏斗块 -->
      </div>

      <!-- 社区管理员 -->
      <div v-else-if="isCommunityAdmin && adminPanel" class="space-y-4">
        <n-alert type="info" :bordered="false" class="mb-2">
          {{ t('community.unifiedDashboard.communityScopeNote') }}
        </n-alert>
        <WelcomeCard />
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          <Card title="红色警报：待审核">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.pendingRequests ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              需尽快审核，避免需求积压
            </p>
          </Card>
          <Card title="本周响应时效（分钟）">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.weeklyAvgResponseMinutes ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              发布 → 志愿者认领的平均时长
            </p>
          </Card>
          <Card title="活跃志愿者储备（近30天）">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.activeVolunteers30d ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              近30天有认领记录人数
            </p>
          </Card>
          <Card title="对接成功率">
            <div class="text-2xl font-semibold">
              {{ (((adminPanel.stats.matchRate ?? 0) || 0) * 100).toFixed(1) }}%
            </div>
            <p class="text-xs text-slate-500 mt-1">
              已完成 / 总需求（本社区口径）
            </p>
          </Card>
        </div>

        <div class="grid gap-4 lg:grid-cols-2">
          <Card title="需求类型画像（饼图）">
            <BaseChart
              v-if="adminPanel.demandByServiceType?.length"
              :data="adminPanel.demandByServiceType.map(x => ({ name: x.name, value: x.count }))"
              type="donut"
              :height="260"
            />
          </Card>
          <Card title="供需趋势对比线">
            <BaseChart v-if="trendChartData" :data="trendChartData" type="line" :height="260" />
            <p v-else class="text-xs text-slate-500">暂无趋势数据。</p>
          </Card>
        </div>

        <Card title="志愿者荣誉榜 Top10">
          <BaseChart v-if="topBarData" :data="topBarData" type="bar" :height="280" />
          <p v-else class="text-xs text-slate-500">暂无数据</p>
        </Card>
        <n-alert v-if="!hasAdminData" type="warning" :bordered="false">
          当前数据库业务数据较少，部分图表为空。建议先导入初始化数据并跑通“发布-审核-认领-完成”流程后再展示。
        </n-alert>

        <!-- 去除旧模块：近期服务排期 / 社区服务对接漏斗 / 重复画像 -->
      </div>

      <!-- 志愿者 -->
      <div v-else-if="isVolunteer && userSummary?.volunteer" class="space-y-4">
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          <Card :title="t('community.unifiedDashboard.volHours')">
            <div class="text-2xl font-semibold">
              {{ userSummary.volunteer.totalServiceHours ?? 0 }}
            </div>
          </Card>
          <Card :title="t('community.unifiedDashboard.volPending')">
            <div class="text-2xl font-semibold">
              {{ userSummary.volunteer.pendingClaimCount ?? 0 }}
            </div>
          </Card>
          <Card :title="t('community.unifiedDashboard.volDone')">
            <div class="text-2xl font-semibold">
              {{ userSummary.volunteer.completedClaimCount ?? 0 }}
            </div>
          </Card>
          <Card :title="t('community.unifiedDashboard.volRating')">
            <div class="text-2xl font-semibold">
              {{ userSummary.volunteer.averageRating ?? '—' }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.volRatingHint', { n: userSummary.volunteer.evaluationCount ?? 0 }) }}
            </p>
          </Card>
        </div>

        <div class="grid gap-4 lg:grid-cols-2">
          <Card :title="t('community.unifiedDashboard.volProjects')">
            <ul class="list-disc pl-5 text-sm space-y-1">
              <li v-for="(p, i) in userSummary.volunteer.recentProjectTitles" :key="i">
                {{ p }}
              </li>
              <li v-if="!userSummary.volunteer.recentProjectTitles?.length" class="text-slate-400 list-none pl-0">
                {{ t('community.unifiedDashboard.empty') }}
              </li>
            </ul>
          </Card>
          <Card :title="t('community.unifiedDashboard.volHonor')">
            <p class="text-sm text-slate-600 dark:text-slate-300">
              {{ userSummary.volunteer.honorNote }}
            </p>
          </Card>
        </div>
      </div>

      <!-- 居民 -->
      <div v-else-if="isResident && userSummary?.resident" class="space-y-4">
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
          <Card :title="t('community.unifiedDashboard.resPending')">
            <div class="text-2xl font-semibold">
              {{ userSummary.resident.requestStatusCounts?.pending ?? 0 }}
            </div>
          </Card>
          <Card :title="t('community.unifiedDashboard.resPublished')">
            <div class="text-2xl font-semibold">
              {{ userSummary.resident.requestStatusCounts?.published ?? 0 }}
            </div>
          </Card>
          <Card :title="t('community.unifiedDashboard.resClaimed')">
            <div class="text-2xl font-semibold">
              {{ userSummary.resident.requestStatusCounts?.claimed ?? 0 }}
            </div>
          </Card>
          <Card :title="t('community.unifiedDashboard.resCompleted')">
            <div class="text-2xl font-semibold">
              {{ userSummary.resident.requestStatusCounts?.completed ?? 0 }}
            </div>
          </Card>
          <Card :title="t('community.unifiedDashboard.resRejected')">
            <div class="text-2xl font-semibold">
              {{ userSummary.resident.requestStatusCounts?.rejected ?? 0 }}
            </div>
          </Card>
        </div>

        <div class="grid gap-4 lg:grid-cols-2">
          <Card :title="t('community.unifiedDashboard.resEvalCount')">
            <div class="text-2xl font-semibold">
              {{ userSummary.resident.evaluationsGivenCount ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.resEvalHint') }}
            </p>
          </Card>
          <Card :title="t('community.unifiedDashboard.resAnnouncements')">
            <ul class="text-sm space-y-2">
              <li v-for="a in userSummary.resident.latestAnnouncements" :key="a.id" class="flex justify-between gap-2">
                <span class="truncate">{{ a.title }}</span>
                <span class="text-slate-400 shrink-0 text-xs">{{ formatDt(a.publishedAt) }}</span>
              </li>
              <li v-if="!userSummary.resident.latestAnnouncements?.length" class="text-slate-400">
                {{ t('community.unifiedDashboard.empty') }}
              </li>
            </ul>
          </Card>
        </div>
      </div>

      <div v-else-if="!loading" class="text-sm text-slate-500">
        {{ t('community.unifiedDashboard.noData') }}
      </div>
    </n-spin>
  </div>
</template>
