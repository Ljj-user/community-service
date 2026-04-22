import api from '../index'
import type { BackendResult, UserInfo } from '@/store/modules/app/auth'

export interface UserProfileResponse {
  id: number
  username: string
  realName?: string
  phone?: string
  email?: string
  avatarUrl?: string
  role?: number
  identityType?: number
  communityId?: number
  communityName?: string
  province?: string
  city?: string
  timeCoins?: number
  points?: number
  identityTag?: string
  gender?: 0 | 1 | 2
  skillTags?: string
  address?: string
  createdAt?: string
}

export interface UserProfileUpdateRequest {
  username?: string
  realName?: string
  phone?: string
  email?: string
  avatarUrl?: string
  address?: string
  communityId?: number
  gender?: 0 | 1 | 2
  skillTags?: string
  identityTag?: string
}

export function getMyProfile() {
  return api.get<any, BackendResult<UserProfileResponse>>('/user/profile')
}

export function updateMyProfile(data: UserProfileUpdateRequest) {
  return api.put<any, BackendResult<UserProfileResponse>>('/user/profile', data)
}

export function uploadMyAvatar(file: File) {
  const form = new FormData()
  form.append('file', file)
  return api.post<any, BackendResult<UserProfileResponse>>('/user/avatar', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
  })
}

