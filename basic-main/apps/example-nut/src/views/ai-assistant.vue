<script setup lang="ts">
import { aiChat, type AiChatHistoryMessage } from '@/api/modules/ai'
import { markAiRecordApplied } from '@/api/modules/ai'
import { toast } from 'vue-sonner'
import AiHeroInput from '@/components/AiHeroInput.vue'
import { saveAiDemandDraft } from '@/utils/aiDraft'

definePage({
  meta: { title: 'AI助手', auth: true },
})

const route = useRoute()
const router = useRouter()
const loading = ref(false)
const inputText = ref('')
const quickPrompts = ['帮我整理陪诊需求', '我想找人上门打扫', '教我怎么发布求助', '帮我写一段简短说明'] as const
const chatRows = ref<Array<{ role: 'user' | 'ai'; text: string; time: string; draft?: any; analysisRecordId?: number; sourceText?: string }>>([
  { role: 'ai', text: '直接说需求就行，比如“明天上午想找人陪老人去医院”。我会帮你整理成可提交的表单内容。', time: '刚刚' },
])

function nowTime() {
  return new Date().toTimeString().slice(0, 5)
}

async function sendMessage() {
  const text = inputText.value.trim()
  if (!text || loading.value) return
  const history: AiChatHistoryMessage[] = chatRows.value.slice(-8).map(row => ({
    role: row.role === 'ai' ? 'assistant' : 'user',
    text: row.text,
  }))
  chatRows.value.push({ role: 'user', text, time: nowTime() })
  inputText.value = ''
  loading.value = true
  try {
    const res = await aiChat(text, history)
    chatRows.value.push({
      role: 'ai',
      text: res.data?.reply || '已收到。',
      time: nowTime(),
      draft: res.data?.orderDraft,
      analysisRecordId: res.data?.analysisRecordId,
      sourceText: text,
    })
  }
  catch (e: any) {
    toast.error(e?.message || 'AI 服务暂不可用')
    chatRows.value.push({ role: 'ai', text: '网络有点忙，请稍后再试。', time: nowTime() })
  }
  finally {
    loading.value = false
  }
}

async function applyDraft(row: { draft?: any; analysisRecordId?: number; text: string; sourceText?: string }) {
  if (!row.draft) return
  saveAiDemandDraft({
    analysisRecordId: row.analysisRecordId,
    inputText: row.sourceText,
    reply: row.text,
    draft: row.draft,
  })
  if (row.analysisRecordId) {
    try {
      await markAiRecordApplied(row.analysisRecordId)
    } catch {}
  }
  router.push('/hall-publish')
}

function usePrompt(prompt: string) {
  inputText.value = prompt
  void sendMessage()
}

async function sendPrefilledQueryFromRoute() {
  const q = String(route.query.q || '').trim()
  if (!q) return
  inputText.value = q
  await sendMessage()
}

onMounted(() => {
  void sendPrefilledQueryFromRoute()
})
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page m-mobile-page-bg">
      <header class="head">
        <button class="back" @click="router.back()">
          <FmIcon name="i-carbon:chevron-left" />
        </button>
        <h2>邻里互助助手</h2>
        <img src="https://picsum.photos/seed/kindred-assistant/120/120" alt="AI头像" class="avatar">
      </header>

      <div class="chat">
        <article v-for="(row, idx) in chatRows" :key="idx" class="bubble-wrap" :class="row.role">
          <div class="bubble" :class="row.role">{{ row.text }}</div>
          <div v-if="row.role === 'ai' && row.draft" class="draft-card">
            <div class="draft-head">
              <strong>{{ row.draft.serviceType || '需求草稿' }}</strong>
              <span>建议填写</span>
            </div>
            <div class="draft-grid">
              <div>紧急程度：{{ row.draft.urgencyLevel || '2' }}</div>
              <div>期望时间：{{ row.draft.expectedTime || '待补充' }}</div>
              <div class="full">标签：{{ row.draft.tags?.join('、') || '社区互助' }}</div>
              <div class="full draft-desc">{{ row.draft.description || '暂无描述' }}</div>
            </div>
            <button type="button" class="draft-action" @click="applyDraft(row)">带入表单继续补充</button>
          </div>
          <small>{{ row.time }}</small>
        </article>

        <div class="prompts">
          <button v-for="prompt in quickPrompts" :key="prompt" @click="usePrompt(prompt)">
            {{ prompt }}
          </button>
        </div>

        <article v-if="loading" class="bubble-wrap ai">
          <div class="bubble ai">正在整理中...</div>
        </article>
      </div>

      <AiHeroInput
        v-model="inputText"
        class="input-bar"
        :show-voice="false"
        placeholder="输入一句需求，按回车就能生成草稿"
        @send="sendMessage"
      />
    </div>
  </AppPageLayout>
</template>

<style scoped>
.page { min-height: 100%; height: 100%; display: grid; grid-template-rows: auto 1fr auto; padding: 10px 12px; gap: 10px; }
.head { display: grid; grid-template-columns: auto 1fr auto; align-items: center; gap: 10px; }
.back { width: 34px; height: 34px; border: 1px solid var(--m-color-border); border-radius: 10px; background: var(--m-color-card); display: inline-flex; align-items: center; justify-content: center; }
.head h2 { margin: 0; font-size: 17px; color: var(--m-color-text); font-weight: 900; text-align: center; }
.avatar { width: 34px; height: 34px; border-radius: 50%; object-fit: cover; border: 1px solid #d1d5db; }
.chat { overflow: auto; display: flex; flex-direction: column; gap: 10px; padding-bottom: 8px; }
.bubble-wrap { max-width: 86%; display: grid; gap: 4px; }
.bubble-wrap.user { align-self: flex-end; justify-items: end; }
.bubble { border-radius: 14px; padding: 10px 12px; font-size: 14px; line-height: 1.6; white-space: pre-wrap; }
.bubble.ai { background: #fff; border: 1px solid #e5e7eb; color: #111827; }
.bubble.user { background: #16a34a; color: #fff; }
.bubble-wrap small { color: #9ca3af; font-size: 11px; }
.prompts { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.prompts button { border: 0; border-radius: 999px; background: #ecfdf5; color: #047857; font-size: 12px; font-weight: 800; padding: 8px 10px; }
.input-bar { margin-top: 2px; }
.draft-card {
  margin-top: 8px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.92);
  border: 1px solid rgba(15, 23, 42, 0.08);
  padding: 12px;
  display: grid;
  gap: 10px;
}
.draft-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}
.draft-head strong {
  color: #0f172a;
  font-size: 14px;
}
.draft-head span {
  font-size: 11px;
  font-weight: 800;
  color: #166534;
  background: #ecfdf5;
  padding: 4px 8px;
  border-radius: 999px;
}
.draft-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px 10px;
  font-size: 12px;
  color: #475569;
}
.draft-grid .full {
  grid-column: 1 / -1;
}
.draft-desc {
  white-space: pre-wrap;
  line-height: 1.7;
}
.draft-action {
  height: 38px;
  border: 0;
  border-radius: 12px;
  background: linear-gradient(135deg, #15803d 0%, #16a34a 100%);
  color: #fff;
  font-size: 13px;
  font-weight: 900;
}
</style>
