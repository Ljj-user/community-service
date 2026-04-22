<script setup lang="ts">
import { toTypedSchema } from '@vee-validate/zod'
import { useForm } from 'vee-validate'
import * as z from 'zod'
import { FormControl, FormField, FormItem, FormMessage } from '@/ui/shadcn/ui/form'
import apiApp from '@/api/modules/app'

definePage({
  name: 'register',
  meta: {
    title: '注册',
  },
})

const router = useRouter()
const appAuthStore = useAppAuthStore()
const loading = ref(false)
const sending = ref(false)
const countdown = ref(0)
let timer: any = null

const form = useForm({
  validationSchema: toTypedSchema(z.object({
    username: z.string().min(2, '请输入用户名'),
    password: z.string().min(6, '密码至少6位'),
    realName: z.string().min(1, '请输入姓名'),
    phone: z.string().regex(/^1[3-9]\d{9}$/, '手机号格式不正确'),
    email: z.string().email('邮箱格式不正确'),
    verificationCode: z.string().min(4, '请输入验证码'),
    identityType: z.number().min(1),
  })),
  initialValues: {
    username: '',
    password: '',
    realName: '',
    phone: '',
    email: '',
    verificationCode: '',
    identityType: 1,
  },
})

async function sendCode() {
  const email = (form.values.email || '').trim()
  if (!email || sending.value || countdown.value > 0)
    return
  sending.value = true
  try {
    const res = await apiApp.sendVerificationCode({ email, scene: 'REGISTER' })
    if (res.code !== 200)
      throw new Error(res.message || '发送失败')
    if (res.data?.devCode)
      alert(`验证码（演示）: ${res.data.devCode}`)
    countdown.value = 60
    timer = setInterval(() => {
      countdown.value -= 1
      if (countdown.value <= 0) {
        clearInterval(timer)
        timer = null
      }
    }, 1000)
  } catch (e: any) {
    alert(e?.message || '发送失败')
  } finally {
    sending.value = false
  }
}

const onSubmit = form.handleSubmit(async (values) => {
  loading.value = true
  try {
    const res = await apiApp.register({
      username: values.username,
      password: values.password,
      realName: values.realName,
      phone: values.phone,
      email: values.email,
      verificationCode: values.verificationCode,
      verificationScene: 'REGISTER',
      identityType: values.identityType,
    })
    if (res.code !== 200)
      throw new Error(res.message || '注册失败')
    await appAuthStore.login({ account: values.username, password: values.password })
    router.replace('/user')
  } catch (e: any) {
    alert(e?.message || '注册失败')
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <AppPageLayout :navbar="false" copyright>
    <div class="mx-4 flex flex-1 flex-col gap-6 justify-center">
      <div class="text-center space-y-2">
        <div class="text-7 font-black">
          注册账号
        </div>
        <div class="text-stone-5 text-sm">
          注册后即可在移动端体验互助功能
        </div>
      </div>

      <form @submit="onSubmit">
        <div class="mx-2 border rounded-xl bg-card overflow-hidden divide-y">
          <FormField v-slot="{ componentField }" name="username">
            <FormItem class="p-1 space-y-0">
              <FormControl>
                <FmInput type="text" placeholder="用户名" class="border-none w-full" v-bind="componentField" />
              </FormControl>
              <FormMessage class="text-xs pb-2 pl-3" />
            </FormItem>
          </FormField>
          <FormField v-slot="{ componentField }" name="realName">
            <FormItem class="p-1 space-y-0">
              <FormControl>
                <FmInput type="text" placeholder="姓名" class="border-none w-full" v-bind="componentField" />
              </FormControl>
              <FormMessage class="text-xs pb-2 pl-3" />
            </FormItem>
          </FormField>
          <FormField v-slot="{ componentField }" name="phone">
            <FormItem class="p-1 space-y-0">
              <FormControl>
                <FmInput type="text" placeholder="手机号" class="border-none w-full" v-bind="componentField" />
              </FormControl>
              <FormMessage class="text-xs pb-2 pl-3" />
            </FormItem>
          </FormField>
          <FormField v-slot="{ componentField }" name="email">
            <FormItem class="p-1 space-y-0">
              <FormControl>
                <FmInput type="text" placeholder="邮箱（验证码）" class="border-none w-full" v-bind="componentField" />
              </FormControl>
              <FormMessage class="text-xs pb-2 pl-3" />
            </FormItem>
          </FormField>
          <FormField v-slot="{ componentField }" name="verificationCode">
            <FormItem class="p-1 space-y-0">
              <FormControl>
                <div class="flex items-center gap-2">
                  <FmInput type="text" placeholder="验证码" class="border-none w-full" v-bind="componentField" />
                  <FmButton size="sm" variant="outline" type="button" :disabled="countdown>0" :loading="sending" @click="sendCode">
                    {{ countdown > 0 ? `${countdown}s` : '发送' }}
                  </FmButton>
                </div>
              </FormControl>
              <FormMessage class="text-xs pb-2 pl-3" />
            </FormItem>
          </FormField>
          <FormField v-slot="{ componentField }" name="identityType">
            <FormItem class="p-2 space-y-0">
              <FormControl>
                <div class="flex gap-2 text-sm">
                  <label class="flex items-center gap-1">
                    <input type="radio" :value="1" v-bind="componentField">
                    居民
                  </label>
                  <label class="flex items-center gap-1">
                    <input type="radio" :value="2" v-bind="componentField">
                    志愿者
                  </label>
                </div>
              </FormControl>
              <FormMessage class="text-xs pb-2 pl-3" />
            </FormItem>
          </FormField>
          <FormField v-slot="{ componentField }" name="password">
            <FormItem class="p-1 space-y-0">
              <FormControl>
                <FmInput type="password" placeholder="密码" class="border-none w-full" v-bind="componentField" />
              </FormControl>
              <FormMessage class="text-xs pb-2 pl-3" />
            </FormItem>
          </FormField>
        </div>

        <div class="mt-6 px-4 space-y-3">
          <FmButton :loading class="w-full" type="submit">
            注册并登录
          </FmButton>
          <FmButton variant="ghost" class="w-full" type="button" @click="router.replace('/login')">
            返回登录
          </FmButton>
        </div>
      </form>
    </div>
  </AppPageLayout>
</template>

