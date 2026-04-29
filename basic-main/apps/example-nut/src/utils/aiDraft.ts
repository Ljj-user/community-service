import type { AiOrderDraft } from '@/api/modules/ai'

const STORAGE_KEY = 'community-ai-demand-draft'

export interface StoredAiDraft {
  analysisRecordId?: number
  inputText?: string
  reply?: string
  draft: AiOrderDraft
}

export function saveAiDemandDraft(payload: StoredAiDraft) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(payload))
}

export function loadAiDemandDraft(): StoredAiDraft | null {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as StoredAiDraft
  } catch {
    return null
  }
}

export function clearAiDemandDraft() {
  localStorage.removeItem(STORAGE_KEY)
}
