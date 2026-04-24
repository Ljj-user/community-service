<script setup lang="ts">
import { claimServiceRequest, getPublishedRequests, type ServiceRequestVO } from '@/api/modules/serviceRequests'

definePage({
  meta: {
    title: '接取任务',
    auth: true,
  },
})

const router = useRouter()
const loading = ref(false)
const error = ref('')
const rows = ref<ServiceRequestVO[]>([])
const categories = ['全部需求', '助老', '代买跑腿', '清洁', '陪诊', '维修']
const activeCategory = ref('全部需求')
const takingId = ref<number | null>(null)
const vulnerableKeywords = ['老人', '独居', '失能', '残障', '残疾', '低保', '高龄', '困难', '特殊人群']

function urgencyText(v: number) {
  if (v >= 4) return '极紧急'
  if (v === 3) return '紧急'
  if (v === 2) return '中等'
  return '普通'
}

function urgencyClass(v: number) {
  if (v >= 4) return 'urgent-high'
  if (v >= 2) return 'urgent-mid'
  return 'urgent-low'
}

/** 与首页需求卡片一致 */
function tagClass(type: string) {
  if (!type) return 'tag-green'
  if (type.includes('学习') || type.includes('教育')) return 'tag-indigo'
  if (type.includes('陪')) return 'tag-red'
  if (type.includes('买') || type.includes('跑腿')) return 'tag-orange'
  if (type.includes('维修')) return 'tag-blue'
  if (type.includes('助老')) return 'tag-purple'
  return 'tag-green'
}

function normalizedServiceType(type?: string) {
  const t = String(type || '').trim()
  if (!t) return '互助服务'
  if (t.includes('教育') || t.includes('辅导') || t.includes('作业'))
    return '学习陪伴'
  return t
}

function isVulnerableRequest(item: ServiceRequestVO) {
  const tags = (item.specialTags || []).join(' ')
  const text = `${item.requesterName || ''} ${item.description || ''} ${tags}`
  return vulnerableKeywords.some(k => text.includes(k))
}

async function loadData() {
  loading.value = true
  error.value = ''
  try {
    const res = await getPublishedRequests(1, 30, activeCategory.value)
    if (res.code !== 200) throw new Error(res.message || '加载失败')
    rows.value = res.data.records || []
  }
  catch (e: any) {
    error.value = e?.message || '加载失败'
  }
  finally {
    loading.value = false
  }
}

function switchCategory(c: string) {
  activeCategory.value = c
  loadData()
}

async function takeOne(item: ServiceRequestVO) {
  if (!item?.id || takingId.value) return
  takingId.value = item.id
  try {
    const res = await claimServiceRequest({ requestId: item.id })
    if (res.code !== 200) {
      window.alert(res.message || '接取失败')
      return
    }
    window.alert('接取成功，已进入“我参与的办理”')
    await loadData()
  }
  catch (e: any) {
    window.alert(e?.message || '接取失败')
  }
  finally {
    takingId.value = null
  }
}

onMounted(loadData)
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page">
      <header class="m-topbar">
        <button class="m-back" @click="router.back()">
          返回
        </button>
        <h2 class="m-top-title">接取任务</h2>
      </header>

      <p class="take-lead">
        浏览本社区已发布需求，认领后请按时完成服务
      </p>

      <div class="tabs">
        <button
          v-for="c in categories"
          :key="c"
          type="button"
          class="tab"
          :class="{ active: activeCategory === c }"
          @click="switchCategory(c)"
        >
          {{ c }}
        </button>
      </div>

      <div v-if="loading" class="status">
        加载中...
      </div>
      <div v-else-if="error" class="status err">
        {{ error }}
      </div>
      <div v-else class="list">
        <article v-for="r in rows" :key="r.id" class="take-card">
          <div class="urgency-corner" :class="urgencyClass(r.urgencyLevel)">
            {{ urgencyText(r.urgencyLevel) }}
          </div>
          <div class="row-1">
            <div class="left">
              <span class="biz-tag" :class="tagClass(normalizedServiceType(r.serviceType))">{{ normalizedServiceType(r.serviceType) }}</span>
              <div class="title-wrap">
                <span class="title">{{ r.requesterName || `${normalizedServiceType(r.serviceType)}需求` }}</span>
                <span v-if="isVulnerableRequest(r)" class="vul-badge">特殊人群</span>
              </div>
            </div>
            <!-- 时间币概念暂时隐藏：不在接单列表中展示奖励 -->
          </div>
          <div class="row-2">
            {{ r.description || '需要邻里协助，欢迎认领' }}
          </div>
          <div class="row-3">
            <div class="meta">
              <span><FmIcon name="i-carbon:location" />{{ r.communityName || '本社区' }} · {{ r.serviceAddress }}</span>
            </div>
            <NutButton type="primary" size="small" class="take-btn" :loading="takingId === r.id" @click="takeOne(r)">
              {{ takingId === r.id ? '接取中...' : '立即接取' }}
            </NutButton>
          </div>
        </article>
      </div>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.page { min-height: 100%; background: var(--m-color-bg); padding: var(--m-space-page); box-sizing: border-box; }

.take-lead {
  margin: 0 0 10px;
  font-size: 12px;
  line-height: 1.45;
  color: var(--m-color-subtext);
}

.tabs { display: flex; gap: 8px; overflow-x: auto; white-space: nowrap; margin-bottom: 12px; padding-bottom: 2px; }
.tab {
  flex-shrink: 0;
  border: 0;
  background: var(--m-color-card);
  padding: 8px 10px;
  border-radius: 10px;
  color: var(--m-color-subtext);
  border-bottom: 2px solid transparent;
}
.tab.active { color: #059669; border-bottom-color: #059669; font-weight: 800; }

.status { color: var(--m-color-subtext); font-size: 13px; }
.status.err { color: #dc2626; }

.list { display: grid; gap: 10px; }

.take-card {
  position: relative;
  background: linear-gradient(160deg, #ffffff 6%, #f0fdf4 95%);
  border: 1px solid #d1fae5;
  border-radius: 16px;
  padding: 14px;
  box-shadow: 0 2px 10px rgba(15, 23, 42, 0.05);
  overflow: hidden;
}
.take-card::after {
  content: '';
  position: absolute;
  right: -26px;
  top: -28px;
  width: 84px;
  height: 84px;
  border-radius: 999px;
  background: rgba(16, 185, 129, 0.1);
  pointer-events: none;
}

.urgency-corner {
  position: absolute;
  top: 0;
  right: 0;
  z-index: 1;
  padding: 5px 10px;
  font-size: 11px;
  font-weight: 800;
  color: #fff;
  border-bottom-left-radius: 12px;
  border-top-right-radius: 16px;
}
.urgent-high { background: linear-gradient(135deg, #dc2626, #f97316); }
.urgent-mid { background: linear-gradient(135deg, #d97706, #f59e0b); }
.urgent-low { background: linear-gradient(135deg, #059669, #10b981); }

.row-1 {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
  padding-right: 72px;
}
.row-1 .left { display: flex; align-items: center; gap: 8px; min-width: 0; }
.title-wrap { display: inline-flex; align-items: center; gap: 6px; min-width: 0; }
.biz-tag {
  font-size: 10px;
  padding: 3px 8px;
  border-radius: 999px;
  font-weight: 800;
  white-space: nowrap;
}
.tag-red { background: #fef2f2; color: #dc2626; }
.tag-orange { background: #fff7ed; color: #ea580c; }
.tag-blue { background: #eff6ff; color: #2563eb; }
.tag-purple { background: #faf5ff; color: #9333ea; }
.tag-indigo { background: #eef2ff; color: #4338ca; }
.tag-green { background: #ecfdf5; color: #059669; }
.title {
  font-weight: 800;
  color: var(--m-color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.vul-badge {
  flex-shrink: 0;
  border: 1px solid #fbbf24;
  color: #b45309;
  background: #fffbeb;
  border-radius: 999px;
  padding: 2px 7px;
  font-size: 10px;
  font-weight: 800;
}
.reward { font-weight: 900; color: #047857; white-space: nowrap; font-size: 13px; }

.row-2 {
  position: relative;
  z-index: 1;
  margin-top: 6px;
  color: var(--m-color-subtext);
  font-size: 12px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.row-3 {
  position: relative;
  z-index: 1;
  margin-top: 10px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}
.meta {
  color: var(--m-color-muted);
  font-size: 11px;
  min-width: 0;
  line-height: 1.35;
}
.meta span {
  display: inline-flex;
  align-items: flex-start;
  gap: 4px;
}
.meta :deep(svg) { flex-shrink: 0; font-size: 14px; margin-top: 1px; opacity: 0.85; }

.take-btn { border-radius: 10px !important; font-weight: 800 !important; }

:global(.dark) .page { background: #111827; }
:global(.dark) .back { background: #1f2937; color: #f3f4f6; border: 1px solid #374151; }
:global(.dark) .top h2 { color: #f3f4f6; }
:global(.dark) .take-lead { color: #9ca3af; }
:global(.dark) .tab { background: #1f2937; color: #d1d5db; }
:global(.dark) .tab.active { color: #34d399; border-bottom-color: #34d399; }
:global(.dark) .take-card {
  background: linear-gradient(160deg, #0f172a 6%, #052e26 95%);
  border-color: #14532d;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
}
:global(.dark) .title { color: #f3f4f6; }
:global(.dark) .row-2 { color: #9ca3af; }
:global(.dark) .reward { color: #6ee7b7; }
:global(.dark) .tag-red { background: rgba(220, 38, 38, 0.15); color: #fca5a5; }
:global(.dark) .tag-orange { background: rgba(234, 88, 12, 0.15); color: #fdba74; }
:global(.dark) .tag-blue { background: rgba(37, 99, 235, 0.15); color: #93c5fd; }
:global(.dark) .tag-purple { background: rgba(147, 51, 234, 0.15); color: #d8b4fe; }
:global(.dark) .tag-indigo { background: rgba(67, 56, 202, 0.2); color: #a5b4fc; }
:global(.dark) .tag-green { background: rgba(5, 150, 105, 0.2); color: #6ee7b7; }
::global(.dark) .vul-badge {
  background: rgba(217, 119, 6, 0.18);
  border-color: rgba(251, 191, 36, 0.4);
  color: #fcd34d;
}
</style>
