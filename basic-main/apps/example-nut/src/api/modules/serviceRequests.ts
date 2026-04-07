import api from '@/api'

export interface BackendResult<T> {
  code: number
  message: string
  data: T
}

export interface IPage<T> {
  records: T[]
  total: number
  size: number
  current: number
}

export interface ServiceRequestVO {
  id: number
  serviceType: string
  serviceAddress: string
  requesterName?: string
  urgencyLevel: number
  status: number
  expectedTime?: string
  publishedAt?: string
  createdAt?: string
  description?: string
  communityName?: string
  province?: string
  city?: string
}

export function getPublishedRequests(current = 1, size = 10, serviceType?: string) {
  const query = new URLSearchParams({
    status: '1',
    current: String(current),
    size: String(size),
  })
  if (serviceType && serviceType !== '全部需求') {
    query.set('serviceType', serviceType)
  }
  return api.get<any, BackendResult<IPage<ServiceRequestVO>>>(`/service-request/list?${query.toString()}`)
}

