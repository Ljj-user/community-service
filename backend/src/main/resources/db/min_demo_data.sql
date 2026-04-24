-- 最小演示数据（可重复执行）
-- 覆盖：社区筛选、邀请码、智能匹配、异常检测、审核日志
-- 使用：
--   mysql -u root -p community_service < backend/src/main/resources/db/min_demo_data.sql

USE community_service;

SET NAMES utf8mb4;

-- 1) 基础社区（用于“社区下拉/社区筛选”）
INSERT INTO sys_region (id, name, level, parent_id, province, city) VALUES
(100, '西湖区', 1, NULL, '浙江省', '杭州市'),
(110, '文新街道', 2, 100, '浙江省', '杭州市'),
(3001, '翠苑社区', 3, 110, '浙江省', '杭州市'),
(3002, '文苑社区', 3, 110, '浙江省', '杭州市')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  level = VALUES(level),
  parent_id = VALUES(parent_id),
  province = VALUES(province),
  city = VALUES(city);

-- 2) 系统配置（异常规则关键开关）
INSERT INTO sys_config (config_key, config_value) VALUES
('alert', '{
  "demandUnclaimedHours": 24,
  "serviceUnfinishedHours": 48,
  "fulfillmentRateThreshold": 0.8,
  "complaintRateThreshold": 0.05,
  "noShowFreezeCount": 3,
  "enableUnclaimedAlert": true,
  "enableUnfinishedAlert": true,
  "enableFulfillmentAlert": true,
  "enableComplaintAlert": true,
  "careInactivityDays": 3,
  "surge24hMinRequests": 5,
  "surgeMultiplier": 2,
  "enableCareInactivityAlert": true,
  "enableDemandSurgeAlert": true
}')
ON DUPLICATE KEY UPDATE
  config_value = VALUES(config_value);

-- 3) 用户（密码均为 123456）
-- role: 1超管 2社区管理员 3普通用户；identity_type: 1居民 2志愿者
INSERT INTO sys_user (
  id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag,
  real_name, phone, email, gender, address, skill_tags, status, created_at, updated_at, is_deleted
) VALUES
(1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', 1, 1, NULL, 0, 0, NULL, '系统管理员', '13800000001', 'admin@demo.com', 1, '平台总部', NULL, 1, NOW(3), NOW(3), 0),
(2, 'manager', 'e10adc3949ba59abbe56e057f20f883e', 2, 1, 3001, 0, 0, NULL, '社区管理员', '13800000002', 'manager@demo.com', 1, '翠苑社区服务站', NULL, 1, NOW(3), NOW(3), 0),
(3, 'resident1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 20, 100, '普通居民', '张大爷', '13800000011', 'resident1@demo.com', 1, '翠苑社区1栋101', NULL, 1, NOW(3), NOW(3), 0),
(4, 'elder1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 10, 80, '孤寡老人', '李奶奶', '13800000012', 'elder1@demo.com', 2, '翠苑社区2栋202', NULL, 1, NOW(3), NOW(3), 0),
(6, 'volunteer1', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 200, '活力老人', '志愿者小王', '13800000021', 'vol1@demo.com', 1, '翠苑社区5栋501', '["护理","助浴","陪伴"]', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  role = VALUES(role),
  identity_type = VALUES(identity_type),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag),
  real_name = VALUES(real_name),
  phone = VALUES(phone),
  email = VALUES(email),
  address = VALUES(address),
  skill_tags = VALUES(skill_tags),
  status = VALUES(status),
  updated_at = VALUES(updated_at),
  is_deleted = 0;

-- 让重点人群变成“连续多日未登录”，便于异常规则触发
UPDATE sys_user
SET last_login_at = DATE_SUB(NOW(3), INTERVAL 7 DAY), updated_at = NOW(3)
WHERE id = 4;

-- 4) 邀请码（用于“社区邀请码”筛选与导出）
INSERT INTO community_invite_code
  (id, community_id, code, status, expires_at, max_uses, used_count, created_by, created_at, updated_at)
VALUES
  (9001, 3001, 'DEMO3001', 1, DATE_ADD(NOW(3), INTERVAL 30 DAY), 200, 3, 2, NOW(3), NOW(3)),
  (9002, 3002, 'DEMO3002', 1, DATE_ADD(NOW(3), INTERVAL 30 DAY), 200, 1, 1, NOW(3), NOW(3))
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  status = VALUES(status),
  expires_at = VALUES(expires_at),
  max_uses = VALUES(max_uses),
  used_count = VALUES(used_count),
  updated_at = VALUES(updated_at);

-- 5) 需求（用于智能匹配与监控/异常）
INSERT INTO service_request
  (id, requester_user_id, community_id, service_type, description, service_address, expected_time, urgency_level, special_tags,
   status, audit_by_user_id, audit_at, published_at, claimed_at, completed_at, created_at, updated_at, is_deleted)
VALUES
  -- 已发布，且超时未认领（监控风险1）
  (8001, 4, 3001, '助浴', '独居老人需要上门助浴服务', '翠苑社区2栋202', DATE_SUB(NOW(3), INTERVAL 4 HOUR), 4,
   '["独居老人","行动不便"]', 1, 2, DATE_SUB(NOW(3), INTERVAL 2 DAY), DATE_SUB(NOW(3), INTERVAL 2 DAY), NULL, NULL,
   DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
  -- 已认领，且超时未完成（监控风险2）
  (8002, 3, 3001, '陪伴', '需要陪诊与聊天陪伴', '翠苑社区1栋101', DATE_SUB(NOW(3), INTERVAL 3 HOUR), 3,
   '["独居老人"]', 2, 2, DATE_SUB(NOW(3), INTERVAL 3 DAY), DATE_SUB(NOW(3), INTERVAL 3 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
   DATE_SUB(NOW(3), INTERVAL 3 DAY), NOW(3), 0),
  -- 正常已发布（可用于智能匹配展示）
  (8003, 3, 3001, '护理', '需要上门基础护理服务', '翠苑社区1栋101', DATE_ADD(NOW(3), INTERVAL 1 DAY), 2,
   '["护理"]', 1, 2, DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL, NULL,
   DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  requester_user_id = VALUES(requester_user_id),
  community_id = VALUES(community_id),
  service_type = VALUES(service_type),
  description = VALUES(description),
  service_address = VALUES(service_address),
  expected_time = VALUES(expected_time),
  urgency_level = VALUES(urgency_level),
  special_tags = VALUES(special_tags),
  status = VALUES(status),
  audit_by_user_id = VALUES(audit_by_user_id),
  audit_at = VALUES(audit_at),
  published_at = VALUES(published_at),
  claimed_at = VALUES(claimed_at),
  completed_at = VALUES(completed_at),
  updated_at = VALUES(updated_at),
  is_deleted = 0;

-- 6) 认领记录（绑定 8002）
INSERT INTO service_claim
  (id, request_id, volunteer_user_id, claim_at, claim_status, service_hours, hours_submitted_at, completion_note, created_at, updated_at, is_deleted)
VALUES
  (8101, 8002, 6, DATE_SUB(NOW(3), INTERVAL 1 DAY), 1, NULL, NULL, NULL, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  request_id = VALUES(request_id),
  volunteer_user_id = VALUES(volunteer_user_id),
  claim_at = VALUES(claim_at),
  claim_status = VALUES(claim_status),
  updated_at = VALUES(updated_at),
  is_deleted = 0;

-- 7) 智能匹配结构化标签
INSERT INTO sys_user_skill (user_id, skill_tag, created_at) VALUES
  (6, '护理', NOW()),
  (6, '助浴', NOW()),
  (6, '陪伴', NOW())
ON DUPLICATE KEY UPDATE
  created_at = VALUES(created_at);

INSERT INTO service_request_tag (request_id, tag_name, created_at) VALUES
  (8001, '助浴', NOW()),
  (8001, '独居老人', NOW()),
  (8002, '陪伴', NOW()),
  (8003, '护理', NOW())
ON DUPLICATE KEY UPDATE
  created_at = VALUES(created_at);

INSERT INTO skill_tag_stat (skill_tag, user_count, updated_at) VALUES
  ('护理', 10, NOW()),
  ('助浴', 8, NOW()),
  ('陪伴', 15, NOW())
ON DUPLICATE KEY UPDATE
  user_count = VALUES(user_count),
  updated_at = VALUES(updated_at);

-- 8) 审核日志（系统管理-审核日志页面有真实数据可看）
INSERT INTO audit_log
  (user_id, username, role, module, action, request_path, http_method, success, result_msg, risk_level, ip, elapsed_ms, created_at)
VALUES
  (1, 'admin', 1, 'SYSTEM_CONFIG', 'PUT /admin/config/alert', '/admin/config/alert', 'PUT', 1, '预警规则保存成功', 'NORMAL', '127.0.0.1', 52, NOW()),
  (2, 'manager', 2, 'REQUEST_AUDIT', 'POST /service-request/audit', '/service-request/audit', 'POST', 1, '审核通过', 'WARN', '127.0.0.1', 88, NOW()),
  (1, 'admin', 1, 'DATA_EXPORT', 'GET /admin/export/service_request', '/admin/export/service_request', 'GET', 1, 'OK', 'WARN', '127.0.0.1', 120, NOW());

-- 9) 预置一条异常事件（即使调度未到点，也可立即演示）
INSERT INTO anomaly_alert_event
  (alert_code, community_id, request_id, target_user_id, severity, trigger_rule, suggestion_action, rule_snapshot, dedup_key, occurred_at, created_at)
VALUES
  ('CARE_INACTIVE', 3001, NULL, 4, 2, '连续3天未登录', '建议社区管理员电话关怀或上门核实', '{"days":3}', CONCAT('CARE_INACTIVE:4:', CURDATE()), NOW(), NOW());

