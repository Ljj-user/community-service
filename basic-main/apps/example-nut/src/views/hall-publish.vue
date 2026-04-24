<script setup lang="ts">
import { createServiceRequest } from '@/api/modules/serviceRequests'

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

const form = reactive({
  serviceType: SERVICE_TYPES[0],
  urgencyLevel: 2,
  serviceAddress: '',
  description: '',
  emergencyContactName: '',
  emergencyContactPhone: '',
  emergencyContactRelation: '',
})

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
  if (form.description.trim()) {
    return
  }
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
  if (!form.serviceAddress.trim()) {
    window.alert('请填写服务地址')
    return
  }
  if (!form.emergencyContactName.trim()) {
    window.alert('请填写联系人姓名')
    return
  }
  if (!form.emergencyContactPhone.trim()) {
    window.alert('请填写联系人电话')
    return
  }
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
      // 移动端当前未提供时间控件，先给默认预约时间（当前+2小时）
      expectedTime: plusHours(2),
    })
    if (res.code !== 200) {
      window.alert(res.message || '发布失败')
      return
    }
    window.alert('发布成功，已提交审核')
    router.back()
  }
  catch (e: any) {
    window.alert(e?.message || '发布失败')
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
  if (!form.serviceAddress.trim()) {
    form.serviceAddress = (u?.communityName || u?.address || '').trim()
  }
  if (!form.emergencyContactName.trim()) {
    form.emergencyContactName = (u?.realName || u?.username || '').trim()
  }
  resetTemplate()
})
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page">
      <header class="m-topbar">
        <button class="m-back" @click="router.back()">
          返回
        </button>
        <h2 class="m-top-title">发布需求</h2>
      </header>

      <section class="pub-hero" aria-hidden="true">
        <div class="pub-hero-glow" />
        <div class="pub-hero-inner">
          <span class="pub-badge">互助</span>
          <p class="pub-hero-title">
            向社区发起一条需求
          </p>
          <p class="pub-hero-desc">
            填写后会真实提交到后端，进入审核流程
          </p>
        </div>
      </section>

      <div class="pub-form">
        <div class="form-card">
          <div class="label">
            请选择服务类型
          </div>
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
          <div class="label">
            紧急程度
          </div>
          <div class="level">
            <button type="button" :class="{ active: form.urgencyLevel === 1 }" @click="form.urgencyLevel = 1">
              普通
            </button>
            <button type="button" :class="{ active: form.urgencyLevel === 2 }" @click="form.urgencyLevel = 2">
              中等
            </button>
            <button type="button" :class="{ active: form.urgencyLevel >= 3 }" @click="form.urgencyLevel = 4">
              极紧急
            </button>
          </div>
        </div>

        <div class="form-card">
          <div class="label">
            服务地址
          </div>
          <NutInput v-model="form.serviceAddress" placeholder="如：幸福小区1栋101" />
        </div>

        <div class="form-card">
          <div class="label-row">
            <div class="label">
              需求描述
            </div>
            <button type="button" class="template-reset" @click="resetTemplate">
              重置模板
            </button>
          </div>
          <NutTextarea v-model="form.description" rows="7" placeholder="请描述需要帮助的内容" />
          <p class="desc-tip">
            可在模板基础上补充细节
          </p>
        </div>

        <div class="form-card">
          <div class="label">
            联系人信息
          </div>
          <div class="contact-grid">
            <NutInput v-model="form.emergencyContactName" placeholder="联系人姓名（必填）" />
            <NutInput v-model="form.emergencyContactPhone" placeholder="联系人电话（必填）" />
            <NutInput v-model="form.emergencyContactRelation" placeholder="与服务对象关系（选填）" />
          </div>
        </div>
      </div>

      <div class="pub-actions">
        <NutButton block type="primary" class="submit-btn" :loading="loading" @click="submit">
          提交发布
        </NutButton>
      </div>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.page {
  min-height: 100%;
  background: var(--m-color-bg);
  padding: var(--m-space-page);
  padding-bottom: calc(var(--m-space-page) + env(safe-area-inset-bottom, 0px));
  display: flex;
  flex-direction: column;
  gap: 12px;
  box-sizing: border-box;
}

.pub-hero {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid #6ee7b7;
  background: linear-gradient(135deg, #047857 0%, #10b981 45%, #34d399 100%);
  color: #fff;
  padding: 14px 14px 16px;
  flex-shrink: 0;
}
.pub-hero-glow {
  position: absolute;
  right: -40px;
  top: -36px;
  width: 120px;
  height: 120px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.18);
  pointer-events: none;
}
.pub-hero-inner { position: relative; z-index: 1; }
.pub-badge {
  display: inline-block;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.06em;
  padding: 3px 8px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.22);
  border: 1px solid rgba(255, 255, 255, 0.35);
}
.pub-hero-title {
  margin: 10px 0 0;
  font-size: 17px;
  font-weight: 900;
  line-height: 1.25;
}
.pub-hero-desc {
  margin: 6px 0 0;
  font-size: 12px;
  line-height: 1.45;
  opacity: 0.95;
}

.pub-form {
  display: grid;
  gap: 10px;
  flex: 1;
  min-height: 0;
}
.form-card {
  position: relative;
  background: linear-gradient(160deg, #ffffff 0%, #f0fdf4 100%);
  border: 1px solid #d1fae5;
  border-radius: 14px;
  padding: 12px;
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.04);
  overflow: hidden;
}
.form-card::before {
  content: '';
  position: absolute;
  right: -24px;
  bottom: -28px;
  width: 72px;
  height: 72px;
  border-radius: 999px;
  background: rgba(16, 185, 129, 0.1);
  pointer-events: none;
}
.label {
  position: relative;
  z-index: 1;
  margin-bottom: 8px;
  color: #047857;
  font-size: 13px;
  font-weight: 700;
}
.label-row {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}
.template-reset {
  border: 1px solid #cbd5e1;
  border-radius: 999px;
  background: #fff;
  font-size: 11px;
  color: #334155;
  padding: 3px 10px;
}
.type-grid {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.type-card {
  border: 1px solid #d1d5db;
  border-radius: 10px;
  background: #fff;
  color: #374151;
  padding: 10px 12px;
  font-size: 12px;
  line-height: 1.35;
  text-align: left;
  min-height: 56px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}
.type-card.active {
  border-color: #10b981;
  background: #ecfdf5;
  color: #065f46;
  box-shadow: 0 2px 8px rgba(16, 185, 129, 0.2);
}
.check-mark { font-weight: 800; color: #059669; }
.desc-tip {
  position: relative;
  z-index: 1;
  margin: 6px 0 0;
  color: #64748b;
  font-size: 12px;
}
.contact-grid {
  position: relative;
  z-index: 1;
  display: grid;
  gap: 8px;
}
.level {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
}
.level button {
  border: 1px solid #d1d5db;
  background: #fff;
  border-radius: 10px;
  padding: 8px 0;
  color: #4b5563;
}
.level button.active {
  border-color: #10b981;
  color: #047857;
  background: #ecfdf5;
  font-weight: 800;
  box-shadow: 0 2px 8px rgba(16, 185, 129, 0.2);
}

.pub-actions { flex-shrink: 0; }
.submit-btn {
  border-radius: 12px !important;
  font-weight: 800 !important;
  box-shadow: 0 6px 20px rgba(16, 185, 129, 0.35) !important;
}

:global(.dark) .page { background: #111827; }
:global(.dark) .back { background: #1f2937; color: #f3f4f6; border: 1px solid #374151; }
:global(.dark) .top h2 { color: #f3f4f6; }
:global(.dark) .pub-hero {
  border-color: #14532d;
  background: linear-gradient(135deg, #064e3b 0%, #047857 50%, #059669 100%);
}
:global(.dark) .form-card {
  background: linear-gradient(160deg, #1f2937 0%, #052e26 100%);
  border-color: #14532d;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
}
:global(.dark) .label { color: #6ee7b7; }
:global(.dark) .level button {
  background: #0f172a;
  border-color: #4b5563;
  color: #d1d5db;
}
:global(.dark) .level button.active {
  background: #065f46;
  border-color: #10b981;
  color: #ecfdf5;
}
::global(.dark) .template-reset { background: #111827; border-color: #4b5563; color: #d1d5db; }
::global(.dark) .type-card { background: #0f172a; border-color: #4b5563; color: #d1d5db; }
::global(.dark) .type-card.active { background: #065f46; border-color: #10b981; color: #ecfdf5; }
::global(.dark) .desc-tip { color: #9ca3af; }
</style>
