-- 社区公益服务对接管理平台（MySQL 8.0）
-- 核心表：用户（含角色）、需求、服务认领记录、评价
-- 说明：采用逻辑删除（is_deleted），时间字段使用 DATETIME(3)

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS service_evaluation;
DROP TABLE IF EXISTS service_claim;
DROP TABLE IF EXISTS service_request;
DROP TABLE IF EXISTS sys_user;

-- ----------------------------
-- 用户表（含角色/身份）
-- 角色：1超级管理员 2社区管理员 3普通用户
-- 普通用户身份：1居民老人 2志愿者（仅 role=3，互斥）
-- ----------------------------
CREATE TABLE sys_user (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  username          VARCHAR(50)      NOT NULL COMMENT '用户名（登录名）',
  password_md5      VARCHAR(100)     NOT NULL COMMENT '密码哈希（字段名沿用；兼容历史MD5与当前BCrypt）',
  role              TINYINT UNSIGNED NOT NULL COMMENT '角色：1超级管理员 2社区管理员 3普通用户',
  identity_type     TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '普通用户身份：1居民老人 2志愿者（仅role=3，互斥）',
  real_name         VARCHAR(50)      NULL COMMENT '真实姓名',
  phone             VARCHAR(20)      NULL COMMENT '手机号',
  email             VARCHAR(100)     NULL COMMENT '邮箱',
  avatar_url        VARCHAR(255)     NULL COMMENT '头像URL',
  gender            TINYINT UNSIGNED NULL COMMENT '性别：0未知 1男 2女',
  address           VARCHAR(255)     NULL COMMENT '常住地址/社区地址（用于匹配/服务记录）',
  skill_tags        JSON             NULL COMMENT '志愿者能力/标签（用于智能匹配；如护理、助浴等）',
  status            TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态：0禁用 1启用',
  last_login_at     DATETIME(3)      NULL COMMENT '最近登录时间',
  created_at        DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at        DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  is_deleted        TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '逻辑删除：0否 1是',
  PRIMARY KEY (id),
  UNIQUE KEY uk_sys_user_username (username),
  KEY idx_sys_user_role (role),
  KEY idx_sys_user_identity (identity_type),
  KEY idx_sys_user_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表（含角色/身份）';

-- ----------------------------
-- 需求表（居民发布 -> 社区管理员审核 -> 发布/驳回 -> 认领 -> 完成）
-- 状态：0待审核 1已发布 2已认领 3已完成 4已驳回
-- 紧急程度：1低 2中 3高 4紧急
-- ----------------------------
CREATE TABLE service_request (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  requester_user_id   BIGINT UNSIGNED NOT NULL COMMENT '需求发起人（居民）用户ID',
  service_type        VARCHAR(50)      NOT NULL COMMENT '服务类型（如助老、清洁、教育等）',
  description         TEXT             NULL COMMENT '需求描述/补充说明',
  service_address     VARCHAR(255)     NOT NULL COMMENT '服务地址',
  expected_time       DATETIME(3)      NULL COMMENT '期望服务时间',
  urgency_level       TINYINT UNSIGNED NOT NULL DEFAULT 2 COMMENT '紧急程度：1低 2中 3高 4紧急',
  special_tags        JSON             NULL COMMENT '特殊人群/需求标签（JSON数组，如独居老人、残障等）',
  status              TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态：0待审核 1已发布 2已认领 3已完成 4已驳回',

  -- 审核信息（社区管理员）
  audit_by_user_id    BIGINT UNSIGNED NULL COMMENT '审核人（社区管理员）用户ID',
  audit_at            DATETIME(3)     NULL COMMENT '审核时间',
  reject_reason       VARCHAR(255)    NULL COMMENT '驳回原因（status=4时必填）',

  -- 流转时间（便于统计/异常监管）
  published_at        DATETIME(3)     NULL COMMENT '发布公开时间（status=1）',
  claimed_at          DATETIME(3)     NULL COMMENT '被认领时间（status=2）',
  completed_at        DATETIME(3)     NULL COMMENT '完成时间（status=3）',

  created_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  is_deleted          TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '逻辑删除：0否 1是',
  PRIMARY KEY (id),
  KEY idx_req_requester (requester_user_id),
  KEY idx_req_status (status),
  KEY idx_req_type (service_type),
  KEY idx_req_created (created_at),
  CONSTRAINT fk_req_requester FOREIGN KEY (requester_user_id) REFERENCES sys_user(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_req_auditor FOREIGN KEY (audit_by_user_id) REFERENCES sys_user(id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='公益服务需求表';

-- ----------------------------
-- 服务认领记录表（志愿者认领 -> 完成后提交时长）
-- claim_status：1已认领 2已完成 3已取消（取消/异常用于管理员干预或重新认领的业务扩展）
-- ----------------------------
CREATE TABLE service_claim (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  request_id         BIGINT UNSIGNED NOT NULL COMMENT '需求ID',
  volunteer_user_id  BIGINT UNSIGNED NOT NULL COMMENT '志愿者用户ID',
  claim_at          DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '认领时间',
  claim_status      TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态：1已认领 2已完成 3已取消',

  service_hours     DECIMAL(6,2)    NULL COMMENT '服务时长（小时，完成后提交）',
  hours_submitted_at DATETIME(3)    NULL COMMENT '时长提交时间',
  completion_note   VARCHAR(255)    NULL COMMENT '完成说明/备注（可用于异常记录）',

  created_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at        DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  is_deleted        TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '逻辑删除：0否 1是',
  PRIMARY KEY (id),
  KEY idx_claim_request (request_id),
  KEY idx_claim_volunteer (volunteer_user_id),
  KEY idx_claim_status (claim_status),
  CONSTRAINT fk_claim_request FOREIGN KEY (request_id) REFERENCES service_request(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_claim_volunteer FOREIGN KEY (volunteer_user_id) REFERENCES sys_user(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='服务认领记录表';

-- ----------------------------
-- 评价表（居民在服务完成后评价）
-- 一个认领记录只能评价一次（uk_eval_claim）
-- rating：1-5 星
-- ----------------------------
CREATE TABLE service_evaluation (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  claim_id         BIGINT UNSIGNED NOT NULL COMMENT '认领记录ID',
  request_id       BIGINT UNSIGNED NOT NULL COMMENT '需求ID（冗余，便于查询）',
  resident_user_id BIGINT UNSIGNED NOT NULL COMMENT '评价人（居民）用户ID',
  volunteer_user_id BIGINT UNSIGNED NOT NULL COMMENT '被评价人（志愿者）用户ID',
  rating           TINYINT UNSIGNED NOT NULL COMMENT '星级：1-5',
  content          VARCHAR(500)     NULL COMMENT '评价内容',
  created_at       DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
  updated_at       DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
  is_deleted       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '逻辑删除：0否 1是',
  PRIMARY KEY (id),
  UNIQUE KEY uk_eval_claim (claim_id),
  KEY idx_eval_request (request_id),
  KEY idx_eval_volunteer (volunteer_user_id),
  KEY idx_eval_rating (rating),
  CONSTRAINT fk_eval_claim FOREIGN KEY (claim_id) REFERENCES service_claim(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eval_request FOREIGN KEY (request_id) REFERENCES service_request(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eval_resident FOREIGN KEY (resident_user_id) REFERENCES sys_user(id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_eval_volunteer FOREIGN KEY (volunteer_user_id) REFERENCES sys_user(id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='服务评价表';

SET FOREIGN_KEY_CHECKS = 1;
