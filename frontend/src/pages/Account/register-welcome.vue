<script setup lang="ts">
const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const isVolunteer = computed(() => route.query.identity === 'volunteer')

function goProfile() {
  router.push('/Account/profile')
}
</script>

<route lang="yaml">
meta:
  title: registerWelcome
  layout: auth
  authRequired: true
</route>

<template>
  <div class="min-h-[70vh] flex flex-col items-center justify-center px-4 py-10">
    <div class="max-w-lg w-full rounded-2xl border border-slate-200 dark:border-slate-600 bg-white dark:bg-slate-800 shadow-lg p-8 md:p-10 text-center">
      <div class="text-2xl md:text-3xl font-semibold mb-4 leading-snug">
        {{ isVolunteer ? t('register.welcomeVolunteerTitle') : t('register.welcomeResidentTitle') }}
      </div>
      <p class="text-lg md:text-xl text-slate-600 dark:text-slate-300 mb-8 leading-relaxed">
        {{ isVolunteer ? t('register.welcomeVolunteerHint') : t('register.welcomeResidentHint') }}
      </p>
      <n-button type="primary" size="large" class="!text-lg !px-10 !h-12" @click="goProfile">
        {{ t('register.welcomeGoProfile') }}
      </n-button>
    </div>
  </div>
</template>
