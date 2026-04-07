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

