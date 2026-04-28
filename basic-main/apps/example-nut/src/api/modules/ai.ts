import api from '@/api'
import type { BackendResult } from './serviceRequests'

export interface AiOrderDraft {
  serviceType: string
  urgencyLevel: number
  expectedTime?: string
  tags?: string[]
  description?: string
}

export interface AiChatResponse {
  mode: 'DEMAND_DRAFT' | 'FAQ'
  reply: string
  orderDraft?: AiOrderDraft
}

export interface AiChatHistoryMessage {
  role: 'user' | 'assistant' | 'ai'
  text: string
}

export function aiChat(message: string, history?: AiChatHistoryMessage[]) {
  return api.post<any, BackendResult<AiChatResponse>>('/ai/chat', { message, history })
}
