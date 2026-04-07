<script setup lang="ts">
import Provider from './ui/provider/index.vue'

const route = useRoute()

const appSettingsStore = useAppSettingsStore()
const appKeepAliveStore = useAppKeepAliveStore()

const { auth } = useAppAuth()

const isAuth = computed(() => {
  return route.matched.every((item) => {
    return item.meta.auth ? (item.meta.auth === true ? true : auth(item.meta.auth)) : true
  })
})

watch([
  () => appSettingsStore.settings.app.dynamicTitle,
  () => appSettingsStore.title,
], () => {
  nextTick(() => {
    if (appSettingsStore.settings.app.dynamicTitle && appSettingsStore.title) {
      document.title = appSettingsStore.title ?? import.meta.env.VITE_APP_TITLE
    }
    else {
      document.title = import.meta.env.VITE_APP_TITLE
    }
  })
}, {
  immediate: true,
  deep: true,
})

const enableAppSetting = import.meta.env.VITE_APP_SETTING
</script>

<template>
  <Provider>
    <RouterView v-slot="{ Component }">
      <Transition name="fade" mode="out-in" appear>
        <KeepAlive :include="appKeepAliveStore.list">
          <component :is="Component" v-if="isAuth" :key="route.fullPath" />
          <AppNotAllowed v-else />
        </KeepAlive>
      </Transition>
    </RouterView>
    <template v-if="enableAppSetting">
      <AppSetting />
    </template>
    <FmToast :theme="appSettingsStore.currentColorScheme" />
  </Provider>
</template>

<style scoped>
.navbar-enter-active,
.navbar-leave-active {
  transition: transform 0.15s ease-in-out;
}

.navbar-enter-from,
.navbar-leave-to {
  transform: translateY(-100%);
}

.tabbar-enter-active,
.tabbar-leave-active {
  transition: transform 0.15s ease-in-out;
}

.tabbar-enter-from,
.tabbar-leave-to {
  transform: translateY(100%);
}

/* 主内容区动画 */
.fade-enter-active {
  transition: 0.2s;
}

.fade-leave-active {
  transition: 0.15s;
}

.fade-enter-from {
  opacity: 0;
}

.fade-leave-to {
  opacity: 0;
}
</style>
