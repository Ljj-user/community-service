import { ApiService } from '~/common/api/api-service'

export interface BackendResult<T> {
  code: number
  message: string
  data: T
}

const apiService = new ApiService('admin')

export async function configGetBasic() {
  return apiService.get<BackendResult<Record<string, unknown>>>('config/basic')
}

export async function configSaveBasic(data: Record<string, unknown>) {
  return apiService.put<BackendResult<null>>('config/basic', data)
}

export async function configGetNotice() {
  return apiService.get<BackendResult<Record<string, unknown>>>('config/notice')
}

export async function configSaveNotice(data: Record<string, unknown>) {
  return apiService.put<BackendResult<null>>('config/notice', data)
}

export async function configGetAlert() {
  return apiService.get<BackendResult<Record<string, unknown>>>('config/alert')
}

export async function configSaveAlert(data: Record<string, unknown>) {
  return apiService.put<BackendResult<null>>('config/alert', data)
}
