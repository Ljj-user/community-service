import api from '@/api'
import type { BackendResult, IPage, ServiceRequestVO } from './serviceRequests'

export interface HallSummaryVO {
  myPublishedCount: number
  /** 我作为志愿者已完成的任务数 */
  myCompletedCount?: number
  inProgressCount: number
  receivedEvaluationCount: number
  receivedAvgRating?: number | null
}

export interface ServiceClaimVO {
  id: number
  requestId: number
  requestTitle?: string
  requestAddress?: string
  volunteerUserId?: number
  volunteerName?: string
  claimAt?: string
  claimStatus: number
  serviceHours?: number
  hoursSubmittedAt?: string
  completionNote?: string
  createdAt?: string
}

export interface VolunteerEvaluationVO {
  id: number
  claimId: number
  requestId: number
  serviceType?: string
  serviceAddress?: string
  residentUserId?: number
  residentName?: string
  rating: number
  content?: string
  createdAt?: string
}

export interface ServiceEvaluationHistoryVO {
  id: number
  claimId: number
  requestId: number
  serviceType?: string
  serviceAddress?: string
  volunteerUserId?: number
  volunteerName?: string
  rating: number
  content?: string
  createdAt?: string
}

export function getHallSummary() {
  return api.get<any, BackendResult<HallSummaryVO>>('/hall/summary')
}

export function getMyPublishHistory(current = 1, size = 10) {
  const query = new URLSearchParams({
    current: String(current),
    size: String(size),
  })
  return api.get<any, BackendResult<IPage<ServiceRequestVO>>>(`/service-request/my-list?${query.toString()}`)
}

export function getMyClaimRecords(current = 1, size = 20) {
  const query = new URLSearchParams({
    current: String(current),
    size: String(size),
  })
  return api.get<any, BackendResult<IPage<ServiceClaimVO>>>(`/service-claim/my-records?${query.toString()}`)
}

export function getMyReceivedReviews(current = 1, size = 10) {
  const query = new URLSearchParams({
    current: String(current),
    size: String(size),
  })
  return api.get<any, BackendResult<IPage<VolunteerEvaluationVO>>>(`/service-evaluation/my-received?${query.toString()}`)
}

export function getMyReviewHistory(current = 1, size = 10) {
  const query = new URLSearchParams({
    current: String(current),
    size: String(size),
  })
  return api.get<any, BackendResult<IPage<ServiceEvaluationHistoryVO>>>(`/service-evaluation/my-history?${query.toString()}`)
}
