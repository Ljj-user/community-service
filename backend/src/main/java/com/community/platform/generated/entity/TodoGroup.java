package com.community.platform.generated.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 待办事项分组表
 */
@Getter
@Setter
@ToString
@TableName("todo_group")
public class TodoGroup implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属用户ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 分组标题
     */
    @TableField("title")
    private String title;

    /**
     * 图标
     */
    @TableField("icon")
    private String icon;

    /**
     * 背景颜色
     */
    @TableField("bg_color")
    private String bgColor;

    /**
     * 是否今日任务分组
     */
    @TableField("is_today")
    private Boolean isToday;

    @TableField("created_at")
    private LocalDateTime createdAt;

    @TableField("updated_at")
    private LocalDateTime updatedAt;
}

