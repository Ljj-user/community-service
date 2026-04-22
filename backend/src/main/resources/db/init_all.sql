-- One-shot DB initialization script for MySQL CLI
-- Usage example:
-- mysql -u root -p < backend/src/main/resources/db/init_all.sql

CREATE DATABASE IF NOT EXISTS community_service
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE community_service;

-- 1) 表结构
SOURCE backend/src/main/resources/db/schema.sql;

-- 2) 迁移/特殊脚本（依赖表已创建）
-- service_request 增加紧急联系人字段（若已在表结构中合并，可注释本行）
SOURCE backend/src/main/resources/db/service_request_emergency.sql;

-- 网格化管理 + 时间银行结构扩展
SOURCE backend/src/main/resources/db/migration_grid_timebank.sql;

-- 3) 临时/演示数据
SOURCE backend/src/main/resources/db/temp_data.sql;

-- 4) 可选：历史数据修复脚本（按需执行）
-- SOURCE backend/src/main/resources/db/migration_identity_no_dual.sql;

-- 5) 站内通知扩展（用于顶部“消息通知”）
SOURCE backend/src/main/resources/db/migration_sys_notification.sql;

-- 6) 管理员分权增强（社区范围索引）
SOURCE backend/src/main/resources/db/migration_admin_scope.sql;

-- 7) 匹配解释快照（可选预留）
SOURCE backend/src/main/resources/db/migration_matching_explain.sql;

-- 7.1) 智能匹配结构化标签表
SOURCE backend/src/main/resources/db/migration_matching_skill_tag.sql;

-- 8) 注册验证码 + 引导问卷
SOURCE backend/src/main/resources/db/migration_register_verification_onboarding.sql;

-- 9) 互助社区预留：发帖求助 / 以物换物（仅建表）
SOURCE backend/src/main/resources/db/migration_mutual_aid_post_trade.sql;

-- 10) 社区邀请码（移动端加入/改绑社区）
SOURCE backend/src/main/resources/db/migration_community_invite_code.sql;

-- 11) 社区轮播图（移动端首页 Banner）
SOURCE backend/src/main/resources/db/migration_community_banner.sql;

