import { setSettings } from '@fantastic-mobile/settings'

export default setSettings({
  // 请在此处编写或粘贴配置代码
  tabbar: {
    list: [
      {
        path: '/',
        icon: 'mdi:home-outline',
        activeIcon: 'mdi:home',
        text: '首页',
      },
      {
        path: '/hall',
        icon: 'mdi:clipboard-text-outline',
        activeIcon: 'mdi:clipboard-text',
        text: '任务',
      },
      {
        path: '/messages',
        icon: 'mdi:message-processing-outline',
        activeIcon: 'mdi:message-processing',
        text: '消息',
      },
      {
        path: '/user/',
        icon: 'mdi:account-outline',
        activeIcon: 'mdi:account',
        text: '我的',
      },
    ],
  },
})
