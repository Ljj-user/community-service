import HttpClient from '~/common/api/http-client'

const client = HttpClient()

export type ExportModule = 'service_request' | 'users' | 'audit'
export type ExportFormat = 'excel' | 'pdf'

export async function exportModule(params: {
  module: ExportModule
  format: ExportFormat
  startTime?: string
  endTime?: string
}) {
  return client.get(`admin/export/${params.module}`, {
    params: {
      format: params.format,
      startTime: params.startTime,
      endTime: params.endTime,
    },
    responseType: 'blob',
  })
}

