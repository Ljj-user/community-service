import apiApp from '@/api/modules/app'
import router from '@/router'

export interface BackendResult<T> {
  code: number
  message: string
  data: T
}

export interface UserInfo {
  id: number
  username: string
  role: number
  identityType?: number
  realName?: string
  communityId?: number
  /** 绑定社区名称（后端由 sys_user.community_id 关联 sys_region） */
  communityName?: string
  /** 省、市（展示用，来自 sys_region） */
  province?: string
  city?: string
  timeCoins?: number
  points?: number
}

export interface LoginData {
  token: string
  userInfo: UserInfo
}

export const useAppAuthStore = defineStore(
  'appAuth',
  () => {
    // 账号信息
    const account = ref(localStorage.account ?? '')
    const token = ref(localStorage.token ?? '')
    const avatar = ref(localStorage.avatar ?? '')
    const user = ref<UserInfo | null>(localStorage.user ? JSON.parse(localStorage.user) : null)

    // 权限信息
    const isGetPermissions = ref(false)
    const permissions = ref<string[]>([])

    // 登录状态
    const isLogin = computed(() => {
      if (token.value) {
        return true
      }
      return false
    })

    // 登录
    function login(data: {
      account: string
      password: string
    }) {
      return new Promise<BackendResult<LoginData>>((resolve, reject) => {
        apiApp.login(data).then((res) => {
          if (res.code !== 200 || !res.data?.token) {
            reject(new Error(res.message || '登录失败'))
            return
          }
          // 移动端仅允许普通用户
          if (res.data.userInfo?.role !== 3) {
            logout()
            reject(new Error('当前账号为管理端账号，请使用PC后台登录'))
            return
          }
          localStorage.setItem('account', res.data.userInfo.realName || res.data.userInfo.username || data.account)
          localStorage.setItem('token', res.data.token)
          localStorage.setItem('avatar', '')
          localStorage.setItem('user', JSON.stringify(res.data.userInfo))
          account.value = localStorage.account
          token.value = res.data.token
          avatar.value = ''
          user.value = res.data.userInfo
          resolve(res)
        }).catch((error) => {
          reject(error)
        })
      })
    }

    // 刷新用户信息（用于页面展示）
    async function hydrateUser() {
      if (!token.value) return
      try {
        const res = await apiApp.me()
        if (res.code === 200) {
          user.value = res.data
          localStorage.setItem('user', JSON.stringify(res.data))
          account.value = res.data.realName || res.data.username || account.value
          localStorage.setItem('account', account.value)
        }
      }
      catch {}
    }

    // 登出
    function logout() {
      // 模拟退出登录，清除 token 信息
      localStorage.removeItem('account')
      localStorage.removeItem('token')
      localStorage.removeItem('avatar')
      localStorage.removeItem('user')
      account.value = ''
      token.value = ''
      avatar.value = ''
      user.value = null
      router.push('/')
    }

    // 获取权限
    async function getPermissions() {
      // 你的项目移动端目前不依赖权限点，这里保持兼容空实现
      permissions.value = []
      isGetPermissions.value = true
    }

    return {
      account,
      token,
      avatar,
      user,
      isLogin,
      isGetPermissions,
      permissions,
      login,
      hydrateUser,
      logout,
      getPermissions,
    }
  },
)
