<script setup lang="ts">
import { aiChat, type AiChatResponse } from '@/api/modules/ai'
import { createServiceRequest } from '@/api/modules/serviceRequests'

definePage({
  meta: {
    title: 'AI助手',
    auth: true,
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()
const loading = ref(false)
const publishing = ref(false)
const inputText = ref('')
const chatRows = ref<Array<{ role: 'user' | 'ai'; text: string }>>([
  { role: 'ai', text: '你好，我可以帮你生成需求单，也可以回答“怎么发布需求/积分怎么算/服务规则”等问题。' },
])
const latestDraft = ref<AiChatResponse['orderDraft']>()
const draftForm = reactive({
  serviceType: '助老服务（陪护 / 陪诊）',
  urgencyLevel: 2,
  expectedTime: '',
  tags: [] as string[],
  description: '',
  serviceAddress: '',
  emergencyContactName: '',
  emergencyContactPhone: '',
  emergencyContactRelation: '',
})
const listening = ref(false)

let recognition: any = null

const SERVICE_TYPES = [
  '助老服务（陪护 / 陪诊）',
  '代办服务（买菜 / 取药）',
  '家政清洁',
  '心理陪伴 / 聊天',
  '应急帮助（紧急求助）',
  '社区活动支持',
] as const

function goBack() {
  router.back()
}

async function sendMessage() {
  const text = inputText.value.trim()
  if (!text || loading.value) return
  chatRows.value.push({ role: 'user', text })
  inputText.value = ''
  loading.value = true
  try {
    const res = await aiChat(text)
    const data = res.data
    chatRows.value.push({ role: 'ai', text: data?.reply || '已收到。' })
    latestDraft.value = data?.orderDraft
    if (data?.orderDraft) {
      // 同步到可编辑草稿表单（确保能一键发布且通过后端校验）
      draftForm.serviceType = (data.orderDraft.serviceType && SERVICE_TYPES.includes(data.orderDraft.serviceType as any))
        ? data.orderDraft.serviceType
        : SERVICE_TYPES[0]
      draftForm.urgencyLevel = Number(data.orderDraft.urgencyLevel || 2)
      draftForm.expectedTime = String(data.orderDraft.expectedTime || '')
      draftForm.tags = Array.isArray(data.orderDraft.tags) ? data.orderDraft.tags : []
      draftForm.description = String(data.orderDraft.description || '')
      // 地址 / 联系人自动带入账号信息（用户仍可改）
      const u = appAuthStore.user
      draftForm.serviceAddress = (u?.communityName || u?.address || '').trim()
      draftForm.emergencyContactName = (u?.realName || u?.username || '').trim()
      draftForm.emergencyContactPhone = ''
      draftForm.emergencyContactRelation = ''
    }
  }
  finally {
    loading.value = false
  }
}

async function createOrderByDraft() {
  if (!latestDraft.value || publishing.value) return
  if (!draftForm.serviceAddress.trim()) {
    window.alert('请填写服务地址')
    return
  }
  if (!draftForm.emergencyContactName.trim()) {
    window.alert('请填写联系人姓名')
    return
  }
  if (!draftForm.emergencyContactPhone.trim()) {
    window.alert('请填写联系人电话')
    return
  }
  publishing.value = true
  try {
    await createServiceRequest({
      serviceType: draftForm.serviceType,
      serviceAddress: draftForm.serviceAddress.trim(),
      description: draftForm.description.trim() || undefined,
      expectedTime: draftForm.expectedTime || '',
      urgencyLevel: Number(draftForm.urgencyLevel || 2),
      specialTags: draftForm.tags || [],
      emergencyContactName: draftForm.emergencyContactName.trim(),
      emergencyContactPhone: draftForm.emergencyContactPhone.trim(),
      emergencyContactRelation: draftForm.emergencyContactRelation.trim() || undefined,
    })
    window.alert('订单已生成，可在任务中心查看')
    latestDraft.value = undefined
    router.push('/hall')
  }
  finally {
    publishing.value = false
  }
}
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="ai-page">
      <header class="topbar">
        <button class="back-btn" type="button" @click="goBack">← 返回</button>
        <h1>AI助手</h1>
      </header>

      <div class="chat-box">
        <div v-for="(row, idx) in chatRows" :key="idx" class="msg" :class="row.role">
          {{ row.text }}
        </div>
        <div v-if="loading" class="msg ai">正在思考中...</div>

        <section v-if="latestDraft" class="draft-inline">
          <h3>需求草稿（可编辑）</h3>

          <div class="field">
            <div class="field-label">服务类型</div>
            <select v-model="draftForm.serviceType" class="select">
              <option v-for="t in SERVICE_TYPES" :key="t" :value="t">
                {{ t }}
              </option>
            </select>
          </div>

          <div class="field">
            <div class="field-label">紧急程度</div>
            <div class="level">
              <button type="button" :class="{ active: draftForm.urgencyLevel === 1 }" @click="draftForm.urgencyLevel = 1">
                普通
              </button>
              <button type="button" :class="{ active: draftForm.urgencyLevel === 2 }" @click="draftForm.urgencyLevel = 2">
                中等
              </button>
              <button type="button" :class="{ active: draftForm.urgencyLevel >= 3 }" @click="draftForm.urgencyLevel = 4">
                紧急
              </button>
            </div>
          </div>

          <div class="field">
            <div class="field-label">服务地址</div>
            <input v-model="draftForm.serviceAddress" class="input" placeholder="如：幸福小区1栋101">
          </div>

          <div class="field">
            <div class="field-label">联系人姓名</div>
            <input v-model="draftForm.emergencyContactName" class="input" placeholder="必填">
          </div>
          <div class="field">
            <div class="field-label">联系人电话</div>
            <input v-model="draftForm.emergencyContactPhone" class="input" placeholder="必填">
          </div>
          <div class="field">
            <div class="field-label">关系（选填）</div>
            <input v-model="draftForm.emergencyContactRelation" class="input" placeholder="如：子女/邻居">
          </div>

          <div class="field">
            <div class="field-label">标签</div>
            <input v-model="draftForm.tags" class="input" placeholder="（可选）后台会按 tags 存 specialTags" style="display:none">
            <div class="tags">
              <span v-for="(t, i) in draftForm.tags" :key="`${t}-${i}`" class="tag">
                {{ t }}
              </span>
              <span v-if="draftForm.tags.length === 0" class="tag muted">无</span>
            </div>
          </div>

          <div class="field">
            <div class="field-label">描述</div>
            <textarea v-model="draftForm.description" class="textarea" rows="5" placeholder="可修改 AI 生成内容" />
          </div>

          <button type="button" class="create-btn" :disabled="publishing" @click="createOrderByDraft">
            {{ publishing ? '创建中...' : '一键生成订单' }}
          </button>
        </section>
      </div>

      <footer class="input-bar">
        <button type="button" class="voice-btn" :class="{ active: listening }" @click="toggleVoiceInput">
          {{ listening ? '停止' : '语音' }}
        </button>
        <input v-model="inputText" type="text" placeholder="输入需求或问题..." @keyup.enter="sendMessage">
        <button type="button" class="send-btn" :disabled="loading" @click="sendMessage">发送</button>
      </footer>
    </div>
  </AppPageLayout>
</template>

<style scoped>

function toggleVoiceInput() {
  const win = window as any
  const SpeechRecognition = win.SpeechRecognition || win.webkitSpeechRecognition
  if (!SpeechRecognition) {
    window.alert('当前浏览器不支持语音输入，请改用文字输入')
    return
  }
  if (!recognition) {
    recognition = new SpeechRecognition()
    recognition.lang = 'zh-CN'
    recognition.interimResults = false
    recognition.maxAlternatives = 1
    recognition.onresult = (event: any) => {
      const transcript = event?.results?.[0]?.[0]?.transcript || ''
      inputText.value = String(transcript).trim()
    }
    recognition.onend = () => {
      listening.value = false
    }
    recognition.onerror = () => {
      listening.value = false
    }
  }
  if (listening.value) {
    recognition.stop()
    listening.value = false
    return
  }
  listening.value = true
  recognition.start()
}
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="ai-page">
      <header class="topbar">
        <button class="back-btn" type="button" @click="goBack">← 返回</button>
        <h1>AI助手</h1>
      </header>

      <div class="chat-box">
        <div v-for="(row, idx) in chatRows" :key="idx" class="msg" :class="row.role">
          {{ row.text }}
        </div>
        <div v-if="loading" class="msg ai">正在思考中...</div>
        <section v-if="latestDraft" class="draft-inline">
          <h3>需求草稿</h3>
          <p><b>服务类型：</b>{{ latestDraft.serviceType }}</p>
          <p><b>时间：</b>{{ latestDraft.expectedTime || '尽快' }}</p>
          <p><b>标签：</b>{{ (latestDraft.tags || []).join('、') || '无' }}</p>
          <p><b>描述：</b>{{ latestDraft.description || '-' }}</p>
          <button type="button" class="create-btn" :disabled="publishing" @click="createOrderByDraft">
            {{ publishing ? '创建中...' : '一键生成订单' }}
          </button>
        </section>
      </div>

      <footer class="input-bar">
        <button type="button" class="voice-btn" :class="{ active: listening }" @click="toggleVoiceInput">
          {{ listening ? '停止' : '语音' }}
        </button>
        <input v-model="inputText" type="text" placeholder="输入需求或问题..." @keyup.enter="sendMessage">
        <button type="button" class="send-btn" :disabled="loading" @click="sendMessage">发送</button>
      </footer>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.ai-page {
  min-height: 100%;
  height: 100%;
  display: grid;
  grid-template-rows: auto 1fr auto;
  background: #f7f7f8;
}
.topbar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-bottom: 1px solid #ececf1;
  background: #f7f7f8;
}
.topbar h1 { margin: 0; font-size: 16px; font-weight: 700; color: #111827; }
.back-btn {
  border: 0;
  background: transparent;
  border-radius: 8px;
  padding: 6px 8px;
  color: #4b5563;
}
.chat-box {
  overflow-y: auto;
  padding: 14px 12px 20px;
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 12px;
}
.msg {
  display: inline-block;
  width: auto;
  max-width: min(88%, 620px);
  padding: 10px 12px;
  border-radius: 14px;
  font-size: 14px;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}
.msg.ai {
  align-self: flex-start;
  background: transparent;
  color: #111827;
}
.msg.user {
  align-self: flex-end;
  background: #ffffff;
  color: #111827;
  border: 1px solid #ececf1;
}
.draft-inline {
  justify-self: start;
  width: min(100%, 620px);
  background: #ffffff;
  border: 1px solid #ececf1;
  border-radius: 14px;
  padding: 10px 12px;
}
.draft-inline h3 { margin: 0 0 8px; font-size: 14px; }
.field { margin: 0 0 10px; }
.field-label { font-size: 12px; color: #6b7280; margin-bottom: 6px; }
.input, .select, .textarea {
  width: 100%;
  border: 1px solid #d1d5db;
  border-radius: 12px;
  padding: 10px 12px;
  font-size: 14px;
  box-sizing: border-box;
  background: #fff;
}
.textarea { resize: vertical; }
.tags { display: flex; flex-wrap: wrap; gap: 6px; }
.tag { font-size: 12px; padding: 3px 8px; border-radius: 999px; background: #f3f4f6; color: #111827; }
.tag.muted { color: #6b7280; }
.create-btn {
  width: 100%;
  border: 0;
  border-radius: 10px;
  padding: 10px;
  color: #fff;
  background: #10a37f;
  font-weight: 700;
}
.input-bar {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 8px;
  align-items: center;
  padding: 10px 12px calc(10px + env(safe-area-inset-bottom));
  border-top: 1px solid #ececf1;
  background: #f7f7f8;
}
.input-bar input {
  border: 1px solid #d1d5db;
  background: #fff;
  border-radius: 12px;
  padding: 11px 12px;
  font-size: 14px;
  line-height: 1.35;
}
.voice-btn, .send-btn {
  border: none;
  border-radius: 10px;
  padding: 10px 12px;
  color: #fff;
  background: #6b7280;
}
.voice-btn.active { background: #dc2626; }
.send-btn { background: #10a37f; }
</style>
