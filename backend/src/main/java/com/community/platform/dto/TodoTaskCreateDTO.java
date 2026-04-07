package com.community.platform.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 待办事项任务创建 DTO
 */
@Data
public class TodoTaskCreateDTO {

    @NotBlank(message = "任务标题不能为空")
    private String title;

    @NotNull(message = "分组ID不能为空")
    private Long groupId;
}

