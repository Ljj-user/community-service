<route lang="yaml">
meta:
  title: admin-dashboard
  layout: default
  breadcrumb:
    - adminOpsGroup
    - admin-dashboard
</route>

<script setup lang="ts">
const router = useRouter()
const { t } = useI18n()

function go(path: string) {
  router.push(path)
}
</script>

<template>
  <div class="space-y-4">
    <h1 class="text-2xl font-semibold mb-2">
      {{ t('community.dashboard.title') }}
    </h1>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-4">
      {{ t('community.dashboard.intro') }}
    </p>

    <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <Card :title="t('community.dashboard.cardRequestsTitle')" class="cursor-pointer" @click="go('/community/requests')">
        <p class="text-sm text-slate-600 dark:text-slate-300">
          {{ t('community.dashboard.cardRequestsDesc') }}
        </p>
        <div class="mt-3 flex gap-2">
          <n-button size="small" type="primary" @click.stop="go('/community/requests')">
            {{ t('community.dashboard.cardRequestsBtn') }}
          </n-button>
        </div>
      </Card>

      <Card :title="t('community.dashboard.cardVolunteersTitle')" class="cursor-pointer" @click="go('/community/volunteers')">
        <p class="text-sm text-slate-600 dark:text-slate-300">
          {{ t('community.dashboard.cardVolunteersDesc') }}
        </p>
        <div class="mt-3 flex gap-2">
          <n-button size="small" type="primary" @click.stop="go('/community/volunteers')">
            {{ t('community.dashboard.cardVolunteersBtn') }}
          </n-button>
        </div>
      </Card>

      <Card :title="t('community.dashboard.cardMonitorTitle')" class="cursor-pointer" @click="go('/community/monitor')">
        <p class="text-sm text-slate-600 dark:text-slate-300">
          {{ t('community.dashboard.cardMonitorDesc') }}
        </p>
        <div class="mt-3 flex gap-2">
          <n-button size="small" @click.stop="go('/community/monitor')">
            {{ t('community.dashboard.cardMonitorBtn') }}
          </n-button>
        </div>
      </Card>

      <Card :title="t('community.dashboard.cardNewsTitle')" class="cursor-pointer" @click="go('/community/announcements')">
        <p class="text-sm text-slate-600 dark:text-slate-300">
          {{ t('community.dashboard.cardNewsDesc') }}
        </p>
        <div class="mt-3 flex gap-2">
          <n-button size="small" @click.stop="go('/community/announcements')">
            {{ t('community.dashboard.cardNewsBtn') }}
          </n-button>
        </div>
      </Card>

      <Card :title="t('community.dashboard.cardStatsTitle')" class="cursor-pointer" @click="go('/admin/global-dashboard')">
        <p class="text-sm text-slate-600 dark:text-slate-300">
          {{ t('community.dashboard.cardStatsDesc') }}
        </p>
        <div class="mt-3 flex gap-2">
          <n-button size="small" @click.stop="go('/admin/global-dashboard')">
            {{ t('community.dashboard.cardStatsBtn') }}
          </n-button>
        </div>
      </Card>
    </div>

    <div class="mt-6">
      <h2 class="text-lg font-semibold mb-3">
        {{ t('community.dashboard.sectionSystemTitle') }}
      </h2>
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <Card :title="t('community.dashboard.cardUsersTitle')" class="cursor-pointer" @click="go('/admin/users')">
          <p class="text-sm text-slate-600 dark:text-slate-300">
            {{ t('community.dashboard.cardUsersDesc') }}
          </p>
          <div class="mt-3 flex gap-2">
            <n-button size="small" type="primary" @click.stop="go('/admin/users')">
              {{ t('community.dashboard.cardUsersBtn') }}
            </n-button>
          </div>
        </Card>

        <Card :title="t('community.dashboard.cardAuditTitle')" class="cursor-pointer" @click="go('/admin/audit')">
          <p class="text-sm text-slate-600 dark:text-slate-300">
            {{ t('community.dashboard.cardAuditDesc') }}
          </p>
          <div class="mt-3 flex gap-2">
            <n-button size="small" @click.stop="go('/admin/audit')">
              {{ t('community.dashboard.cardAuditBtn') }}
            </n-button>
          </div>
        </Card>
      </div>
    </div>
  </div>
</template>
