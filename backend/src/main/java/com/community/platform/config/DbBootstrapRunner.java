package com.community.platform.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * 运行期兜底：当本机数据库未执行 init_all.sql 时，确保关键表存在，避免启动即报错。
 *
 * 注意：这里只做 CREATE TABLE IF NOT EXISTS（幂等），不做破坏性变更。
 */
@Component
public class DbBootstrapRunner implements ApplicationRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        ensureSysNotification();
        ensureVerificationAndOnboarding();
        ensureMatchingTags();
        ensureMutualAidPostAndBarter();
        ensureCommunityInviteCode();
        ensureCommunityBanner();
    }

    private void ensureSysNotification() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS sys_notification (
                  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
                  recipient_user_id BIGINT UNSIGNED NOT NULL COMMENT '接收人用户ID',
                  title             VARCHAR(200)     NOT NULL COMMENT '标题',
                  summary           VARCHAR(500)     NULL COMMENT '摘要',
                  msg_category      TINYINT UNSIGNED NOT NULL COMMENT '1业务待办 2系统公告',
                  read_status       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0未读 1已读',
                  ref_type          VARCHAR(32)      NULL COMMENT '关联业务类型',
                  ref_id            BIGINT UNSIGNED  NULL COMMENT '关联业务主键',
                  created_at        DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                  PRIMARY KEY (id),
                  KEY idx_notif_user_read (recipient_user_id, read_status),
                  KEY idx_notif_user_cat_time (recipient_user_id, msg_category, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='站内消息通知';
                """);
    }

    private void ensureVerificationAndOnboarding() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS verify_code_ticket (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  scene VARCHAR(32) NOT NULL,
                  target VARCHAR(128) NOT NULL,
                  verify_code VARCHAR(16) NOT NULL,
                  expires_at DATETIME NOT NULL,
                  is_used TINYINT NOT NULL DEFAULT 0,
                  used_at DATETIME NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  INDEX idx_verify_target_scene (target, scene),
                  INDEX idx_verify_expire (expires_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='验证码票据表';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS user_onboarding_profile (
                  user_id BIGINT PRIMARY KEY,
                  skill_tags_json JSON NULL,
                  preferred_features_json JSON NULL,
                  intent_note VARCHAR(500) NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户引导问卷主表';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS user_onboarding_answer (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  question_key VARCHAR(64) NOT NULL,
                  answer_value VARCHAR(255) NOT NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_onboarding_answer_user (user_id),
                  INDEX idx_onboarding_answer_key (question_key)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户引导问卷答案表';
                """);
    }

    private void ensureMatchingTags() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS sys_user_skill (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  skill_tag VARCHAR(64) NOT NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_user_skill (user_id, skill_tag),
                  INDEX idx_user_skill_user (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户技能表';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS service_request_tag (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  request_id BIGINT NOT NULL,
                  tag_name VARCHAR(64) NOT NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_request_tag (request_id, tag_name),
                  INDEX idx_request_tag_req (request_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='需求标签表';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS skill_tag_stat (
                  skill_tag VARCHAR(64) PRIMARY KEY,
                  user_count INT NOT NULL DEFAULT 0,
                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='技能热度统计（用于新用户推荐冷启动）';
                """);
    }

    private void ensureMutualAidPostAndBarter() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS mutual_aid_post (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
                  community_id BIGINT UNSIGNED NOT NULL COMMENT '所属社区ID',
                  author_user_id BIGINT UNSIGNED NOT NULL COMMENT '发布人用户ID',
                  post_type TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1求助 2互助信息 3闲置/交换信息（预留）',
                  title VARCHAR(200) NOT NULL COMMENT '标题',
                  content TEXT NOT NULL COMMENT '正文',
                  contact VARCHAR(100) NULL COMMENT '联系方式（可选）',
                  location VARCHAR(200) NULL COMMENT '位置描述（可选）',
                  status TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0待审核 1已发布 2已关闭 3已删除(逻辑)',
                  view_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '浏览量',
                  like_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '点赞数',
                  comment_count INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '评论数',
                  is_deleted TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0否 1是',
                  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
                  PRIMARY KEY (id),
                  KEY idx_post_comm_status_time (community_id, status, created_at),
                  KEY idx_post_author_time (author_user_id, created_at),
                  FULLTEXT KEY ftx_post_title_content (title, content)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='互助社区帖子（预留）';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS mutual_aid_post_tag (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  post_id BIGINT UNSIGNED NOT NULL,
                  tag_name VARCHAR(64) NOT NULL,
                  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  UNIQUE KEY uk_post_tag (post_id, tag_name),
                  KEY idx_post_tag_tag (tag_name)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='帖子标签（预留）';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS mutual_aid_post_comment (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  post_id BIGINT UNSIGNED NOT NULL,
                  user_id BIGINT UNSIGNED NOT NULL,
                  parent_id BIGINT UNSIGNED NULL COMMENT '父评论ID（楼中楼）',
                  content VARCHAR(1000) NOT NULL,
                  like_count INT UNSIGNED NOT NULL DEFAULT 0,
                  is_deleted TINYINT UNSIGNED NOT NULL DEFAULT 0,
                  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  KEY idx_post_comment_post_time (post_id, created_at),
                  KEY idx_post_comment_user_time (user_id, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='帖子评论（预留）';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS barter_listing (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
                  community_id BIGINT UNSIGNED NOT NULL COMMENT '所属社区ID',
                  owner_user_id BIGINT UNSIGNED NOT NULL COMMENT '物品所有者用户ID',
                  title VARCHAR(200) NOT NULL COMMENT '标题',
                  description TEXT NOT NULL COMMENT '描述',
                  category VARCHAR(64) NULL COMMENT '分类（可选）',
                  condition_level TINYINT UNSIGNED NULL COMMENT '成色/新旧程度（可选）',
                  expected_item VARCHAR(200) NULL COMMENT '期望交换物（可选）',
                  status TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1上架 2已预定 3已成交 4已下架',
                  view_count INT UNSIGNED NOT NULL DEFAULT 0,
                  is_deleted TINYINT UNSIGNED NOT NULL DEFAULT 0,
                  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  KEY idx_barter_comm_status_time (community_id, status, created_at),
                  KEY idx_barter_owner_time (owner_user_id, created_at),
                  FULLTEXT KEY ftx_barter_title_desc (title, description)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='以物换物挂牌（预留）';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS barter_listing_image (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  listing_id BIGINT UNSIGNED NOT NULL,
                  image_url VARCHAR(500) NOT NULL,
                  sort_no INT UNSIGNED NOT NULL DEFAULT 0,
                  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  KEY idx_barter_img_listing (listing_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='挂牌图片（预留）';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS barter_offer (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  listing_id BIGINT UNSIGNED NOT NULL COMMENT '挂牌ID',
                  proposer_user_id BIGINT UNSIGNED NOT NULL COMMENT '提出交换的用户ID',
                  offer_text VARCHAR(500) NOT NULL COMMENT '交换提议说明',
                  status TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0待处理 1同意 2拒绝 3撤回',
                  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  KEY idx_barter_offer_listing_time (listing_id, created_at),
                  KEY idx_barter_offer_user_time (proposer_user_id, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='以物换物交换提议（预留）';
                """);
    }

    private void ensureCommunityInviteCode() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS community_invite_code (
                  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
                  community_id  BIGINT UNSIGNED NOT NULL COMMENT '社区ID（sys_region.id，通常 level=3）',
                  code          VARCHAR(32)      NOT NULL COMMENT '邀请码（短码）',
                  status        TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0禁用 1启用',
                  expires_at    DATETIME(3)      NULL COMMENT '过期时间（NULL=不过期）',
                  max_uses      INT UNSIGNED     NOT NULL DEFAULT 100 COMMENT '最大可用次数',
                  used_count    INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '已使用次数',
                  created_by    BIGINT UNSIGNED  NULL COMMENT '创建人用户ID',
                  created_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                  updated_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
                  PRIMARY KEY (id),
                  UNIQUE KEY uk_invite_code (code),
                  KEY idx_invite_comm_status (community_id, status),
                  KEY idx_invite_expire (expires_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区邀请码';
                """);
    }

    private void ensureCommunityBanner() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS community_banner (
                  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键',
                  community_id BIGINT UNSIGNED NULL COMMENT '社区ID（NULL=全局默认）',
                  title        VARCHAR(100)    NOT NULL COMMENT '主标题',
                  subtitle     VARCHAR(200)    NULL COMMENT '副标题',
                  image_url    VARCHAR(500)    NULL COMMENT '图片URL（可空：纯文案卡片）',
                  link_url     VARCHAR(500)    NULL COMMENT '点击跳转链接（可空）',
                  sort_no      INT             NOT NULL DEFAULT 0 COMMENT '排序（小在前）',
                  status       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0禁用 1启用',
                  created_by   BIGINT UNSIGNED NULL COMMENT '创建人用户ID',
                  created_at   DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  updated_at   DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  KEY idx_banner_comm_status_sort (community_id, status, sort_no),
                  KEY idx_banner_comm_time (community_id, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='社区轮播图';
                """);
    }
}

