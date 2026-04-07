-- 待办事项分组表
CREATE TABLE IF NOT EXISTS todo_group (
    id           BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id      BIGINT      NOT NULL COMMENT '所属用户ID',
    title        VARCHAR(100) NOT NULL COMMENT '分组标题',
    icon         VARCHAR(16)  NOT NULL COMMENT '分组图标（emoji 或图标编码）',
    bg_color     VARCHAR(32)  NULL COMMENT '背景颜色',
    is_today     TINYINT(1)   DEFAULT 0 COMMENT '是否今日任务分组',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='待办事项分组表';

CREATE INDEX idx_todo_group_user ON todo_group (user_id);

-- 待办事项任务表
CREATE TABLE IF NOT EXISTS todo_task (
    id           BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    user_id      BIGINT      NOT NULL COMMENT '所属用户ID（冗余，便于按用户查询）',
    group_id     BIGINT      NOT NULL COMMENT '所属分组ID',
    title        VARCHAR(255) NOT NULL COMMENT '任务标题',
    is_done      TINYINT(1)   DEFAULT 0 COMMENT '是否完成',
    is_favorite  TINYINT(1)   DEFAULT 0 COMMENT '是否收藏/置顶',
    is_today     TINYINT(1)   DEFAULT 0 COMMENT '是否今日任务',
    sort_order   INT          DEFAULT 0 COMMENT '排序序号',
    done_date    DATETIME     NULL COMMENT '完成时间',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='待办事项任务表';

CREATE INDEX idx_todo_task_group ON todo_task (group_id);
CREATE INDEX idx_todo_task_user ON todo_task (user_id);

