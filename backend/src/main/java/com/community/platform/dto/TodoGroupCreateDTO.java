package com.community.platform.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 待办事项分组创建 DTO
 */
@Data
public class TodoGroupCreateDTO {

    @NotBlank(message = "分组标题不能为空")
    private String title;

    @NotBlank(message = "分组图标不能为空")
    private String icon;

    private String bgColor;
}

