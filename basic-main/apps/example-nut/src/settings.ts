import { setSettings } from '@fantastic-mobile/settings'

export default setSettings({
  // 请在此处编写或粘贴配置代码
  tabbar: {
    list: [
      {
        path: '/',
        icon: 'mdi:home-outline',
        activeIcon: 'mdi:home',
        text: '主页',
      },
      {
        path: '/hall',
        icon: 'mdi:view-grid-outline',
        activeIcon: 'mdi:view-grid',
        text: '大厅',
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
