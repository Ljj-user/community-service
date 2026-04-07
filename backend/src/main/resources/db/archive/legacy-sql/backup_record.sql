-- 备份/恢复/导出记录表（用于“数据导出与备份”页面）
CREATE TABLE IF NOT EXISTS backup_record (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  record_type VARCHAR(16) NOT NULL COMMENT '类型 BACKUP/RESTORE/EXPORT',
  module VARCHAR(64) DEFAULT NULL COMMENT '导出模块 service_request/users/audit 等',
  format VARCHAR(16) DEFAULT NULL COMMENT '导出格式 excel/pdf/csv 等',
  filename VARCHAR(255) DEFAULT NULL COMMENT '文件名',
  file_path VARCHAR(512) DEFAULT NULL COMMENT '文件路径（服务器本地）',
  file_size_mb DECIMAL(10,2) DEFAULT NULL COMMENT '文件大小 MB',
  status VARCHAR(16) NOT NULL DEFAULT 'SUCCESS' COMMENT '状态 SUCCESS/FAILED/RUNNING',
  note VARCHAR(255) DEFAULT NULL COMMENT '备注',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  is_deleted TINYINT NOT NULL DEFAULT 0 COMMENT '逻辑删除：0否 1是',
  INDEX idx_type (record_type),
  INDEX idx_module (module),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='备份/恢复/导出记录表';

