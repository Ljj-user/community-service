<script setup lang="ts">
import { createServiceRequest } from '@/api/modules/serviceRequests'
import { toast } from 'vue-sonner'

definePage({
  meta: {
    title: '发布需求',
    auth: true,
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()
const loading = ref(false)
const SERVICE_TYPES = [
  '助老服务（陪护 / 陪诊）',
  '代办服务（买菜 / 取药）',
  '家政清洁',
  '心理陪伴 / 聊天',
  '应急帮助（紧急求助）',
  '社区活动支持',
] as const

const form = reactive<{
  serviceType: (typeof SERVICE_TYPES)[number]
  urgencyLevel: number
  serviceAddress: string
  description: string
  emergencyContactName: string
  emergencyContactPhone: string
  emergencyContactRelation: string
}>({
  serviceType: SERVICE_TYPES[0],
  urgencyLevel: 2,
  serviceAddress: '',
  description: '',
  emergencyContactName: '',
  emergencyContactPhone: '',
  emergencyContactRelation: '',
})

function onGotoStats() {
  router.push({ path: '/hall-overview', query: { kind: 'stats' } })
}

function getDescriptionTemplate(serviceType: string) {
  if (serviceType === '助老服务（陪护 / 陪诊）') {
    return `【服务类型】助老服务（陪护 / 陪诊）
【需求内容】需要陪同老人就医或日常照看
【服务时间】请填写可服务时段
【联系人】请填写姓名与联系电话`
  }
  if (serviceType === '代办服务（买菜 / 取药）') {
    const addressLine = form.serviceAddress.trim() || '请填写具体地址'
    return `【服务类型】代办服务（买菜 / 取药）
【代办事项】请填写需要代办的内容（买菜/取药）
【配送地址】${addressLine}
【联系人】请填写姓名与联系电话`
  }
  if (serviceType === '家政清洁') {
    return `【服务类型】家政清洁
【清洁范围】请填写需要清洁的区域（如厨房/卫生间）
【上门时间】请填写期望上门时间
【备注】如有工具或注意事项请补充`
  }
  if (serviceType === '心理陪伴 / 聊天') {
    return `【服务类型】心理陪伴 / 聊天
【需求说明】希望有人倾听与交流
【陪伴方式】可线下或电话沟通
【时间安排】请填写方便联系的时间`
  }
  if (serviceType === '应急帮助（紧急求助）') {
    return `【服务类型】应急帮助（紧急求助）
【紧急事项】请简要说明当前紧急情况
【所在位置】请填写详细地址与楼栋门牌
【联系方式】请立即填写可联系手机号`
  }
  return `【服务类型】社区活动支持
【活动名称】请填写活动主题
【需要支持】如秩序维护/物资搬运/现场引导
【活动时间地点】请填写具体时间与地点`
}

watch(() => form.serviceType, (nextType) => {
  if (form.description.trim()) return
  form.description = getDescriptionTemplate(nextType)
}, { immediate: true })

watch(() => form.serviceAddress, () => {
  if (form.serviceType !== '代办服务（买菜 / 取药）') return
  if (form.description.trim()) return
  form.description = getDescriptionTemplate(form.serviceType)
})

function plusHours(hours: number) {
  const d = new Date(Date.now() + hours * 60 * 60 * 1000)
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  const hh = String(d.getHours()).padStart(2, '0')
  const mi = String(d.getMinutes()).padStart(2, '0')
  const ss = String(d.getSeconds()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}:${ss}`
}

async function submit() {
  if (loading.value) return
  if (!form.serviceAddress.trim()) return toast.error('请填写服务地址')
  if (!form.emergencyContactName.trim()) return toast.error('请填写联系人姓名')
  if (!form.emergencyContactPhone.trim()) return toast.error('请填写联系人电话')
  loading.value = true
  try {
    const res = await createServiceRequest({
      serviceType: form.serviceType,
      urgencyLevel: form.urgencyLevel,
      serviceAddress: form.serviceAddress.trim(),
      description: form.description.trim() || undefined,
      emergencyContactName: form.emergencyContactName.trim(),
      emergencyContactPhone: form.emergencyContactPhone.trim(),
      emergencyContactRelation: form.emergencyContactRelation.trim() || undefined,
      expectedTime: plusHours(2),
    })
    if (res.code !== 200) throw new Error(res.message || '发布失败')
    toast.success('发布成功，已提交审核')
    router.back()
  }
  catch (e: any) {
    toast.error(e?.message || '发布失败')
  }
  finally {
    loading.value = false
  }
}

function resetTemplate() {
  form.description = getDescriptionTemplate(form.serviceType)
}

onMounted(async () => {
  await appAuthStore.hydrateUser()
  const u = appAuthStore.user
  if (!form.serviceAddress.trim()) form.serviceAddress = (u?.communityName || u?.address || '').trim()
  if (!form.emergencyContactName.trim()) form.emergencyContactName = (u?.realName || u?.username || '').trim()
  resetTemplate()
})
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page m-mobile-page-bg">
      <header class="head">
        <button type="button" class="back" @click="router.back()">
          <FmIcon name="i-carbon:chevron-left" />
        </button>
        <h2>发布需求</h2>
        <button type="button" class="stats-btn" @click="onGotoStats">
          <FmIcon name="mdi:chart-line" />服务统计
        </button>
      </header>

      <section class="form">
        <div class="form-card">
          <div class="label">请选择服务类型</div>
          <div class="type-grid">
            <button
              v-for="type in SERVICE_TYPES"
              :key="type"
              type="button"
              class="type-card"
              :class="{ active: form.serviceType === type }"
              @click="form.serviceType = type"
            >
              <span>{{ type }}</span>
              <span v-if="form.serviceType === type" class="check-mark">✓</span>
            </button>
          </div>
        </div>

        <div class="form-card">
          <div class="label">紧急程度</div>
          <div class="level">
            <button type="button" :class="{ active: form.urgencyLevel === 1 }" @click="form.urgencyLevel = 1">普通</button>
            <button type="button" :class="{ active: form.urgencyLevel === 2 }" @click="form.urgencyLevel = 2">中等</button>
            <button type="button" :class="{ active: form.urgencyLevel >= 3 }" @click="form.urgencyLevel = 4">极紧急</button>
          </div>
        </div>

        <div class="form-card">
          <div class="label">服务地址</div>
          <NutInput v-model="form.serviceAddress" placeholder="如：幸福小区1栋101" />
        </div>

        <div class="form-card">
          <div class="label-row">
            <div class="label">需求描述</div>
            <button type="button" class="template-reset" @click="resetTemplate">重置模板</button>
          </div>
          <NutTextarea v-model="form.description" rows="7" placeholder="请描述需要帮助的内容" />
          <p class="desc-tip">可在模板基础上补充细节</p>
        </div>

        <div class="form-card">
          <div class="label">联系人信息</div>
          <div class="contact-grid">
            <NutInput v-model="form.emergencyContactName" placeholder="联系人姓名（必填）" />
            <NutInput v-model="form.emergencyContactPhone" placeholder="联系人电话（必填）" />
            <NutInput v-model="form.emergencyContactRelation" placeholder="与服务对象关系（选填）" />
          </div>
        </div>
      </section>

      <button class="submit-btn" :disabled="loading" @click="submit">
        {{ loading ? '提交中...' : '提交发布' }}
      </button>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.page { min-height: 100%; padding: 12px; display: grid; gap: 12px; }
.head { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 10px; }
.back { width: 34px; height: 34px; border: 1px solid var(--m-color-border); border-radius: 10px; background: var(--m-color-card); display: inline-flex; align-items: center; justify-content: center; }
.head h2 { margin: 0; font-size: 18px; color: var(--m-color-text); font-weight: 900; }
.stats-btn { height: 34px; border: 0; border-radius: 10px; padding: 0 10px; color: #fff; font-size: 12px; font-weight: 900; display: inline-flex; align-items: center; gap: 6px; background: linear-gradient(135deg, #0f766e 0%, #059669 100%); }
.form { display: grid; gap: 10px; }
.form-card {
  position: relative;
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  padding: 12px;
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.04);
}
.label { margin-bottom: 8px; color: #0f172a; font-size: 13px; font-weight: 700; }
.label-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
.template-reset { border: 1px solid #cbd5e1; border-radius: 999px; background: #fff; font-size: 11px; color: #334155; padding: 3px 10px; }
.type-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.type-card {
  border: 1px solid #d1d5db; border-radius: 10px; background: #fff; color: #374151; padding: 10px 12px; font-size: 12px; line-height: 1.35;
  text-align: left; min-height: 56px; display: flex; justify-content: space-between; align-items: flex-start;
}
.type-card.active { border-color: #10b981; background: #ecfdf5; color: #065f46; box-shadow: 0 2px 8px rgba(16, 185, 129, 0.2); }
.check-mark { font-weight: 800; color: #059669; }
.desc-tip { margin: 6px 0 0; color: #64748b; font-size: 12px; }
.contact-grid { display: grid; gap: 8px; }
.level { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.level button { border: 1px solid #d1d5db; background: #fff; border-radius: 10px; padding: 8px 0; color: #4b5563; }
.level button.active { border-color: #10b981; color: #047857; background: #ecfdf5; font-weight: 800; }
.submit-btn {
  height: 46px; border: 0; border-radius: 12px; color: #fff; font-size: 15px; font-weight: 900;
  background: linear-gradient(140deg, #1fa34a 0%, #14803b 100%);
}
.submit-btn:disabled { opacity: .6; }
</style>
