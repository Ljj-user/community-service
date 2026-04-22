import { ApiService } from '~/common/api/api-service'

export interface BackendResult<T> {
  code: number
  message: string
  data: T
}

export interface BannerVO {
  id: number
  title: string
  subtitle?: string
  imageUrl?: string
  linkUrl?: string
}

const apiService = new ApiService('admin')

export async function bannerList(params?: { communityId?: number | null }) {
  const q = new URLSearchParams()
  if (params?.communityId !== undefined && params?.communityId !== null)
    q.set('communityId', String(params.communityId))
  const s = q.toString()
  return apiService.get<BackendResult<BannerVO[]>>(`banner/list${s ? `?${s}` : ''}`)
}

export async function bannerUpsert(payload: {
  id?: number
  communityId?: number | null
  title: string
  subtitle?: string
  imageUrl?: string
  linkUrl?: string
  sortNo: number
  status: 0 | 1
}) {
  return apiService.post<BackendResult<null>>('banner', payload)
}

export async function bannerDelete(id: number, params?: { communityId?: number | null }) {
  const q = new URLSearchParams()
  if (params?.communityId !== undefined && params?.communityId !== null)
    q.set('communityId', String(params.communityId))
  const s = q.toString()
  return apiService.delete<BackendResult<null>>(`banner/${id}${s ? `?${s}` : ''}`)
}

