import { acceptHMRUpdate, defineStore } from 'pinia'

import type {
  GroupCreateModel,
  TaskCreateModel,
  TaskGroup,
  TaskItem,
} from '~/models/Todo'
import todoService from '~/services/todo.service'

export const useTodoAppStore = defineStore('Todo', () => {
  const groups = ref<TaskGroup[]>([])
  const tasks = ref<TaskItem[]>([])

  const isLoadingGroups = ref(false)
  const isLoadingTasks = ref(false)

  async function loadGroups() {
    isLoadingGroups.value = true
    try {
      groups.value = await todoService.loadGroups()
    } finally {
      isLoadingGroups.value = false
    }
  }

  async function loadGroupTasks(groupId: number) {
    isLoadingTasks.value = true
    try {
      const result = await todoService.loadTasks(groupId)
      tasks.value = Array.isArray(result) ? result : []
    } finally {
      isLoadingTasks.value = false
    }
  }

  async function createGroup(group: TaskGroup) {
    // 防御：确保 groups 为数组
    if (!Array.isArray(groups.value)) {
      groups.value = []
    }

    const payload: GroupCreateModel = {
      title: group.title,
      icon: group.icon,
      bgColor: group.bgColor,
    }
    const created = await todoService.createGroup(payload)
    groups.value.push(created as TaskGroup)
    window.umami?.track('Todo:CreateGroup', { title: group.title })
  }

  async function updateGroup(group: TaskGroup) {
    const updated = await todoService.updateGroup(group)
    const index = groups.value.findIndex((g: TaskGroup) => g.id === group.id)
    if (index !== -1) {
      groups.value[index] = updated as TaskGroup
    }
  }

  function deleteGroup(id: number) {
    const index = groups.value.findIndex((x: TaskGroup) => x.id === id)
    if (index) groups.value.splice(index, 1)
  }

  async function toggleDoneTask(id: number) {
    const task = tasks.value.find((x: TaskItem) => x.id === id)
    if (!task) return

    task.isDone = !task.isDone
    task.doneDate = task.isDone ? new Date() : undefined

    // 同步到后端
    await todoService.updateTask(task)
  }

  async function toggleFavTask(id: number) {
    const task = tasks.value.find((x: TaskItem) => x.id === id)
    if (!task) return

    task.isFavorite = !task.isFavorite
    if (task.isFavorite) window.umami?.track('Todo:FavTask')

    // 同步到后端
    await todoService.updateTask(task)
  }

  function deleteTask(id: number) {
    const taskIndex = tasks.value.findIndex((x: TaskItem) => x.id === id)
    if (taskIndex > -1) {
      tasks.value.splice(taskIndex, 1)
    }
  }

  async function createTask(task: TaskCreateModel) {
    if (!Array.isArray(tasks.value)) {
      tasks.value = []
    }

    const result = await todoService.createTask(task)
    // 将新任务插入到列表最前面
    tasks.value.unshift(result as TaskItem)
    window.umami?.track('Todo:CreateTask', { title: task.title })
  }

  const counts = computed(() => {
    return groups.value.map((g: TaskGroup) => ({
      id: g.id,
      count: tasks.value.filter(
        (x: TaskItem) => x.groupId === g.id && !x.isDone,
      ).length,
    }))
  })

  return {
    isLoadingGroups,
    isLoadingTasks,
    groups,
    tasks,
    loadGroups,
    loadGroupTasks,
    createGroup,
    updateGroup,
    createTask,
    toggleDoneTask,
    toggleFavTask,
    deleteGroup,
    deleteTask,
    counts,
  }
})
if (import.meta.hot)
  import.meta.hot.accept(acceptHMRUpdate(useTodoAppStore, import.meta.hot))
