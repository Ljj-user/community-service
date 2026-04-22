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
  router.push('/scan')
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
    <div class="mx-4 flex flex-1 flex-col gap-4 justify-center">
      <div class="text-center space-y-2">
        <div class="text-7 font-black">
          加入社区
        </div>
        <div class="text-stone-5 text-sm">
          请输入邀请码或扫码加入；后续再次输入新码可改绑社区
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
            扫码
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
  </AppPageLayout>
</template>

