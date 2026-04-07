<script setup lang="ts">
definePage({
  meta: {
    title: '发布需求',
    auth: true,
  },
})

const router = useRouter()
const loading = ref(false)
const form = reactive({
  serviceType: '助老',
  urgencyLevel: 2,
  serviceAddress: '',
  description: '',
})

async function submit() {
  if (!form.serviceAddress.trim()) {
    window.alert('请填写服务地址')
    return
  }
  loading.value = true
  try {
    await new Promise(resolve => setTimeout(resolve, 500))
    window.alert('发布成功（演示）')
    router.back()
  }
  finally {
    loading.value = false
  }
}
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="page">
      <header class="top">
        <button class="back" @click="router.back()">
          返回
        </button>
        <h2>发布需求</h2>
      </header>

      <section class="pub-hero" aria-hidden="true">
        <div class="pub-hero-glow" />
        <div class="pub-hero-inner">
          <span class="pub-badge">互助</span>
          <p class="pub-hero-title">
            向社区发起一条需求
          </p>
          <p class="pub-hero-desc">
            填写后邻居可在「接取任务」中查看并认领
          </p>
        </div>
      </section>

      <div class="pub-form">
        <div class="form-card">
          <div class="label">
            服务类型
          </div>
          <NutRadioGroup v-model="form.serviceType" direction="horizontal">
            <NutRadio label="助老">
              助老
            </NutRadio>
            <NutRadio label="代买跑腿">
              代买跑腿
            </NutRadio>
            <NutRadio label="清洁">
              清洁
            </NutRadio>
          </NutRadioGroup>
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
          <div class="label">
            需求描述
          </div>
          <NutTextarea v-model="form.description" rows="3" placeholder="请描述需要帮助的内容" />
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
  background: #f4f6f8;
  padding: 14px;
  padding-bottom: calc(14px + env(safe-area-inset-bottom, 0px));
  display: flex;
  flex-direction: column;
  gap: 12px;
  box-sizing: border-box;
}
.top { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.back { border: 0; border-radius: 8px; background: #fff; padding: 6px 10px; box-shadow: 0 1px 6px rgba(15, 23, 42, 0.06); }
.top h2 { margin: 0; font-size: 18px; font-weight: 900; color: #111827; }

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
</style>
