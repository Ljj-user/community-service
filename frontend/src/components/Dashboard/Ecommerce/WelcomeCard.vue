<script setup lang="ts">
const { t } = useI18n()
const profileStore = useProfileStore()

const daysInCommunity = computed(() => {
  const createdAt = profileStore.userProfile?.createdAt
  if (!createdAt) return 0
  const created = new Date(createdAt)
  const now = new Date()
  const diffMs = now.getTime() - created.getTime()
  return Math.max(0, Math.floor(diffMs / (1000 * 60 * 60 * 24)))
})

onMounted(() => {
  if (!profileStore.userProfile?.id) {
    profileStore.loadUserProfile()
  }
})
</script>

<template>
  <div class="h-auto flex flex-col justify-end relative">
    <div class="p-2">
      <Card>
        <div class="flex flex-row justify-between">
          <div class="flex flex-row md:pt-4">
            <span class="text-12 me-2">👋 </span>
            <div>
              <h3 class="text-lg font-bold">
                {{ t('dashboard.welcome.title') }}
              </h3>

              <p class="description">
                {{ t('dashboard.welcome.greeting_message') }}
              </p>
              <p class="description pt-7">
                你已来到互助社区
                <b class="inline-block min-w-12 px-1 text-size-lg">
                  <n-number-animation show-separator :from="0" :to="daysInCommunity" />
                </b>
                天
              </p>
            </div>
          </div>
          <img src="@/assets/images/3d-female-character-waving.png" width="140px"
            class="hidden md:block -mt-24 -mb-4 me-6 cursor-pointer">
        </div>
      </card>
    </div>
  </div>
</template>

<style scoped>
.confetti-container
{
  position: absolute;
  left:0;
  right:0;
  bottom:0;
  z-index: 10;
  height: 250px;
  width: 100%;
}

.description{
  font-size: .99rem;
}
</style>
