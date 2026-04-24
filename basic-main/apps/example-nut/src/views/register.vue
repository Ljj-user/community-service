<script setup lang="ts">
import apiApp from '@/api/modules/app'
import { updateMyProfile } from '@/api/modules/profile'

definePage({
  name: 'register',
  meta: { title: '注册' },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()
const loading = ref(false)
const sending = ref(false)
const countdown = ref(0)
const step = ref<'pick' | 'form'>('pick')
const identityType = ref<1 | 2>(1)
const otherSkillEnabled = ref(false)
const selectedSkills = ref<string[]>([])
const customSkill = ref('')
let timer: any = null

const skillTemplates = ['陪诊', '助老照护', '跑腿代办', '家电维修', '心理陪伴']

const form = reactive({
  username: '',
  realName: '',
  phone: '',
  email: '',
  verificationCode: '',
  address: '',
  password: '',
  confirmPassword: '',
})

const isVolunteer = computed(() => identityType.value === 2)

function pickIdentity(v: 1 | 2) {
  identityType.value = v
  step.value = 'form'
}

function backToPick() {
  step.value = 'pick'
}

function toSkillText() {
  const list = [...selectedSkills.value]
  if (otherSkillEnabled.value && customSkill.value.trim())
    list.push(customSkill.value.trim())
  return Array.from(new Set(list)).join(',')
}

function validateForm() {
  if (!form.username.trim()) return '请输入用户名'
  if (!form.realName.trim()) return '请输入姓名'
  if (!/^1[3-9]\d{9}$/.test(form.phone.trim())) return '手机号格式不正确'
  if (!/^\S+@\S+\.\S+$/.test(form.email.trim())) return '邮箱格式不正确'
  if (!form.verificationCode.trim()) return '请输入验证码'
  if (!form.address.trim()) return '请输入居住地址'
  if (form.password.length < 6) return '密码至少 6 位'
  if (form.password !== form.confirmPassword) return '两次输入密码不一致'
  if (isVolunteer.value && !toSkillText()) return '志愿者请至少填写一个技能'
  return ''
}

async function sendCode() {
  const email = form.email.trim()
  if (!email || sending.value || countdown.value > 0) return
  sending.value = true
  try {
    const res = await apiApp.sendVerificationCode({ email, scene: 'REGISTER' })
    if (res.code !== 200) throw new Error(res.message || '发送失败')
    if (res.data?.devCode) alert(`验证码（演示）: ${res.data.devCode}`)
    countdown.value = 60
    timer = setInterval(() => {
      countdown.value -= 1
      if (countdown.value <= 0) {
        clearInterval(timer)
        timer = null
      }
    }, 1000)
  }
  catch (e: any) {
    alert(e?.message || '发送失败')
  }
  finally {
    sending.value = false
  }
}

async function onSubmit() {
  const err = validateForm()
  if (err) {
    alert(err)
    return
  }
  loading.value = true
  try {
    const skillText = toSkillText()
    const res = await apiApp.register({
      username: form.username.trim(),
      password: form.password,
      realName: form.realName.trim(),
      phone: form.phone.trim(),
      email: form.email.trim(),
      verificationCode: form.verificationCode.trim(),
      verificationScene: 'REGISTER',
      identityType: identityType.value,
      skillTags: skillText ? skillText.split(',') : undefined,
    })
    if (res.code !== 200) throw new Error(res.message || '注册失败')
    await appAuthStore.login({ account: form.username.trim(), password: form.password })
    await updateMyProfile({
      address: form.address.trim(),
    })
    await appAuthStore.hydrateUser()
    router.replace('/user')
  }
  catch (e: any) {
    alert(e?.message || '注册失败')
  }
  finally {
    loading.value = false
  }
}
</script>

<template>
  <AppPageLayout :navbar="false" copyright>
    <div class="register-page">
      <div class="head">
        <h2>办理注册</h2>
        <p>先选择身份，再补全必要信息</p>
      </div>

      <div v-if="step === 'pick'" class="pick-card">
        <button class="pick-btn" @click="pickIdentity(1)">
          <b>我是居民</b>
          <span>发布需求、查看办理进度</span>
        </button>
        <button class="pick-btn" @click="pickIdentity(2)">
          <b>我是志愿者</b>
          <span>参与服务、办理互助任务</span>
        </button>
      </div>

      <form v-else class="form-card" @submit.prevent="onSubmit">
        <div class="identity-tip">
          当前身份：{{ isVolunteer ? '志愿者' : '居民' }}
          <button type="button" @click="backToPick">
            重新选择
          </button>
        </div>
        <FmInput v-model="form.username" type="text" placeholder="用户名" />
        <FmInput v-model="form.realName" type="text" placeholder="姓名" />
        <FmInput v-model="form.phone" type="text" placeholder="手机号" />
        <FmInput v-model="form.email" type="text" placeholder="邮箱" />
        <div class="code-row">
          <FmInput v-model="form.verificationCode" type="text" placeholder="邮箱验证码" />
          <FmButton size="sm" variant="outline" type="button" :disabled="countdown > 0" :loading="sending" @click="sendCode">
            {{ countdown > 0 ? `${countdown}s` : '发送验证码' }}
          </FmButton>
        </div>
        <FmInput v-model="form.address" type="text" placeholder="居住地址" />
        <template v-if="isVolunteer">
          <div class="skill-block">
            <div class="skill-title">
              服务技能（可多选）
            </div>
            <label v-for="s in skillTemplates" :key="s" class="skill-item">
              <input v-model="selectedSkills" :value="s" type="checkbox">
              <span>{{ s }}</span>
            </label>
            <label class="skill-item">
              <input v-model="otherSkillEnabled" type="checkbox">
              <span>其他</span>
            </label>
            <FmInput v-if="otherSkillEnabled" v-model="customSkill" type="text" placeholder="请输入其他技能" />
          </div>
        </template>
        <FmInput v-model="form.password" type="password" placeholder="密码（至少6位）" />
        <FmInput v-model="form.confirmPassword" type="password" placeholder="重复密码" />

        <FmButton :loading class="w-full mt-2" type="submit">
          提交注册并进入系统
        </FmButton>
        <FmButton variant="ghost" class="w-full" type="button" @click="router.replace('/login')">
          返回登录
        </FmButton>
      </form>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.register-page { padding: var(--m-space-page); min-height: 100%; display: grid; align-content: center; gap: 12px; background: var(--m-color-bg); }
.head h2 { margin: 0; font-size: 24px; color: var(--m-color-text); font-weight: 800; }
.head p { margin: 4px 0 0; font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.pick-card,
.form-card { background: var(--m-color-card); border: 1px solid var(--m-color-border); border-radius: var(--m-radius-card); padding: 12px; box-shadow: var(--m-shadow-card); display: grid; gap: 10px; }
.pick-btn { border: 1px solid var(--m-color-border); background: var(--m-color-card); border-radius: 10px; padding: 12px; text-align: left; display: grid; gap: 4px; }
.pick-btn b { color: var(--m-color-text); }
.pick-btn span { color: var(--m-color-subtext); font-size: var(--m-font-sub); }
.identity-tip { display: flex; justify-content: space-between; align-items: center; font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.identity-tip button { border: 0; background: transparent; color: var(--m-color-primary); font-weight: 700; }
.code-row { display: grid; grid-template-columns: 1fr auto; gap: 8px; }
.skill-block { display: grid; gap: 6px; border: 1px dashed var(--m-color-border); border-radius: 10px; padding: 8px; }
.skill-title { font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.skill-item { display: inline-flex; align-items: center; gap: 6px; font-size: var(--m-font-sub); color: var(--m-color-text); }
</style>

