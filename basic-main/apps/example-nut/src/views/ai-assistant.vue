<script setup lang="ts">
import { aiChat, type AiChatHistoryMessage } from '@/api/modules/ai'
import { toast } from 'vue-sonner'
import AiHeroInput from '@/components/AiHeroInput.vue'

definePage({
  meta: { title: 'AI助手', auth: true },
})

const route = useRoute()
const router = useRouter()
const loading = ref(false)
const inputText = ref('')
const quickPrompts = ['我该怎么发布需求？', '怎么接取任务？', '怎么查看服务统计？', '帮我写一段求助说明'] as const
const chatRows = ref<Array<{ role: 'user' | 'ai'; text: string; time: string }>>([
  { role: 'ai', text: '您好，我是邻里互助 AI 助手。可以直接描述您的问题。', time: '刚刚' },
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
    chatRows.value.push({ role: 'ai', text: res.data?.reply || '已收到。', time: nowTime() })
  }
  catch (e: any) {
    toast.error(e?.message || 'AI 服务暂不可用')
    chatRows.value.push({ role: 'ai', text: '网络有点忙，请稍后再试。', time: nowTime() })
  }
  finally {
    loading.value = false
  }
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
          <small>{{ row.time }}</small>
        </article>

        <div class="prompts">
          <button v-for="prompt in quickPrompts" :key="prompt" @click="usePrompt(prompt)">
            {{ prompt }}
          </button>
        </div>

        <article v-if="loading" class="bubble-wrap ai">
          <div class="bubble ai">正在思考中...</div>
        </article>
      </div>

      <AiHeroInput
        v-model="inputText"
        class="input-bar"
        :show-voice="false"
        placeholder="输入问题后按回车即可发送"
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
</style>
