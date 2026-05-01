-- One-shot DB initialization script for MySQL CLI
-- Usage example:
-- mysql -u root -p < backend/src/main/resources/db/init_all.sql

CREATE DATABASE IF NOT EXISTS community_service
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE community_service;

-- 1) 导入当前 PRD v2 表结构
SOURCE backend/src/main/resources/db/schema_v2_prd.sql;

-- 2) 导入当前模拟数据
SOURCE backend/src/main/resources/db/temp_data.sql;
