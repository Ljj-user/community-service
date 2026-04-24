<route lang="yaml">
meta:
  title: admin-config
  layout: default
  breadcrumb:
    - adminSystemGroup
    - admin-config
</route>

<script setup lang="ts">
/**
 * 系统配置管理
 * 根据流程图：基础参数、通知模板、预警规则设置
 * 结合思维导图：积分规则、风控策略、响应时效、服务定价等
 */
import {
  configGetBasic,
  configSaveBasic,
  configGetNotice,
  configSaveNotice,
  configGetAlert,
  configSaveAlert,
} from '~/api/adminConfig'

const { t } = useI18n()
const message = useMessage()
const loading = ref(true)

// 基础参数（来自思维导图：积分通兑、服务定价、响应时效、风控开关）
const basicParams = reactive({
  // 积分规则：服务1小时=10积分
  pointsPerHour: 10,
  // 社区管理员需求分类标注时效（小时）
  demandClassifyHours: 2,
  // 居民满意度回访时效（天）
  feedbackDays: 3,
  // 居民与志愿者首次对接须经社区管理员视频见证
  requireVideoWitness: true,
  // 敏感操作需二次短信验证
  requireSmsVerify: true,
  // 高风险项目人工复核与双签
  requireDoubleSign: true,
  // 数字无障碍：语音输入
  enableVoiceInput: true,
  // 数字无障碍：大字模式
  enableLargeText: true,
  // 电话预约与社区代办通道
  enablePhoneBooking: true,
})

// 通知模板
const noticeTemplates = reactive({
  smsVerify: '【社区公益平台】您的验证码为：{code}，5分钟内有效，请勿泄露。',
  demandApproved: '【社区公益平台】您发布的需求「{title}」已通过审核，已进入志愿者匹配阶段。',
  demandRejected: '【社区公益平台】您发布的需求「{title}」未通过审核，原因：{reason}。',
  volunteerApproved: '【社区公益平台】您的志愿者申请已通过审核，可开始浏览并认领服务需求。',
  volunteerRejected: '【社区公益平台】您的志愿者申请未通过审核，如有疑问请联系社区管理员。',
  demandMatched: '【社区公益平台】您的需求「{title}」已匹配志愿者，请留意服务进度。',
})

// 预警规则（来自思维导图：超时未响应、履约率、投诉率、爽约冻结）
const alertRules = reactive({
  // 需求超时未认领预警（小时）
  demandUnclaimedHours: 24,
  // 服务超时未完成预警（小时）
  serviceUnfinishedHours: 48,
  // 履约率预警阈值（低于该比例触发）
  fulfillmentRateThreshold: 0.8,
  // 投诉率预警阈值（高于该比例触发）
  complaintRateThreshold: 0.05,
  // 居民恶意爽约次数触发服务冻结
  noShowFreezeCount: 3,
  // 启用超时未认领预警
  enableUnclaimedAlert: true,
  // 启用超时未完成预警
  enableUnfinishedAlert: true,
  // 启用履约率预警
  enableFulfillmentAlert: true,
  // 启用投诉率预警
  enableComplaintAlert: true,
  // 重点人群连续未登录预警（天）
  careInactivityDays: 3,
  // 社区24小时求助骤增预警：最低触发数量
  surge24hMinRequests: 5,
  // 社区24小时求助骤增预警：相对7天均值倍数
  surgeMultiplier: 2,
  // 启用重点人群连续未登录预警
  enableCareInactivityAlert: true,
  // 启用社区求助骤增预警
  enableDemandSurgeAlert: true,
})

const saving = ref(false)

async function loadConfig() {
  loading.value = true
  try {
    const [basicRes, noticeRes, alertRes] = await Promise.all([
      configGetBasic(),
      configGetNotice(),
      configGetAlert(),
    ])
    if (basicRes?.data && typeof basicRes.data === 'object') {
      Object.assign(basicParams, basicRes.data)
    }
    if (noticeRes?.data && typeof noticeRes.data === 'object') {
      Object.assign(noticeTemplates, noticeRes.data)
    }
    if (alertRes?.data && typeof alertRes.data === 'object') {
      Object.assign(alertRules, alertRes.data)
    }
  } catch (e) {
    message.error(t('community.systemConfig.loadFailed'))
  } finally {
    loading.value = false
  }
}

async function handleSaveBasic() {
  saving.value = true
  try {
    const res = await configSaveBasic({ ...basicParams })
    message.success(res?.message || t('community.systemConfig.saveOkBasic'))
  } catch (e) {
    message.error(t('community.systemConfig.saveFailed'))
  } finally {
    saving.value = false
  }
}

async function handleSaveNotice() {
  saving.value = true
  try {
    const res = await configSaveNotice({ ...noticeTemplates })
    message.success(res?.message || t('community.systemConfig.saveOkNotice'))
  } catch (e) {
    message.error(t('community.systemConfig.saveFailed'))
  } finally {
    saving.value = false
  }
}

async function handleSaveAlert() {
  saving.value = true
  try {
    const res = await configSaveAlert({ ...alertRules })
    message.success(res?.message || t('community.systemConfig.saveOkAlert'))
  } catch (e) {
    message.error(t('community.systemConfig.saveFailed'))
  } finally {
    saving.value = false
  }
}

onMounted(loadConfig)
</script>

<template>
  <div class="space-y-4">
    <h1 class="text-xl font-semibold">
      {{ t('community.systemConfig.title') }}
    </h1>
    <p class="text-sm text-slate-500 dark:text-slate-400">
      {{ t('community.systemConfig.subtitle') }}
    </p>

    <n-spin :show="loading">
      <n-collapse default-expanded-names="basic">
      <!-- 一、基础参数 -->
      <n-collapse-item name="basic" :title="t('community.systemConfig.collapseBasic')">
        <template #header-extra>
          <n-button size="small" type="primary" :loading="saving" @click.stop="handleSaveBasic">
            {{ t('community.systemConfig.btnSave') }}
          </n-button>
        </template>
        <Card :title="t('community.systemConfig.cardBusiness')">
          <div class="grid gap-x-8 gap-y-6 sm:grid-cols-2">
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.pointsPerHour')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="basicParams.pointsPerHour" :min="1" :max="100" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.pointsPerHourHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.demandClassifyHours')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="basicParams.demandClassifyHours" :min="1" :max="72" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.demandClassifyHoursHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.feedbackDays')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="basicParams.feedbackDays" :min="1" :max="30" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.feedbackDaysHint') }}
              </p>
            </div>
          </div>
        </Card>
        <Card :title="t('community.systemConfig.cardCompliance')" class="mt-4">
          <div class="space-y-5">
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.requireVideoWitness')" label-placement="top" :show-feedback="false">
                <n-switch v-model:value="basicParams.requireVideoWitness" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.requireVideoWitnessHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.requireSmsVerify')" label-placement="top" :show-feedback="false">
                <n-switch v-model:value="basicParams.requireSmsVerify" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.requireSmsVerifyHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.requireDoubleSign')" label-placement="top" :show-feedback="false">
                <n-switch v-model:value="basicParams.requireDoubleSign" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.requireDoubleSignHint') }}
              </p>
            </div>
          </div>
        </Card>
        <Card :title="t('community.systemConfig.cardA11y')" class="mt-4">
          <div class="space-y-5">
            <n-form-item :label="t('community.systemConfig.enableVoiceInput')" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="basicParams.enableVoiceInput" />
            </n-form-item>
            <n-form-item :label="t('community.systemConfig.enableLargeText')" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="basicParams.enableLargeText" />
            </n-form-item>
            <n-form-item :label="t('community.systemConfig.enablePhoneBooking')" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="basicParams.enablePhoneBooking" />
            </n-form-item>
          </div>
        </Card>
      </n-collapse-item>

      <!-- 二、通知模板 -->
      <n-collapse-item name="notice" :title="t('community.systemConfig.collapseNotice')">
        <template #header-extra>
          <n-button size="small" type="primary" :loading="saving" @click.stop="handleSaveNotice">
            {{ t('community.systemConfig.btnSave') }}
          </n-button>
        </template>
        <n-alert type="info" class="mb-4" :bordered="false">
          {{ t('community.systemConfig.noticePlaceholderHint') }}
        </n-alert>
        <div class="space-y-5">
          <n-form-item :label="t('community.systemConfig.tplSmsVerify')" label-placement="top" :show-feedback="false">
            <n-input v-model:value="noticeTemplates.smsVerify" type="textarea" :rows="2" :placeholder="t('community.systemConfig.phSmsVerify')" />
          </n-form-item>
          <n-form-item :label="t('community.systemConfig.tplDemandApproved')" label-placement="top" :show-feedback="false">
            <n-input v-model:value="noticeTemplates.demandApproved" type="textarea" :rows="2" :placeholder="t('community.systemConfig.phDemandApproved')" />
          </n-form-item>
          <n-form-item :label="t('community.systemConfig.tplDemandRejected')" label-placement="top" :show-feedback="false">
            <n-input v-model:value="noticeTemplates.demandRejected" type="textarea" :rows="2" :placeholder="t('community.systemConfig.phDemandRejected')" />
          </n-form-item>
          <n-form-item :label="t('community.systemConfig.tplVolunteerApproved')" label-placement="top" :show-feedback="false">
            <n-input v-model:value="noticeTemplates.volunteerApproved" type="textarea" :rows="2" :placeholder="t('community.systemConfig.phVolunteerApproved')" />
          </n-form-item>
          <n-form-item :label="t('community.systemConfig.tplVolunteerRejected')" label-placement="top" :show-feedback="false">
            <n-input v-model:value="noticeTemplates.volunteerRejected" type="textarea" :rows="2" :placeholder="t('community.systemConfig.phVolunteerRejected')" />
          </n-form-item>
          <n-form-item :label="t('community.systemConfig.tplDemandMatched')" label-placement="top" :show-feedback="false">
            <n-input v-model:value="noticeTemplates.demandMatched" type="textarea" :rows="2" :placeholder="t('community.systemConfig.phDemandMatched')" />
          </n-form-item>
        </div>
      </n-collapse-item>

      <!-- 三、预警规则 -->
      <n-collapse-item name="alert" :title="t('community.systemConfig.collapseAlert')">
        <template #header-extra>
          <n-button size="small" type="primary" :loading="saving" @click.stop="handleSaveAlert">
            {{ t('community.systemConfig.btnSave') }}
          </n-button>
        </template>
        <Card :title="t('community.systemConfig.cardTimeout')">
          <div class="grid gap-x-8 gap-y-6 sm:grid-cols-2">
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.demandUnclaimedHours')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="alertRules.demandUnclaimedHours" :min="1" :max="168" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.demandUnclaimedHoursHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.serviceUnfinishedHours')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="alertRules.serviceUnfinishedHours" :min="1" :max="336" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.serviceUnfinishedHoursHint') }}
              </p>
            </div>
            <n-form-item :label="t('community.systemConfig.enableUnclaimedAlert')" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="alertRules.enableUnclaimedAlert" />
            </n-form-item>
            <n-form-item :label="t('community.systemConfig.enableUnfinishedAlert')" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="alertRules.enableUnfinishedAlert" />
            </n-form-item>
          </div>
        </Card>
        <Card :title="t('community.systemConfig.cardKpi')" class="mt-4">
          <div class="grid gap-x-8 gap-y-6 sm:grid-cols-2">
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.fulfillmentRateThreshold')" label-placement="top" :show-feedback="false">
                <n-input-number
                  v-model:value="alertRules.fulfillmentRateThreshold"
                  :min="0"
                  :max="1"
                  :step="0.05"
                  :precision="2"
                  class="w-full"
                />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.fulfillmentRateHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.complaintRateThreshold')" label-placement="top" :show-feedback="false">
                <n-input-number
                  v-model:value="alertRules.complaintRateThreshold"
                  :min="0"
                  :max="1"
                  :step="0.01"
                  :precision="2"
                  class="w-full"
                />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.complaintRateHint') }}
              </p>
            </div>
            <n-form-item :label="t('community.systemConfig.enableFulfillmentAlert')" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="alertRules.enableFulfillmentAlert" />
            </n-form-item>
            <n-form-item :label="t('community.systemConfig.enableComplaintAlert')" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="alertRules.enableComplaintAlert" />
            </n-form-item>
          </div>
        </Card>
        <Card :title="t('community.systemConfig.cardCredit')" class="mt-4">
          <div class="config-field max-w-xs">
            <n-form-item :label="t('community.systemConfig.noShowFreezeCount')" label-placement="top" :show-feedback="false">
              <n-input-number v-model:value="alertRules.noShowFreezeCount" :min="1" :max="10" class="w-full" />
            </n-form-item>
            <p class="text-xs text-slate-500 mt-1">
              {{ t('community.systemConfig.noShowFreezeHint') }}
            </p>
          </div>
        </Card>
        <Card :title="t('community.systemConfig.cardAnomaly')" class="mt-4">
          <div class="grid gap-x-8 gap-y-6 sm:grid-cols-2">
            <n-form-item label="启用重点人群连续未登录预警" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="alertRules.enableCareInactivityAlert" />
            </n-form-item>
            <n-form-item label="启用社区求助骤增预警" label-placement="top" :show-feedback="false">
              <n-switch v-model:value="alertRules.enableDemandSurgeAlert" />
            </n-form-item>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.careInactivityDays')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="alertRules.careInactivityDays" :min="1" :max="30" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.careInactivityDaysHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.surge24hMinRequests')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="alertRules.surge24hMinRequests" :min="1" :max="200" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.surge24hMinRequestsHint') }}
              </p>
            </div>
            <div class="config-field">
              <n-form-item :label="t('community.systemConfig.surgeMultiplier')" label-placement="top" :show-feedback="false">
                <n-input-number v-model:value="alertRules.surgeMultiplier" :min="1" :max="10" :step="0.1" :precision="1" class="w-full" />
              </n-form-item>
              <p class="text-xs text-slate-500 mt-1">
                {{ t('community.systemConfig.surgeMultiplierHint') }}
              </p>
            </div>
          </div>
        </Card>
      </n-collapse-item>
    </n-collapse>
    </n-spin>
  </div>
</template>

<style scoped>
.config-field {
  display: flex;
  flex-direction: column;
  gap: 0;
}
.config-field :deep(.n-form-item) {
  margin-bottom: 0;
}
</style>
