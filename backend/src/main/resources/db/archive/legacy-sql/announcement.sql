USE community_service;

DROP TABLE IF EXISTS announcement;
CREATE TABLE announcement (
  id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  title VARCHAR(200) NOT NULL COMMENT '公告标题',
  content_html LONGTEXT NOT NULL COMMENT '公告内容（HTML，富文本）',
  content_text TEXT NULL COMMENT '公告纯文本（可选，用于搜索）',
  target_scope TINYINT NOT NULL DEFAULT 0 COMMENT '推送范围：0全体 1社区 2楼栋',
  target_community_id BIGINT NULL COMMENT '推送社区ID（scope=1/2）',
  target_building_id BIGINT NULL COMMENT '推送楼栋ID（scope=2）',
  status TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0草稿 1已发布',
  is_top TINYINT NOT NULL DEFAULT 0 COMMENT '是否置顶：0否 1是',
  top_at DATETIME NULL COMMENT '置顶时间',
  publisher_user_id BIGINT NOT NULL COMMENT '发布人（社区管理员）用户ID',
  published_at DATETIME NULL COMMENT '发布时间',
  created_at DATETIME NOT NULL COMMENT '创建时间',
  updated_at DATETIME NOT NULL COMMENT '更新时间',
  is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0否 1是',
  KEY idx_status_published (status, published_at),
  KEY idx_scope (target_scope, target_community_id, target_building_id),
  KEY idx_top (is_top, top_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='社区公告表';

INSERT INTO announcement
  (title, content_html, content_text, target_scope, status, is_top, top_at, publisher_user_id, published_at, created_at, updated_at, is_deleted)
VALUES
  ('【示例】社区活动通知', '<p>本周六上午9点，社区开展环境清洁志愿活动，欢迎报名参与。</p>', '本周六上午9点，社区开展环境清洁志愿活动，欢迎报名参与。', 0, 1, 1, NOW(), 1, NOW(), NOW(), NOW(), 0),
  ('【示例】便民服务安排', '<p>本周三下午，社区卫生服务站提供义诊服务，请有需要的居民前往。</p>', '本周三下午，社区卫生服务站提供义诊服务，请有需要的居民前往。', 0, 1, 0, NULL, 1, NOW(), NOW(), NOW(), 0);

