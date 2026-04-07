<route lang="yaml">
meta:
  title: admin-global-dashboard
  layout: default
  breadcrumb:
    - adminSystemGroup
    - admin-global-dashboard
</route>

<script setup lang="ts">
import type { ChartData, SimpleChartSeries } from '~/models/ChartData'
import 'vue3-map-chart/dist/style.css'
import { MapChart } from 'vue3-map-chart'
import type { DashboardStats, RegionStat } from '~/api/dashboardStats'
import { getDashboardStats, getRegionCoverage } from '~/api/dashboardStats'

const { t, locale } = useI18n()
const message = useMessage()

const loading = ref(false)
const stats = ref<DashboardStats | null>(null)
const regionStats = ref<RegionStat[]>([])

const mapData = computed(() => {
  const data: Record<string, number> = {}
  regionStats.value.forEach((item) => {
    data[item.regionCode] = item.serviceCount
  })
  return data
})

const matchRatePercent = computed(() => {
  if (!stats.value) return 0
  const base =
    stats.value.matchRate ?? (stats.value.totalRequests ? stats.value.completedRequests / stats.value.totalRequests : 0)
  return Number.isFinite(base) ? Math.round(base * 1000) / 10 : 0
})

const coverageRatePercent = computed(() => {
  if (!stats.value) return 0
  const base = stats.value.coverageRate ?? 0
  return Number.isFinite(base) ? Math.round(base * 1000) / 10 : 0
})

const requestMatchChart = computed<SimpleChartSeries[]>(() => {
  void locale.value
  if (!stats.value || !stats.value.totalRequests) {
    return []
  }
  const completed = stats.value.completedRequests || 0
  const unmatched = Math.max(stats.value.totalRequests - completed, 0)
  return [
    { name: t('community.globalDashboard.legendMatched'), value: completed },
    { name: t('community.globalDashboard.legendUnmatched'), value: unmatched },
  ]
})

const monthlyTrendChart = computed<ChartData | null>(() => {
  void locale.value
  if (!stats.value) return null
  return {
    labels: [t('community.globalDashboard.seriesNew'), t('community.globalDashboard.seriesDone')],
    series: [
      {
        name: t('community.globalDashboard.seriesRequests'),
        data: [stats.value.monthlyNewRequests || 0, stats.value.monthlyCompletedRequests || 0],
      },
    ],
  }
})

async function loadData() {
  loading.value = true
  try {
    const [statsRes, regionRes] = await Promise.all([getDashboardStats(), getRegionCoverage()])
    if (statsRes.code === 200 && statsRes.data) {
      stats.value = statsRes.data
    } else {
      message.error(statsRes.message || t('community.globalDashboard.loadStatsFail'))
    }
    if (regionRes.code === 200 && regionRes.data) {
      regionStats.value = regionRes.data
    }
  } catch (e: any) {
    message.error(e?.message || t('community.globalDashboard.loadFail'))
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold">
          {{ t('community.globalDashboard.title') }}
        </h1>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ t('community.globalDashboard.subtitle') }}
        </p>
      </div>
      <n-button size="small" type="primary" :loading="loading" @click="loadData">
        {{ t('community.globalDashboard.refresh') }}
      </n-button>
    </div>

    <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
      <Card :title="t('community.globalDashboard.kpiMatchRate')">
        <div class="flex flex-col gap-1">
          <div class="text-3xl font-semibold">
            {{ matchRatePercent.toFixed(1) }}%
          </div>
          <p class="text-xs text-slate-500">
            {{ t('community.globalDashboard.kpiMatchRateDesc') }}
          </p>
          <p class="text-xs text-slate-400">
            {{ t('community.globalDashboard.kpiMatchDetail', { completed: stats?.completedRequests ?? 0, total: stats?.totalRequests ?? 0 }) }}
          </p>
        </div>
      </Card>

      <Card :title="t('community.globalDashboard.kpiCoverage')">
        <div class="flex flex-col gap-1">
          <div class="text-3xl font-semibold">
            {{ coverageRatePercent.toFixed(1) }}%
          </div>
          <p class="text-xs text-slate-500">
            {{ t('community.globalDashboard.kpiCoverageDesc') }}
          </p>
          <p class="text-xs text-slate-400">
            {{ t('community.globalDashboard.kpiActiveVol', { n: stats?.activeVolunteers ?? 0 }) }}
          </p>
        </div>
      </Card>

      <Card :title="t('community.globalDashboard.kpiTotalReq')">
        <div class="flex flex-col gap-1">
          <div class="text-2xl font-semibold">
            {{ stats?.totalRequests ?? 0 }}
          </div>
          <p class="text-xs text-slate-500">
            {{ t('community.globalDashboard.kpiTotalLabel') }}
          </p>
          <p class="text-xs text-emerald-500">
            {{ t('community.globalDashboard.kpiCompletedLine', { n: stats?.completedRequests ?? 0 }) }}
          </p>
          <p class="text-xs text-amber-500">
            {{ t('community.globalDashboard.kpiPending', { n: stats?.pendingRequests ?? 0 }) }}
          </p>
        </div>
      </Card>

      <Card :title="t('community.globalDashboard.kpiHours')">
        <div class="flex flex-col gap-1">
          <div class="text-3xl font-semibold">
            {{ stats?.totalServiceHours ?? 0 }}
          </div>
          <p class="text-xs text-slate-500">
            {{ t('community.globalDashboard.kpiHoursDesc') }}
          </p>
        </div>
      </Card>
    </div>

    <div class="grid gap-4 lg:grid-cols-2">
      <Card :title="t('community.globalDashboard.chartMatchShare')">
        <BaseChart
          v-if="requestMatchChart.length"
          :data="requestMatchChart"
          type="donut"
          :height="260"
        />
        <p v-else class="text-xs text-slate-500">
          {{ t('community.globalDashboard.chartNoData') }}
        </p>
      </Card>

      <Card :title="t('community.globalDashboard.chartMonthly')">
        <BaseChart
          v-if="monthlyTrendChart"
          :data="monthlyTrendChart"
          type="bar"
          :height="260"
        />
        <p v-else class="text-xs text-slate-500">
          {{ t('community.globalDashboard.chartMonthlyNoData') }}
        </p>
      </Card>
    </div>

    <Card :title="t('community.globalDashboard.chartHeatmap')">
      <div class="mt-2">
        <MapChart
          :data="mapData"
          base-color="var(--primary-color)"
          height="420"
        />
        <p class="mt-2 text-xs text-slate-500">
          {{ t('community.globalDashboard.heatmapHint') }}
        </p>
      </div>
    </Card>
  </div>
</template>
