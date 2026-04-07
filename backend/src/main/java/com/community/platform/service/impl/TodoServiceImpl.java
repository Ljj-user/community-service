package com.community.platform.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.community.platform.dto.TodoGroupCreateDTO;
import com.community.platform.dto.TodoTaskCreateDTO;
import com.community.platform.dto.TodoTaskUpdateDTO;
import com.community.platform.generated.entity.TodoGroup;
import com.community.platform.generated.entity.TodoTask;
import com.community.platform.generated.mapper.TodoGroupMapper;
import com.community.platform.generated.mapper.TodoTaskMapper;
import com.community.platform.service.TodoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 待办事项服务实现
 */
@Service
public class TodoServiceImpl implements TodoService {

    @Autowired
    private TodoGroupMapper todoGroupMapper;

    @Autowired
    private TodoTaskMapper todoTaskMapper;

    @Override
    public List<TodoGroup> listMyGroups(Long userId) {
        LambdaQueryWrapper<TodoGroup> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(TodoGroup::getUserId, userId)
                .orderByAsc(TodoGroup::getId);
        return todoGroupMapper.selectList(wrapper);
    }

    @Override
    public TodoGroup createGroup(Long userId, TodoGroupCreateDTO dto) {
        TodoGroup group = new TodoGroup();
        group.setUserId(userId);
        group.setTitle(dto.getTitle());
        group.setIcon(dto.getIcon());
        group.setBgColor(dto.getBgColor());
        group.setIsToday(Boolean.FALSE);
        group.setCreatedAt(LocalDateTime.now());
        group.setUpdatedAt(LocalDateTime.now());
        todoGroupMapper.insert(group);
        return group;
    }

    @Override
    public TodoGroup updateGroup(Long userId, Long groupId, TodoGroupCreateDTO dto) {
        TodoGroup group = todoGroupMapper.selectById(groupId);
        if (group == null || !userId.equals(group.getUserId())) {
            throw new RuntimeException("分组不存在或无权限修改");
        }
        group.setTitle(dto.getTitle());
        group.setIcon(dto.getIcon());
        group.setBgColor(dto.getBgColor());
        group.setUpdatedAt(LocalDateTime.now());
        todoGroupMapper.updateById(group);
        return group;
    }

    @Override
    public List<TodoTask> listGroupTasks(Long userId, Long groupId) {
        LambdaQueryWrapper<TodoTask> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(TodoTask::getUserId, userId)
                .eq(TodoTask::getGroupId, groupId)
                .orderByAsc(TodoTask::getSortOrder)
                .orderByDesc(TodoTask::getCreatedAt);
        return todoTaskMapper.selectList(wrapper);
    }

    @Override
    public TodoTask createTask(Long userId, TodoTaskCreateDTO dto) {
        TodoTask task = new TodoTask();
        task.setUserId(userId);
        task.setGroupId(dto.getGroupId());
        task.setTitle(dto.getTitle());
        task.setIsDone(Boolean.FALSE);
        task.setIsFavorite(Boolean.FALSE);
        task.setIsToday(Boolean.FALSE);
        task.setSortOrder(0);
        task.setCreatedAt(LocalDateTime.now());
        task.setUpdatedAt(LocalDateTime.now());
        todoTaskMapper.insert(task);
        return task;
    }

    @Override
    public TodoTask updateTask(Long userId, Long taskId, TodoTaskUpdateDTO dto) {
        TodoTask task = todoTaskMapper.selectById(taskId);
        if (task == null || !userId.equals(task.getUserId())) {
            throw new RuntimeException("任务不存在或无权限修改");
        }

        if (dto.getIsDone() != null) {
            task.setIsDone(dto.getIsDone());
            task.setDoneDate(dto.getIsDone() ? LocalDateTime.now() : null);
        }
        if (dto.getIsFavorite() != null) {
            task.setIsFavorite(dto.getIsFavorite());
        }
        task.setUpdatedAt(LocalDateTime.now());
        todoTaskMapper.updateById(task);
        return task;
    }
}

