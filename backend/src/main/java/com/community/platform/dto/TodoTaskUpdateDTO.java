package com.community.platform.dto;

import lombok.Data;

/**
 * 待办事项任务状态更新 DTO
 */
@Data
public class TodoTaskUpdateDTO {

    /**
     * 是否完成（可选）
     */
    private Boolean isDone;

    /**
     * 是否收藏（可选）
     */
    private Boolean isFavorite;
}

