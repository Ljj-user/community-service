<route lang="yaml">
meta:
  title: communityRequests
  layout: default
  breadcrumb:
    - adminOpsGroup
    - communityRequests
</route>

<script setup lang="ts">
import type { DataTableColumns, FormInst } from 'naive-ui'
import {
  serviceRequestAudit,
  serviceRequestDetail,
  serviceRequestList,
  type ServiceRequestVO,
} from '~/api/serviceRequests'
import {
  CheckmarkCircle20Regular,
  DismissCircle20Regular,
  Eye20Regular,
} from '@vicons/fluent'
import { computed, h, resolveComponent } from 'vue'
import { dtActionBtn, dtActionRowClass } from '~/utils/dataTableActions'

const { t, locale } = useI18n()
const message = useMessage()
const dialog = useDialog()

const loading = ref(false)
const query = reactive({
  status: 0 as number | null,
  urgencyLevel: null as number | null,
  serviceType: '',
  current: 1,
  size: 10,
})

const pageTotal = ref(0)
const rows = ref<ServiceRequestVO[]>([])

const showDrawer = ref(false)
const detailLoading = ref(false)
const detail = ref<ServiceRequestVO | null>(null)

const rejectModal = ref(false)
const rejectFormRef = ref<FormInst | null>(null)
const rejectForm = reactive({
  requestId: null as number | null,
  rejectReason: '',
})

const statusOptions = computed(() => [
  { label: t('community.requests.statusPending'), value: 0 },
  { label: t('community.requests.statusPublished'), value: 1 },
  { label: t('community.requests.statusClaimed'), value: 2 },
  { label: t('community.requests.statusCompleted'), value: 3 },
  { label: t('community.requests.statusRejected'), value: 4 },
])

const urgencyOptions = computed(() => [
  { label: t('community.monitor.urgencyLow'), value: 1 },
  { label: t('community.monitor.urgencyMid'), value: 2 },
  { label: t('community.monitor.urgencyHigh'), value: 3 },
  { label: t('community.monitor.urgencyUrgent'), value: 4 },
])

function statusText(v: number) {
  return statusOptions.value.find(x => x.value === v)?.label || String(v)
}

function statusTagType(v: number) {
  if (v === 0) return 'warning'
  if (v === 1) return 'info'
  if (v === 2) return 'default'
  if (v === 3) return 'success'
  return 'error'
}

function urgencyText(v: number) {
  return urgencyOptions.value.find(x => x.value === v)?.label || String(v)
}

function urgencyTagType(v: number) {
  if (v === 4) return 'error'
  if (v === 3) return 'warning'
  if (v === 2) return 'info'
  return 'default'
}

function dateLocale() {
  return locale.value === 'zn' ? 'zh-CN' : 'en-US'
}

async function fetchList() {
  loading.value = true
  try {
    const res = await serviceRequestList({
      status: query.status ?? undefined,
      urgencyLevel: query.urgencyLevel ?? undefined,
      serviceType: query.serviceType || undefined,
      current: query.current,
      size: query.size,
    })
    if (res.code !== 200) {
      message.error(res.message || t('community.requests.loadFailed'))
      return
    }
    rows.value = res.data.records || []
    pageTotal.value = res.data.total || 0
  } catch (e: any) {
    message.error(e?.message || t('community.requests.loadFailed'))
  } finally {
    loading.value = false
  }
}

function resetQuery() {
  query.status = 0
  query.urgencyLevel = null
  query.serviceType = ''
  query.current = 1
  fetchList()
}

async function openDetail(row: ServiceRequestVO) {
  showDrawer.value = true
  detail.value = row
  detailLoading.value = true
  try {
    const res = await serviceRequestDetail(row.id)
    if (res.code === 200) {
      detail.value = res.data
    }
  } catch {
    // ignore
  } finally {
    detailLoading.value = false
  }
}

async function approve(row: ServiceRequestVO) {
  dialog.warning({
    title: t('community.requests.approveTitle'),
    content: t('community.requests.approveBody', { name: row.serviceType }),
    positiveText: t('community.requests.approve'),
    negativeText: t('common.cancel'),
    async onPositiveClick() {
      const res = await serviceRequestAudit({ requestId: row.id, approved: true })
      if (res.code !== 200) {
        message.error(res.message || t('community.requests.opFailed'))
        return
      }
      message.success(res.message || t('community.requests.approveOk'))
      showDrawer.value = false
      fetchList()
    },
  })
}

function openReject(row: ServiceRequestVO) {
  rejectForm.requestId = row.id
  rejectForm.rejectReason = ''
  rejectModal.value = true
}

async function submitReject() {
  await rejectFormRef.value?.validate()
  const res = await serviceRequestAudit({
    requestId: rejectForm.requestId!,
    approved: false,
    rejectReason: rejectForm.rejectReason,
  })
  if (res.code !== 200) {
    message.error(res.message || t('community.requests.opFailed'))
    return
  }
  message.success(res.message || t('community.requests.rejectOk'))
  rejectModal.value = false
  showDrawer.value = false
  fetchList()
}

const rejectRules = computed(() => ({
  rejectReason: {
    required: true,
    message: t('community.requests.rejectReason'),
    trigger: ['input', 'blur'],
  },
}))

const columns = computed<DataTableColumns<ServiceRequestVO>>(() => {
  void locale.value
  return [
    { title: 'ID', key: 'id', width: 90 },
    { title: t('community.requests.colServiceType'), key: 'serviceType', minWidth: 130 },
    { title: '所属社区', key: 'communityName', minWidth: 120, render: (r) => r.communityName || '-' },
    { title: t('community.requests.colResident'), key: 'requesterName', width: 120, render: (r) => r.requesterName || '-' },
    { title: t('community.requests.colAddress'), key: 'serviceAddress', minWidth: 200, ellipsis: { tooltip: true } },
    {
      title: t('community.requests.colUrgency'),
      key: 'urgencyLevel',
      width: 110,
      render: (r) =>
        h(
          resolveComponent('NTag') as any,
          { size: 'small', type: urgencyTagType(r.urgencyLevel), bordered: false },
          { default: () => urgencyText(r.urgencyLevel) },
        ),
    },
    {
      title: t('community.requests.colStatus'),
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
      title: t('community.requests.colSubmitted'),
      key: 'createdAt',
      width: 170,
      render: (r) => (r.createdAt ? new Date(r.createdAt).toLocaleString(dateLocale()) : '-'),
    },
    {
      title: t('community.requests.colActions'),
      key: 'actions',
      width: 220,
      render: (r) =>
        h('div', { class: dtActionRowClass }, [
          dtActionBtn(
            t('community.requests.viewDetail'),
            { type: 'info', onClick: () => openDetail(r) },
            Eye20Regular,
          ),
          ...(r.status === 0
            ? [
                dtActionBtn(
                  t('community.requests.approve'),
                  { type: 'success', onClick: () => approve(r) },
                  CheckmarkCircle20Regular,
                ),
                dtActionBtn(
                  t('community.requests.reject'),
                  { type: 'error', onClick: () => openReject(r) },
                  DismissCircle20Regular,
                ),
              ]
            : []),
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
          {{ t('community.requests.title') }}
        </h1>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          {{ t('community.requests.subtitle') }}
        </p>
      </div>
    </div>

    <Card>
      <div class="grid gap-3 md:grid-cols-4">
        <n-select v-model:value="query.status" :options="statusOptions" :placeholder="t('community.requests.statusPlaceholder')" clearable />
        <n-select v-model:value="query.urgencyLevel" :options="urgencyOptions" :placeholder="t('community.requests.urgencyPlaceholder')" clearable />
        <n-input v-model:value="query.serviceType" :placeholder="t('community.requests.serviceTypePlaceholder')" clearable />
        <div class="flex gap-2">
          <n-button type="primary" :loading="loading" @click="() => { query.current = 1; fetchList() }">
            {{ t('community.users.query') }}
          </n-button>
          <n-button @click="resetQuery">
            {{ t('community.users.reset') }}
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
          page: query.current,
          pageSize: query.size,
          itemCount: pageTotal,
          showSizePicker: true,
          pageSizes: [10, 20, 50],
          onChange: (p: number) => { query.current = p; fetchList() },
          onUpdatePageSize: (s: number) => { query.size = s; query.current = 1; fetchList() },
        }"
      />
    </Card>

    <n-drawer v-model:show="showDrawer" :width="520" placement="right">
      <n-drawer-content :title="t('community.requests.drawerTitle')" closable>
        <n-spin :show="detailLoading">
          <template v-if="detail">
            <div class="space-y-4 text-sm">
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <div class="text-slate-500 mb-1">
                    {{ t('community.requests.colStatus') }}
                  </div>
                  <n-tag :type="statusTagType(detail.status)" size="small">
                    {{ statusText(detail.status) }}
                  </n-tag>
                </div>
                <div>
                  <div class="text-slate-500 mb-1">
                    {{ t('community.requests.colUrgency') }}
                  </div>
                  <n-tag :type="urgencyTagType(detail.urgencyLevel)" size="small">
                    {{ urgencyText(detail.urgencyLevel) }}
                  </n-tag>
                </div>
              </div>

              <div>
                <div class="text-slate-500 mb-1">
                  {{ t('community.requests.colServiceType') }}
                </div>
                <div>{{ detail.serviceType }}</div>
              </div>
              <div>
                <div class="text-slate-500 mb-1">
                  所属社区
                </div>
                <div>{{ detail.communityName || '-' }}</div>
              </div>
              <div>
                <div class="text-slate-500 mb-1">
                  {{ t('community.requests.labelServiceAddr') }}
                </div>
                <div>{{ detail.serviceAddress }}</div>
              </div>
              <div v-if="detail.expectedTime">
                <div class="text-slate-500 mb-1">
                  {{ t('community.requests.labelExpectedTime') }}
                </div>
                <div>{{ new Date(detail.expectedTime).toLocaleString(dateLocale()) }}</div>
              </div>
              <div v-if="detail.requesterName">
                <div class="text-slate-500 mb-1">
                  {{ t('community.requests.colResident') }}
                </div>
                <div>{{ detail.requesterName }}</div>
              </div>
              <div v-if="detail.specialTags?.length">
                <div class="text-slate-500 mb-1">
                  {{ t('community.requests.specialTags') }}
                </div>
                <div class="flex flex-wrap gap-2">
                  <n-tag v-for="tag in detail.specialTags" :key="tag" size="small">
                    {{ tag }}
                  </n-tag>
                </div>
              </div>
              <div v-if="detail.description">
                <div class="text-slate-500 mb-1">
                  {{ t('community.requests.description') }}
                </div>
                <div class="whitespace-pre-wrap break-words">
                  {{ detail.description }}
                </div>
              </div>
              <div v-if="detail.status === 4 && detail.rejectReason">
                <div class="text-slate-500 mb-1">
                  {{ t('community.requests.rejectLabel') }}
                </div>
                <div class="text-red-500 whitespace-pre-wrap break-words">
                  {{ detail.rejectReason }}
                </div>
              </div>

              <div v-if="detail.status === 0" class="pt-2 flex gap-2 justify-end">
                <n-button type="error" ghost @click="openReject(detail)">
                  {{ t('community.requests.reject') }}
                </n-button>
                <n-button type="success" @click="approve(detail)">
                  {{ t('community.requests.approvePublish') }}
                </n-button>
              </div>
            </div>
          </template>
        </n-spin>
      </n-drawer-content>
    </n-drawer>

    <n-modal v-model:show="rejectModal" preset="card" :title="t('community.requests.rejectModalTitle')" style="width: 560px">
      <n-form ref="rejectFormRef" :model="rejectForm" :rules="rejectRules" label-placement="top">
        <n-form-item path="rejectReason" :label="t('community.requests.rejectLabel')">
          <n-input v-model:value="rejectForm.rejectReason" type="textarea" :rows="4" :placeholder="t('community.requests.rejectPlaceholder')" />
        </n-form-item>
        <div class="flex justify-end gap-2">
          <n-button @click="rejectModal = false">
            {{ t('common.cancel') }}
          </n-button>
          <n-button type="error" @click="submitReject">
            {{ t('community.requests.confirmReject') }}
          </n-button>
        </div>
      </n-form>
    </n-modal>
  </div>
</template>
