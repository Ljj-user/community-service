-- One-shot DB initialization script for MySQL CLI
-- Usage example:
-- mysql -u root -p < backend/src/main/resources/db/init_all.sql

CREATE DATABASE IF NOT EXISTS community_service
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE community_service;

-- 1) 表结构（PRD v2）
SOURCE backend/src/main/resources/db/schema_v2_prd.sql;

-- 2) 演示数据后续使用 min_demo_data_v2.sql 初始化。
