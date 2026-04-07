package com.community.platform.service;

import com.community.platform.dto.TodoGroupCreateDTO;
import com.community.platform.dto.TodoTaskCreateDTO;
import com.community.platform.dto.TodoTaskUpdateDTO;
import com.community.platform.generated.entity.TodoGroup;
import com.community.platform.generated.entity.TodoTask;

import java.util.List;

/**
 * 待办事项服务
 */
public interface TodoService {

    /**
     * 查询当前用户的所有分组
     */
    List<TodoGroup> listMyGroups(Long userId);

    /**
     * 创建分组
     */
    TodoGroup createGroup(Long userId, TodoGroupCreateDTO dto);

    /**
     * 更新分组（标题、图标、颜色）
     */
    TodoGroup updateGroup(Long userId, Long groupId, TodoGroupCreateDTO dto);

    /**
     * 查询分组下任务
     */
    List<TodoTask> listGroupTasks(Long userId, Long groupId);

    /**
     * 创建任务
     */
    TodoTask createTask(Long userId, TodoTaskCreateDTO dto);

    /**
     * 更新任务状态（完成/收藏）
     */
    TodoTask updateTask(Long userId, Long taskId, TodoTaskUpdateDTO dto);
}

