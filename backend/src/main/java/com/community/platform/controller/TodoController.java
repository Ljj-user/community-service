package com.community.platform.controller;

import com.community.platform.common.Result;
import com.community.platform.dto.TodoGroupCreateDTO;
import com.community.platform.dto.TodoTaskCreateDTO;
import com.community.platform.dto.TodoTaskUpdateDTO;
import com.community.platform.generated.entity.TodoGroup;
import com.community.platform.generated.entity.TodoTask;
import com.community.platform.security.UserDetailsImpl;
import com.community.platform.service.TodoService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 待办事项接口
 *
 * 供前端 Todo App 使用：
 * - GET /todo/groups             获取当前用户的分组列表
 * - POST /todo/groups            创建分组
 * - GET /todo/groups/{id}/tasks  获取分组下任务
 * - POST /todo/groups/{id}/tasks 在指定分组下创建任务
 */
@RestController
@RequestMapping("/todo")
public class TodoController {

    @Autowired
    private TodoService todoService;

    /**
     * 查询当前用户的所有分组
     */
    @GetMapping("/groups")
    @PreAuthorize("hasAnyRole('USER','COMMUNITY_ADMIN','SUPER_ADMIN')")
    public Result<List<TodoGroup>> listGroups() {
        Long userId = getCurrentUserId();
        return Result.success(todoService.listMyGroups(userId));
    }

    /**
     * 创建分组
     */
    @PostMapping("/groups")
    @PreAuthorize("hasAnyRole('USER','COMMUNITY_ADMIN','SUPER_ADMIN')")
    public Result<TodoGroup> createGroup(@Valid @RequestBody TodoGroupCreateDTO dto) {
        Long userId = getCurrentUserId();
        return Result.success(todoService.createGroup(userId, dto));
    }

    /**
     * 更新分组（标题、图标、颜色）
     */
    @PutMapping("/groups/{groupId}")
    @PreAuthorize("hasAnyRole('USER','COMMUNITY_ADMIN','SUPER_ADMIN')")
    public Result<TodoGroup> updateGroup(@PathVariable("groupId") Long groupId,
                                         @Valid @RequestBody TodoGroupCreateDTO dto) {
        Long userId = getCurrentUserId();
        return Result.success(todoService.updateGroup(userId, groupId, dto));
    }

    /**
     * 查询分组下的任务
     */
    @GetMapping("/groups/{groupId}/tasks")
    @PreAuthorize("hasAnyRole('USER','COMMUNITY_ADMIN','SUPER_ADMIN')")
    public Result<List<TodoTask>> listGroupTasks(@PathVariable("groupId") Long groupId) {
        Long userId = getCurrentUserId();
        return Result.success(todoService.listGroupTasks(userId, groupId));
    }

    /**
     * 在指定分组下创建任务
     */
    @PostMapping("/groups/{groupId}/tasks")
    @PreAuthorize("hasAnyRole('USER','COMMUNITY_ADMIN','SUPER_ADMIN')")
    public Result<TodoTask> createTask(@PathVariable("groupId") Long groupId,
                                       @Valid @RequestBody TodoTaskCreateDTO dto) {
        Long userId = getCurrentUserId();
        // 以路径中的 groupId 为准，保证安全性
        dto.setGroupId(groupId);
        return Result.success(todoService.createTask(userId, dto));
    }

    /**
     * 更新任务状态（完成/收藏）
     */
    @PutMapping("/tasks/{taskId}")
    @PreAuthorize("hasAnyRole('USER','COMMUNITY_ADMIN','SUPER_ADMIN')")
    public Result<TodoTask> updateTask(@PathVariable("taskId") Long taskId,
                                       @RequestBody TodoTaskUpdateDTO dto) {
        Long userId = getCurrentUserId();
        return Result.success(todoService.updateTask(userId, taskId, dto));
    }

    /**
     * 获取当前登录用户ID
     */
    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserDetailsImpl userDetails) {
            return userDetails.getUser().getId();
        }
        throw new RuntimeException("未登录");
    }
}

