import api from '../index'
import type { BackendResult, UserInfo } from '@/store/modules/app/auth'

interface LoginData {
  token: string
  userInfo: UserInfo
}

export default {
  // 登录
  login: (data: {
    account: string
    password: string
  }) => api.post<any, BackendResult<LoginData>>('/auth/login', {
    username: data.account,
    password: data.password,
  }),

  // 获取当前用户信息
  me: () => api.get<any, BackendResult<UserInfo>>('/auth/me'),
}
