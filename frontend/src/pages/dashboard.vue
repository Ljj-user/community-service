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
} from '~/api/dashboardStats'
import { getUserDashboardSummary, type UserDashboardSummary } from '~/api/userDashboard'

const { t, locale } = useI18n()
const message = useMessage()
const accountStore = useAccountStore()

const role = computed(() => accountStore.user?.role)
const identity = computed(() => accountStore.user?.identityType)

const loading = ref(false)
const adminPanel = ref<AdminDashboardPanel | null>(null)
const userSummary = ref<UserDashboardSummary | null>(null)

const isSuperAdmin = computed(() => role.value === 1)
const isCommunityAdmin = computed(() => role.value === 2)
const isVolunteer = computed(() => role.value === 3 && identity.value === 2)
const isResident = computed(() => role.value === 3 && identity.value !== 2)

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
      const res = await getDashboardPanel()
      if (Number(res.code) === 200 && res.data) {
        adminPanel.value = res.data
      }
      else {
        message.error(res.message || t('community.unifiedDashboard.loadFail'))
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
          <Card :title="t('community.unifiedDashboard.kpiVolunteers')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.activeVolunteers ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiVolunteersHint') }}
            </p>
          </Card>
          <Card :title="t('community.unifiedDashboard.kpiHours')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.totalServiceHours ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiHoursHint') }}
            </p>
          </Card>
          <Card :title="t('community.unifiedDashboard.kpiPending')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.pendingRequests ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiPendingHint') }}
            </p>
          </Card>
          <Card :title="t('community.unifiedDashboard.kpiCompleted')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.completedRequests ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiCompletedHint') }}
            </p>
          </Card>
        </div>

        <div class="grid gap-4 lg:grid-cols-2">
          <Card :title="t('community.unifiedDashboard.sectionDemandMix')">
            <div class="space-y-2">
              <div
                v-for="row in adminPanel.demandByServiceType"
                :key="row.name"
                class="flex items-center gap-2 text-sm"
              >
                <span class="w-24 truncate text-slate-600 dark:text-slate-300">{{ row.name }}</span>
                <div class="flex-1 h-2 rounded-full bg-slate-100 dark:bg-slate-700 overflow-hidden">
                  <div
                    class="h-full rounded-full bg-primary"
                    :style="{ width: `${Math.round((row.count / maxDemand) * 100)}%` }"
                  />
                </div>
                <span class="w-8 text-right tabular-nums">{{ row.count }}</span>
              </div>
              <p v-if="!adminPanel.demandByServiceType?.length" class="text-sm text-slate-400">
                {{ t('community.unifiedDashboard.empty') }}
              </p>
            </div>
          </Card>

          <Card v-if="adminPanel.fundingMonitor" :title="t('community.unifiedDashboard.sectionFund')">
            <div class="grid grid-cols-2 gap-2 text-sm">
              <div>
                <div class="text-slate-500">
                  {{ t('community.unifiedDashboard.fundIn') }}
                </div>
                <div class="font-mono">
                  {{ adminPanel.fundingMonitor.fundIn }}
                </div>
              </div>
              <div>
                <div class="text-slate-500">
                  {{ t('community.unifiedDashboard.fundOut') }}
                </div>
                <div class="font-mono">
                  {{ adminPanel.fundingMonitor.fundOut }}
                </div>
              </div>
              <div>
                <div class="text-slate-500">
                  {{ t('community.unifiedDashboard.matIn') }}
                </div>
                <div class="font-mono">
                  {{ adminPanel.fundingMonitor.materialIn }}
                </div>
              </div>
              <div>
                <div class="text-slate-500">
                  {{ t('community.unifiedDashboard.matOut') }}
                </div>
                <div class="font-mono">
                  {{ adminPanel.fundingMonitor.materialOut }}
                </div>
              </div>
            </div>
            <p class="text-xs text-slate-400 mt-3">
              {{ adminPanel.fundingMonitor.note }}
            </p>
          </Card>
        </div>

        <Card :title="t('community.unifiedDashboard.sectionSchedule')">
          <n-data-table
            size="small"
            :bordered="false"
            :columns="[
              { title: t('community.unifiedDashboard.colType'), key: 'serviceType' },
              { title: t('community.unifiedDashboard.colTime'), key: 'expectedTime', render: (r: any) => formatDt(r.expectedTime) },
              { title: t('community.unifiedDashboard.colAddr'), key: 'serviceAddress', ellipsis: { tooltip: true } },
            ]"
            :data="adminPanel.upcomingSchedule || []"
          />
        </Card>
      </div>

      <!-- 社区管理员 -->
      <div v-else-if="isCommunityAdmin && adminPanel" class="space-y-4">
        <n-alert type="info" :bordered="false" class="mb-2">
          {{ t('community.unifiedDashboard.communityScopeNote') }}
        </n-alert>
        <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          <Card :title="t('community.unifiedDashboard.kpiActiveUsers')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.activeVolunteers ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiActiveUsersHint') }}
            </p>
          </Card>
          <Card :title="t('community.unifiedDashboard.kpiPendingAudit')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.pendingRequests ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiPendingAuditHint') }}
            </p>
          </Card>
          <Card :title="t('community.unifiedDashboard.kpiMonthlyNew')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.monthlyNewRequests ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiMonthlyNewHint') }}
            </p>
          </Card>
          <Card :title="t('community.unifiedDashboard.kpiMonthlyDone')">
            <div class="text-2xl font-semibold">
              {{ adminPanel.stats.monthlyCompletedRequests ?? 0 }}
            </div>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.unifiedDashboard.kpiMonthlyDoneHint') }}
            </p>
          </Card>
        </div>

        <Card :title="t('community.unifiedDashboard.sectionDemandMix')">
          <div class="space-y-2">
            <div
              v-for="row in adminPanel.demandByServiceType"
              :key="row.name"
              class="flex items-center gap-2 text-sm"
            >
              <span class="w-24 truncate">{{ row.name }}</span>
              <div class="flex-1 h-2 rounded-full bg-slate-100 dark:bg-slate-700 overflow-hidden">
                <div
                  class="h-full rounded-full bg-primary"
                  :style="{ width: `${Math.round((row.count / maxDemand) * 100)}%` }"
                />
              </div>
              <span class="w-8 text-right tabular-nums">{{ row.count }}</span>
            </div>
          </div>
        </Card>

        <Card :title="t('community.unifiedDashboard.sectionSchedule')">
          <n-data-table
            size="small"
            :bordered="false"
            :columns="[
              { title: t('community.unifiedDashboard.colType'), key: 'serviceType' },
              { title: t('community.unifiedDashboard.colTime'), key: 'expectedTime', render: (r: any) => formatDt(r.expectedTime) },
              { title: t('community.unifiedDashboard.colAddr'), key: 'serviceAddress', ellipsis: { tooltip: true } },
            ]"
            :data="adminPanel.upcomingSchedule || []"
          />
        </Card>
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
