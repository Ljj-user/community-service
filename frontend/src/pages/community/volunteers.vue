<route lang="yaml">
meta:
  title: communityVolunteers
  layout: default
  breadcrumb:
    - adminOpsGroup
    - communityVolunteers
</route>

<script setup lang="ts">
import type { DataTableColumns } from 'naive-ui'
import {
  adminUserList,
  adminUserSetStatus,
  type AdminUserVO,
} from '~/api/adminUsers'
import {
  CheckmarkCircle20Regular,
  Eye20Regular,
  Prohibited20Regular,
} from '@vicons/fluent'
import { h, resolveComponent } from 'vue'
import { dtActionBtn, dtActionRowClass } from '~/utils/dataTableActions'

const { t, locale } = useI18n()
const message = useMessage()
const dialog = useDialog()

const loading = ref(false)

const query = reactive({
  username: '',
  status: null as null | number,
  page: 1,
  size: 10,
})

const pageTotal = ref(0)
const rows = ref<AdminUserVO[]>([])

const showDrawer = ref(false)
const currentVolunteer = ref<AdminUserVO | null>(null)

const statusOptions = computed(() => [
  { label: t('community.volunteers.all'), value: null },
  { label: t('community.volunteers.pending'), value: 0 },
  { label: t('community.volunteers.approved'), value: 1 },
])

function identityText(identityType: number) {
  if (identityType === 1) return t('community.users.identityResident')
  if (identityType === 2) return t('community.users.identityVolunteer')
  return '-'
}

function statusText(status: number) {
  return status === 1 ? t('community.volunteers.approved') : t('community.volunteers.pending')
}

function statusTagType(status: number) {
  return status === 1 ? 'success' : 'warning'
}

async function fetchList() {
  loading.value = true
  try {
    const res = await adminUserList({
      username: query.username || undefined,
      role: 3, // 普通用户
      status: query.status ?? undefined,
      page: query.page,
      size: query.size,
    })
    if (res.code !== 200) {
      message.error(res.message || t('community.volunteers.loadFailed'))
      return
    }
    const volunteers = (res.data.records || []).filter(
      (u) => u.identityType === 2,
    )
    rows.value = volunteers
    pageTotal.value = res.data.total || 0
  } catch (e: any) {
    message.error(e?.message || t('community.volunteers.loadFailed'))
  } finally {
    loading.value = false
  }
}

function resetQuery() {
  query.username = ''
  query.status = null
  query.page = 1
  fetchList()
}

function openDetail(row: AdminUserVO) {
  currentVolunteer.value = row
  showDrawer.value = true
}

async function approve(row: AdminUserVO) {
  dialog.warning({
    title: t('community.volunteers.approveTitle'),
    content: t('community.volunteers.approveBody', { name: row.realName || row.username }),
    positiveText: t('community.volunteers.approveBtn'),
    negativeText: t('common.cancel'),
    async onPositiveClick() {
      const res = await adminUserSetStatus(row.id, 1)
      if (res.code !== 200) {
        message.error(res.message || t('community.volunteers.opFailed'))
        return
      }
      message.success(t('community.volunteers.approveOk'))
      fetchList()
    },
  })
}

async function reject(row: AdminUserVO) {
  dialog.warning({
    title: t('community.volunteers.disableTitle'),
    content: t('community.volunteers.disableBody', { name: row.realName || row.username }),
    positiveText: t('community.volunteers.disable'),
    negativeText: t('common.cancel'),
    async onPositiveClick() {
      const res = await adminUserSetStatus(row.id, 0)
      if (res.code !== 200) {
        message.error(res.message || t('community.volunteers.opFailed'))
        return
      }
      message.success(t('community.volunteers.disableOk'))
      fetchList()
    },
  })
}

const columns = computed<DataTableColumns<AdminUserVO>>(() => {
  void locale.value
  return [
    { title: 'ID', key: 'id', width: 80 },
    { title: t('community.volunteers.colUsername'), key: 'username', minWidth: 120 },
    { title: t('community.volunteers.colName'), key: 'realName', minWidth: 120, render: (r) => r.realName || '-' },
    { title: t('community.volunteers.colPhone'), key: 'phone', minWidth: 130, render: (r) => r.phone || '-' },
    { title: t('community.volunteers.colEmail'), key: 'email', minWidth: 170, render: (r) => r.email || '-' },
    {
      title: t('community.volunteers.colIdentity'),
      key: 'identityType',
      width: 120,
      render: (r) => identityText(r.identityType),
    },
    {
      title: t('community.volunteers.colStatus'),
      key: 'status',
      width: 110,
      render: (r) =>
        h(
          resolveComponent('NTag') as any,
          { size: 'small', type: statusTagType(r.status), bordered: false },
          { default: () => statusText(r.status) },
        ),
    },
    {
      title: t('community.volunteers.colActions'),
      key: 'actions',
      width: 260,
      render: (r) =>
        h('div', { class: dtActionRowClass }, [
          dtActionBtn(
            t('community.volunteers.viewQual'),
            { type: 'info', onClick: () => openDetail(r) },
            Eye20Regular,
          ),
          ...(r.status === 0
            ? [
                dtActionBtn(
                  t('community.volunteers.pass'),
                  { type: 'success', onClick: () => approve(r) },
                  CheckmarkCircle20Regular,
                ),
              ]
            : [
                dtActionBtn(
                  t('community.volunteers.disable'),
                  { type: 'error', onClick: () => reject(r) },
                  Prohibited20Regular,
                ),
              ]),
        ]),
    },
  ]
})

onMounted(fetchList)
</script>

<template>
  <div class="space-y-4">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold">
          {{ t('community.volunteers.title') }}
        </h1>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ t('community.volunteers.subtitle') }}
        </p>
      </div>
    </div>

    <Card>
      <div class="grid gap-3 md:grid-cols-4">
        <n-input v-model:value="query.username" :placeholder="t('community.volunteers.searchUser')" clearable />
        <n-select v-model:value="query.status" :options="statusOptions" :placeholder="t('community.volunteers.auditStatus')" clearable />
        <div class="flex gap-2">
          <n-button type="primary" :loading="loading" @click="() => { query.page = 1; fetchList() }">
            {{ t('community.volunteers.query') }}
          </n-button>
          <n-button @click="resetQuery">
            {{ t('community.volunteers.reset') }}
          </n-button>
        </div>
      </div>
    </Card>

    <Card>
      <n-data-table size="small"
        :columns="columns"
        :data="rows"
        :loading="loading"
        :pagination="{
          page: query.page,
          pageSize: query.size,
          itemCount: pageTotal,
          showSizePicker: true,
          pageSizes: [10, 20, 50],
          onChange: (p: number) => { query.page = p; fetchList() },
          onUpdatePageSize: (s: number) => { query.size = s; query.page = 1; fetchList() },
        }"
      />
    </Card>

    <n-drawer v-model:show="showDrawer" :width="420" placement="right">
      <n-drawer-content :title="t('community.volunteers.drawerTitle')" closable>
        <div v-if="currentVolunteer" class="space-y-3 text-sm">
          <div>
            <div class="text-slate-500 mb-1">
              {{ t('community.volunteers.colName') }}
            </div>
            <div>{{ currentVolunteer.realName || '-' }}</div>
          </div>
          <div>
            <div class="text-slate-500 mb-1">
              {{ t('community.volunteers.colUsername') }}
            </div>
            <div>{{ currentVolunteer.username }}</div>
          </div>
          <div>
            <div class="text-slate-500 mb-1">
              {{ t('community.volunteers.mobile') }}
            </div>
            <div>{{ currentVolunteer.phone || '-' }}</div>
          </div>
          <div>
            <div class="text-slate-500 mb-1">
              {{ t('community.volunteers.colEmail') }}
            </div>
            <div>{{ currentVolunteer.email || '-' }}</div>
          </div>
          <div>
            <div class="text-slate-500 mb-1">
              {{ t('community.volunteers.colIdentity') }}
            </div>
            <div>{{ identityText(currentVolunteer.identityType) }}</div>
          </div>
          <!-- 如果后端后续在 AdminUserVO 中补充 skillTags/address，可以在这里一并展示 -->
        </div>
      </n-drawer-content>
    </n-drawer>
  </div>
</template>

