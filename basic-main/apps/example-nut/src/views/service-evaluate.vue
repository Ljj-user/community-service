<script setup lang="ts">
import { toast } from 'vue-sonner'
import api from '@/api'

definePage({
  meta: {
    title: '服务评价',
    auth: true,
  },
})

const route = useRoute()
const router = useRouter()

const claimId = computed(() => Number(route.query.claimId || 0))
const rating = ref<number>(5)
const content = ref('')
const submitting = ref(false)

const ratingText = computed(() => {
  const v = Number(rating.value || 0)
  if (v >= 5) return '非常满意'
  if (v >= 4) return '满意'
  if (v >= 3) return '一般'
  if (v >= 2) return '不太满意'
  if (v >= 1) return '不满意'
  return '—'
})

async function submit() {
  if (!claimId.value) {
    toast.error('缺少订单信息')
    return
  }
  submitting.value = true
  try {
    const payload = {
      claimId: claimId.value,
      rating: Number(rating.value || 0),
      content: content.value?.trim() || '',
    }
    const res = await api.post<any, { code: number; message: string; data: any }>('/service-evaluation', payload)
    if (res.code !== 200) throw new Error(res.message || '提交失败')
    toast.success('评价已提交')
    router.replace({ path: '/hall-overview', query: { kind: 'reviews' } })
  }
  catch (e: any) {
    toast.error(e?.message || '提交失败')
  }
  finally {
    submitting.value = false
  }
}
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page">
      <header class="m-topbar">
        <button class="m-back" @click="router.back()">
          返回
        </button>
        <h2 class="m-top-title">服务评价</h2>
      </header>

      <div class="card">
        <p class="hint">
          请根据本次服务体验给出评分与建议（双方均可评价，评价将用于信用与激励统计）。
        </p>

        <div class="rating-row">
          <span class="label">评分</span>
          <div class="btns">
            <button
              v-for="v in 5"
              :key="v"
              type="button"
              class="rate-btn"
              :class="{ active: rating === v }"
              @click="rating = v"
            >
              {{ v }}★
            </button>
          </div>
          <div class="rating-text">
            {{ ratingText }}
          </div>
        </div>

        <div class="content-row">
          <span class="label">评价内容（可选）</span>
          <textarea
            v-model="content"
            class="textarea"
            maxlength="200"
            placeholder="说说你的真实感受：准时、沟通、服务质量等"
          />
          <div class="count">
            {{ (content || '').length }}/200
          </div>
        </div>

        <NutButton block type="primary" :loading="submitting" @click="submit">
          提交评价
        </NutButton>
      </div>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.page { min-height: 100%; background: var(--m-color-bg); padding: var(--m-space-page); box-sizing: border-box; }

.card {
  background: var(--m-color-card);
  border: 1px solid var(--m-color-border);
  border-radius: 14px;
  padding: 14px;
  box-shadow: var(--m-shadow-card);
}
.hint { margin: 0 0 12px; color: var(--m-color-subtext); font-size: 12px; line-height: 1.55; }

.label { display: inline-flex; font-size: 12px; font-weight: 800; color: var(--m-color-text); margin-bottom: 6px; }
.rating-row { margin-bottom: 14px; }
.btns { display: flex; gap: 8px; flex-wrap: wrap; }
.rate-btn {
  border: 1px solid var(--m-color-border);
  background: transparent;
  border-radius: 999px;
  padding: 7px 10px;
  font-size: 12px;
  font-weight: 800;
  color: var(--m-color-subtext);
}
.rate-btn.active {
  border-color: #10b981;
  background: #ecfdf5;
  color: #047857;
}
.rating-text { margin-top: 8px; color: #059669; font-weight: 800; font-size: 12px; }

.content-row { margin-bottom: 14px; }
.textarea {
  width: 100%;
  min-height: 110px;
  resize: none;
  border: 1px solid var(--m-color-border);
  border-radius: 12px;
  padding: 10px;
  box-sizing: border-box;
  background: transparent;
  color: var(--m-color-text);
  outline: none;
  font-size: 13px;
  line-height: 1.6;
}
.count { margin-top: 6px; text-align: right; color: var(--m-color-muted); font-size: 11px; }
</style>

