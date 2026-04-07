import { ApiService } from '~/common/api/api-service'
import type {
  GroupCreateModel,
  TaskCreateModel,
  TaskGroup,
  TaskItem,
} from '~/models/Todo'

// 后端统一使用 Result<T> 包装
interface BackendResult<T> {
  code: number
  message: string
  data: T
}

// 对应后端 /todo/** 接口
const apiService = new ApiService('todo')

class TodoService {
  async loadGroups(): Promise<TaskGroup[]> {
    const res = await apiService.get<BackendResult<TaskGroup[]>>('groups')
    return res.data ?? []
  }

  async loadTasks(groupId: number): Promise<TaskItem[]> {
    const res = await apiService.get<BackendResult<TaskItem[]>>(
      `groups/${groupId}/tasks`,
    )
    return res.data ?? []
  }

  async createTask(task: TaskCreateModel): Promise<TaskItem> {
    const res = await apiService.post<BackendResult<TaskItem>>(
      `groups/${task.groupId}/tasks`,
      task,
    )
    return res.data
  }

  async createGroup(group: GroupCreateModel): Promise<TaskGroup> {
    const res = await apiService.post<BackendResult<TaskGroup>>(
      'groups',
      group,
    )
    return res.data
  }

  async updateGroup(group: TaskGroup): Promise<TaskGroup> {
    const payload: GroupCreateModel = {
      title: group.title,
      icon: group.icon,
      bgColor: group.bgColor,
    }
    const res = await apiService.put<BackendResult<TaskGroup>>(
      `groups/${group.id}`,
      payload,
    )
    return res.data
  }

  async updateTask(task: TaskItem): Promise<TaskItem> {
    const payload = {
      isDone: task.isDone,
      isFavorite: task.isFavorite,
    }
    const res = await apiService.put<BackendResult<TaskItem>>(
      `tasks/${task.id}`,
      payload,
    )
    return res.data
  }
}

export default new TodoService()

