-- 互助社区能力预留：发帖求助 / 以物换物（仅建表，不接业务）
-- 设计原则：
-- 1) 社区维度隔离（community_id）
-- 2) 软删除（is_deleted）
-- 3) 状态机字段预留（status）
-- 4) 足够的索引支持列表/筛选/搜索

-- 发帖（求助/互助/闲置等统一为 post_type）
CREATE TABLE IF NOT EXISTS mutual_aid_post (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  community_id  BIGINT UNSIGNED NOT NULL COMMENT '所属社区ID',
  author_user_id BIGINT UNSIGNED NOT NULL COMMENT '发布人用户ID',
  post_type     TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1求助 2互助信息 3闲置/交换信息（预留）',
  title         VARCHAR(200) NOT NULL COMMENT '标题',
  content       TEXT NOT NULL COMMENT '正文',
  contact       VARCHAR(100) NULL COMMENT '联系方式（可选）',
  location      VARCHAR(200) NULL COMMENT '位置描述（可选）',
  status        TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0待审核 1已发布 2已关闭 3已删除(逻辑)',
  view_count    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '浏览量',
  like_count    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '点赞数',
  comment_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '评论数',
  is_deleted    TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0否 1是',
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  PRIMARY KEY (id),
  KEY idx_post_comm_status_time (community_id, status, created_at),
  KEY idx_post_author_time (author_user_id, created_at),
  FULLTEXT KEY ftx_post_title_content (title, content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='互助社区帖子（预留）';

CREATE TABLE IF NOT EXISTS mutual_aid_post_tag (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_id    BIGINT UNSIGNED NOT NULL,
  tag_name   VARCHAR(64) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  UNIQUE KEY uk_post_tag (post_id, tag_name),
  KEY idx_post_tag_tag (tag_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='帖子标签（预留）';

CREATE TABLE IF NOT EXISTS mutual_aid_post_comment (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_id     BIGINT UNSIGNED NOT NULL,
  user_id     BIGINT UNSIGNED NOT NULL,
  parent_id   BIGINT UNSIGNED NULL COMMENT '父评论ID（楼中楼）',
  content     VARCHAR(1000) NOT NULL,
  like_count  INT UNSIGNED NOT NULL DEFAULT 0,
  is_deleted  TINYINT UNSIGNED NOT NULL DEFAULT 0,
  created_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_post_comment_post_time (post_id, created_at),
  KEY idx_post_comment_user_time (user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='帖子评论（预留）';

-- 以物换物：物品挂牌（listing）+ 图片 + 交换提议（offer）
CREATE TABLE IF NOT EXISTS barter_listing (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
  community_id  BIGINT UNSIGNED NOT NULL COMMENT '所属社区ID',
  owner_user_id BIGINT UNSIGNED NOT NULL COMMENT '物品所有者用户ID',
  title         VARCHAR(200) NOT NULL COMMENT '标题',
  description   TEXT NOT NULL COMMENT '描述',
  category      VARCHAR(64) NULL COMMENT '分类（可选）',
  condition_level TINYINT UNSIGNED NULL COMMENT '成色/新旧程度（可选）',
  expected_item VARCHAR(200) NULL COMMENT '期望交换物（可选）',
  status        TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1上架 2已预定 3已成交 4已下架',
  view_count    INT UNSIGNED NOT NULL DEFAULT 0,
  is_deleted    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_barter_comm_status_time (community_id, status, created_at),
  KEY idx_barter_owner_time (owner_user_id, created_at),
  FULLTEXT KEY ftx_barter_title_desc (title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='以物换物挂牌（预留）';

CREATE TABLE IF NOT EXISTS barter_listing_image (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  listing_id BIGINT UNSIGNED NOT NULL,
  image_url  VARCHAR(500) NOT NULL,
  sort_no    INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_barter_img_listing (listing_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='挂牌图片（预留）';

CREATE TABLE IF NOT EXISTS barter_offer (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  listing_id   BIGINT UNSIGNED NOT NULL COMMENT '挂牌ID',
  proposer_user_id BIGINT UNSIGNED NOT NULL COMMENT '提出交换的用户ID',
  offer_text   VARCHAR(500) NOT NULL COMMENT '交换提议说明',
  status       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0待处理 1同意 2拒绝 3撤回',
  created_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_barter_offer_listing_time (listing_id, created_at),
  KEY idx_barter_offer_user_time (proposer_user_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='以物换物交换提议（预留）';

