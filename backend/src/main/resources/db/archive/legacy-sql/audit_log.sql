-- 审计日志表
CREATE TABLE IF NOT EXISTS audit_log (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT DEFAULT NULL COMMENT '操作人ID',
  username VARCHAR(64) DEFAULT NULL COMMENT '操作人用户名',
  role TINYINT DEFAULT NULL COMMENT '角色 1超级管理员 2社区管理员 3普通用户',
  module VARCHAR(64) NOT NULL COMMENT '模块 USER_MANAGE/SYSTEM_CONFIG/REQUEST_AUDIT等',
  action VARCHAR(128) NOT NULL COMMENT '操作动作',
  request_path VARCHAR(256) DEFAULT NULL COMMENT '请求路径',
  http_method VARCHAR(16) DEFAULT NULL COMMENT 'GET/POST/PUT/DELETE',
  success TINYINT NOT NULL DEFAULT 1 COMMENT '0失败 1成功',
  result_msg VARCHAR(512) DEFAULT NULL COMMENT '结果摘要',
  risk_level VARCHAR(16) DEFAULT 'NORMAL' COMMENT 'NORMAL/WARN/HIGH',
  ip VARCHAR(64) DEFAULT NULL COMMENT '客户端IP',
  user_agent VARCHAR(512) DEFAULT NULL COMMENT 'User-Agent',
  elapsed_ms INT DEFAULT NULL COMMENT '耗时毫秒',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  INDEX idx_created_at (created_at),
  INDEX idx_username (username),
  INDEX idx_module (module),
  INDEX idx_success (success),
  INDEX idx_risk_level (risk_level),
  INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审计日志表';

-- 可选：插入几条示例数据便于联调
INSERT INTO audit_log (user_id, username, role, module, action, request_path, http_method, success, result_msg, risk_level, ip, elapsed_ms, created_at) VALUES
(1, 'admin', 1, 'USER_MANAGE', '登录', '/auth/login', 'POST', 1, '登录成功', 'NORMAL', '127.0.0.1', 45, NOW() - INTERVAL 2 HOUR),
(1, 'admin', 1, 'SYSTEM_CONFIG', '保存基础参数', '/admin/config/basic', 'PUT', 1, '保存成功', 'NORMAL', '127.0.0.1', 120, NOW() - INTERVAL 1 HOUR),
(1, 'admin', 1, 'USER_MANAGE', '创建用户', '/admin/users', 'POST', 1, '创建成功', 'NORMAL', '127.0.0.1', 80, NOW() - INTERVAL 30 MINUTE),
(1, 'admin', 1, 'AUTH', '登录', '/auth/login', 'POST', 0, '密码错误', 'WARN', '192.168.1.100', 12, NOW() - INTERVAL 10 MINUTE),
(1, 'admin', 1, 'USER_MANAGE', '禁用用户', '/admin/users/2/status', 'POST', 1, '更新成功', 'NORMAL', '127.0.0.1', 56, NOW());
