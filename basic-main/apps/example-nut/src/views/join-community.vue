<script setup lang="ts">
import apiApp from '@/api/modules/app'
import { toast } from 'vue-sonner'

definePage({
  name: 'join-community',
  meta: {
    title: '加入社区',
    auth: true,
  },
})

const router = useRouter()
const route = useRoute()
const appAuthStore = useAppAuthStore()

const code = ref((route.query.code?.toString() ?? '').trim())
const verifying = ref(false)
const joining = ref(false)

const preview = ref<{ communityId: number; communityName: string } | null>(null)

async function verify() {
  const v = code.value.trim()
  if (!v) {
    toast.error('请输入邀请码')
    return
  }
  verifying.value = true
  try {
    const res = await apiApp.verifyInviteCode({ code: v })
    if (res.code !== 200)
      throw new Error(res.message || '邀请码无效')
    preview.value = {
      communityId: res.data.communityId,
      communityName: res.data.communityName,
    }
  } catch (e: any) {
    preview.value = null
    toast.error(e?.message || '校验失败')
  } finally {
    verifying.value = false
  }
}

async function join() {
  const v = code.value.trim()
  if (!v) {
    toast.error('请输入邀请码')
    return
  }
  joining.value = true
  try {
    const res = await apiApp.joinCommunity({ code: v })
    if (res.code !== 200)
      throw new Error(res.message || '绑定失败')
    toast.success('社区绑定成功')
    await appAuthStore.hydrateUser()
    router.replace('/hall')
  } catch (e: any) {
    toast.error(e?.message || '绑定失败')
  } finally {
    joining.value = false
  }
}

function goScan() {
  toast.info('暂未开放扫码功能，请先输入邀请码加入社区')
}

watch(
  () => route.query.code,
  (v) => {
    const s = (v?.toString() ?? '').trim()
    if (s) {
      code.value = s
      void verify()
    }
  },
)

onMounted(() => {
  if (code.value)
    void verify()
})
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="join-page">
      <header class="top">
        <button type="button" class="back-btn" aria-label="返回" @click="router.back()">
          <FmIcon name="i-carbon:arrow-left" />
        </button>
        <h2>加入社区</h2>
      </header>

      <div class="mx-4 flex flex-1 flex-col gap-4 justify-center">
      <div class="text-center space-y-2">
        <div class="text-7 font-black">
          输入邀请码
        </div>
        <div class="text-stone-5 text-sm">
          请输入邀请码加入；后续再次输入新码可改绑社区
        </div>
      </div>

      <div class="mx-2 border rounded-xl bg-card overflow-hidden divide-y">
        <div class="p-2">
          <FmInput v-model="code" type="text" placeholder="邀请码（例如：ABCD1234）" class="border-none w-full" />
        </div>
      </div>

      <div v-if="preview" class="mx-2 p-3 rounded-xl bg-white border text-sm">
        将加入：<span class="font-bold">{{ preview.communityName }}</span>（{{ preview.communityId }}）
      </div>

      <div class="mt-2 px-4 space-y-3">
        <div class="grid grid-cols-2 gap-3">
          <FmButton variant="outline" type="button" :loading="verifying" @click="verify">
            校验
          </FmButton>
          <FmButton variant="outline" type="button" @click="goScan">
            扫码（暂未开放）
          </FmButton>
        </div>
        <FmButton class="w-full" type="button" :loading="joining" @click="join">
          确认加入
        </FmButton>
        <FmButton variant="ghost" class="w-full" type="button" @click="appAuthStore.logout()">
          退出登录
        </FmButton>
      </div>
    </div>
    </div>
  </AppPageLayout>
</template>

<style scoped>
.join-page { min-height: 100%; background: #f4f6f8; display: flex; flex-direction: column; }
.top { display: flex; align-items: center; gap: 10px; padding: 12px 14px 8px; }
.back-btn { border: 0; background: #fff; width: 34px; height: 34px; border-radius: 999px; display: inline-flex; align-items: center; justify-content: center; color: #111827; }
.top h2 { margin: 0; font-size: 18px; font-weight: 900; color: #111827; }
:global(.dark) .join-page { background: #111827; }
:global(.dark) .back-btn { background: #1f2937; color: #f3f4f6; border: 1px solid #374151; }
:global(.dark) .top h2 { color: #f3f4f6; }
</style>

