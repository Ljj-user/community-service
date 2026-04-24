<script setup lang="ts">
import { toast } from 'vue-sonner'
import { getMyProfile, updateMyProfile, uploadMyAvatar } from '@/api/modules/profile'

definePage({
  name: 'profile-edit',
  meta: {
    title: '完善资料',
    auth: true,
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()

const loading = ref(false)
const saving = ref(false)
const uploading = ref(false)

const localAvatarPreview = ref<string>('')

const form = reactive({
  username: '',
  realName: '',
  phone: '',
  email: '',
  gender: 0 as 0 | 1 | 2,
  identityTag: '',
  address: '',
})
const selectedSkills = ref<string[]>([])
const customSkill = ref('')

const genderOptions = [
  { label: '未知', value: 0 },
  { label: '男', value: 1 },
  { label: '女', value: 2 },
]

const currentAvatarUrl = computed(() => localAvatarPreview.value || appAuthStore.user?.avatarUrl || '')
const communityText = computed(() => appAuthStore.user?.communityName || '未绑定社区')

const identityTagOptions = [
  { label: '普通居民', value: '普通居民' },
  { label: '活力老人', value: '活力老人' },
  { label: '孤寡老人', value: '孤寡老人' },
  { label: '残疾人', value: '残疾人' },
]

const skillTemplates = ['陪诊', '助老照护', '跑腿代办', '家电维修', '心理陪伴']

function parseSkillTags(raw?: string) {
  if (!raw) return [] as string[]
  const s = raw.trim()
  if (!s) return [] as string[]
  try {
    const arr = JSON.parse(s)
    if (Array.isArray(arr)) return arr.map(x => String(x).trim()).filter(Boolean)
  }
  catch {}
  return s.split(',').map(x => x.trim()).filter(Boolean)
}

function skillTagsToPayload() {
  const fixed = selectedSkills.value.filter(x => skillTemplates.includes(x))
  const extra = customSkill.value.trim()
  const merged = Array.from(new Set(extra ? [...fixed, extra] : fixed))
  return JSON.stringify(merged)
}

async function load() {
  loading.value = true
  try {
    const res = await getMyProfile()
    form.username = res.data.username || ''
    form.realName = res.data.realName || ''
    form.phone = res.data.phone || ''
    form.email = res.data.email || ''
    form.gender = (res.data.gender ?? 0) as any
    form.identityTag = res.data.identityTag || ''
    form.address = res.data.address || ''
    const tags = parseSkillTags(res.data.skillTags)
    selectedSkills.value = tags.filter(x => skillTemplates.includes(x))
    customSkill.value = tags.find(x => !skillTemplates.includes(x)) || ''
    // 同步一次 store
    await appAuthStore.hydrateUser()
  } catch (e: any) {
    toast.error(e?.message || '加载失败')
  } finally {
    loading.value = false
  }
}

function onPickAvatar(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  if (!file.type.startsWith('image/')) {
    toast.error('请选择图片文件')
    return
  }
  if (localAvatarPreview.value)
    URL.revokeObjectURL(localAvatarPreview.value)
  localAvatarPreview.value = URL.createObjectURL(file)
  void uploadAvatar(file)
}

async function uploadAvatar(file: File) {
  uploading.value = true
  try {
    await uploadMyAvatar(file)
    toast.success('头像已更新')
    // 后端已写入 avatar_url，再 hydrate 一次让全局头像/昵称同步
    await appAuthStore.hydrateUser()
    // 清掉本地预览，用后端 URL 为准
    if (localAvatarPreview.value) {
      URL.revokeObjectURL(localAvatarPreview.value)
      localAvatarPreview.value = ''
    }
  } catch (e: any) {
    toast.error(e?.message || '头像上传失败')
  } finally {
    uploading.value = false
  }
}

async function save() {
  if (saving.value) return
  saving.value = true
  try {
    await updateMyProfile({
      realName: form.realName || undefined,
      phone: form.phone || undefined,
      email: form.email || undefined,
      gender: form.gender,
      identityTag: form.identityTag || undefined,
      address: form.address || undefined,
      skillTags: skillTagsToPayload(),
    })
    toast.success('资料已保存')
    await appAuthStore.hydrateUser()
    router.back()
  } catch (e: any) {
    toast.error(e?.message || '保存失败')
  } finally {
    saving.value = false
  }
}

onMounted(load)

onBeforeUnmount(() => {
  if (localAvatarPreview.value)
    URL.revokeObjectURL(localAvatarPreview.value)
})
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page">
      <header class="top">
        <button type="button" class="back" @click="router.back()">
          <FmIcon name="i-carbon:arrow-left" />
        </button>
        <h2>完善资料</h2>
        <div class="right" />
      </header>

      <div v-if="loading" class="status">
        加载中…
      </div>

      <template v-else>
        <section class="card">
          <div class="avatar-row">
            <div class="avatar">
              <img v-if="currentAvatarUrl" :src="currentAvatarUrl" alt="avatar">
              <div v-else class="avatar-fallback">
                <FmIcon name="i-carbon:user-avatar-filled-alt" />
              </div>
            </div>
            <div class="avatar-meta">
              <div class="name">
                {{ form.realName || form.username || '用户' }}
              </div>
              <div class="sub">
                {{ communityText }}
              </div>
              <label class="upload-btn" :class="{ disabled: uploading }">
                <input class="hidden" type="file" accept="image/*" :disabled="uploading" @change="onPickAvatar">
                {{ uploading ? '上传中…' : '更换头像' }}
              </label>
            </div>
          </div>
        </section>

        <section class="card">
          <h3 class="section-title">
            基础信息
          </h3>
          <div class="row">
            <div class="label">账号</div>
            <div class="value">{{ form.username }}</div>
          </div>
          <div class="row">
            <div class="label">姓名</div>
            <FmInput v-model="form.realName" class="input" placeholder="请输入真实姓名" />
          </div>
          <div class="row">
            <div class="label">手机号</div>
            <FmInput v-model="form.phone" class="input" placeholder="11位手机号" />
          </div>
          <div class="row">
            <div class="label">邮箱</div>
            <FmInput v-model="form.email" class="input" placeholder="用于通知/验证" />
          </div>
          <div class="row">
            <div class="label">性别</div>
            <NutRadioGroup v-model="form.gender" direction="horizontal">
              <NutRadio v-for="g in genderOptions" :key="g.value" :label="g.value">
                {{ g.label }}
              </NutRadio>
            </NutRadioGroup>
          </div>
          <div class="row">
            <div class="label">地址</div>
            <FmInput v-model="form.address" class="input" placeholder="常住地址（可选）" />
          </div>
          <div class="row">
            <div class="label">居民标签</div>
            <NutRadioGroup v-model="form.identityTag" direction="horizontal">
              <NutRadio v-for="x in identityTagOptions" :key="x.value" :label="x.value">
                {{ x.label }}
              </NutRadio>
            </NutRadioGroup>
          </div>
        </section>

        <section class="card">
          <h3 class="section-title">
            志愿者技能（可选）
          </h3>
          <div class="row skills-row">
            <div class="label">服务技能</div>
            <div class="skills-box">
              <label v-for="s in skillTemplates" :key="s" class="skill-item">
                <input v-model="selectedSkills" :value="s" type="checkbox">
                <span>{{ s }}</span>
              </label>
              <FmInput v-model="customSkill" class="input" placeholder="其他技能（可选）" />
            </div>
          </div>
        </section>

        <div class="actions">
          <NutButton block type="primary" :loading="saving" @click="save">
            保存
          </NutButton>
        </div>
      </template>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.page { min-height: 100%; background: #f4f6f8; padding: 12px 12px 22px; box-sizing: border-box; display: grid; gap: 12px; align-content: start; }
.top { display: grid; grid-template-columns: 40px 1fr 40px; align-items: center; gap: 6px; }
.top h2 { margin: 0; text-align: center; font-size: 18px; font-weight: 900; color: #111827; }
.back { width: 38px; height: 38px; border: 0; border-radius: 12px; background: #fff; box-shadow: 0 1px 6px rgba(15, 23, 42, 0.06); display: inline-flex; align-items: center; justify-content: center; }
.status { font-size: 13px; color: #6b7280; text-align: center; margin-top: 30px; }

.card { background: #fff; border-radius: 16px; padding: 14px; box-shadow: 0 1px 10px rgba(15, 23, 42, 0.06); }
.section-title { margin: 0 0 8px; font-size: 14px; font-weight: 900; color: #0f172a; }
.avatar-row { display: flex; gap: 12px; align-items: center; }
.avatar { width: 72px; height: 72px; border-radius: 999px; overflow: hidden; background: #f1f5f9; display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; }
.avatar img { width: 100%; height: 100%; object-fit: cover; display: block; }
.avatar-fallback { color: #94a3b8; font-size: 34px; }
.avatar-meta { flex: 1; display: grid; gap: 4px; }
.name { font-weight: 900; color: #111827; }
.sub { font-size: 12px; color: #64748b; }
.upload-btn { display: inline-flex; align-items: center; justify-content: center; width: fit-content; padding: 8px 10px; border-radius: 12px; background: #eff6ff; color: #2563eb; font-weight: 800; font-size: 12px; border: 1px solid #bfdbfe; }
.upload-btn.disabled { opacity: .6; pointer-events: none; }
.hidden { display: none; }

.row { display: grid; grid-template-columns: 70px 1fr; align-items: center; gap: 10px; padding: 10px 0; border-bottom: 1px dashed #e5e7eb; }
.row:last-child { border-bottom: 0; }
.label { font-size: 12px; color: #64748b; font-weight: 800; }
.value { font-size: 13px; color: #111827; font-weight: 800; }
.input { width: 100%; }
.skills-row { align-items: start; }
.skills-box { display: grid; gap: 8px; }
.skill-item { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; color: #334155; }
.actions { padding: 0 2px; }
</style>

