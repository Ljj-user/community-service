-- 社区公益服务对接管理平台 - 临时/演示数据（MySQL 8.0）
-- 只包含 DML：INSERT / UPDATE 等，用于联调与演示

USE community_service;

-- ============================================
-- 0) 网格化区域（sys_region）演示数据：1个区 + 1个街道 + 2个社区
-- 说明：用于 community_id 绑定与数据隔离联调
-- ============================================
INSERT INTO sys_region (id, name, level, parent_id) VALUES
(100, '示例区', 1, NULL),
(110, '示例街道', 2, 100),
(3001, '幸福社区', 3, 110),
(3002, '阳光社区', 3, 110)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  level = VALUES(level),
  parent_id = VALUES(parent_id);

-- ============================================
-- 1) 系统配置默认值
-- ============================================
INSERT INTO sys_config (config_key, config_value) VALUES
('basic', '{
  "pointsPerHour": 10,
  "demandClassifyHours": 2,
  "feedbackDays": 3,
  "requireVideoWitness": true,
  "requireSmsVerify": true,
  "requireDoubleSign": true,
  "enableVoiceInput": true,
  "enableLargeText": true,
  "enablePhoneBooking": true
}'),
('notice', '{
  "smsVerify": "【社区公益平台】您的验证码为：{code}，5分钟内有效，请勿泄露。",
  "demandApproved": "【社区公益平台】您发布的需求「{title}」已通过审核，已进入志愿者匹配阶段。",
  "demandRejected": "【社区公益平台】您发布的需求「{title}」未通过审核，原因：{reason}。",
  "volunteerApproved": "【社区公益平台】您的志愿者申请已通过审核，可开始浏览并认领服务需求。",
  "volunteerRejected": "【社区公益平台】您的志愿者申请未通过审核，如有疑问请联系社区管理员。",
  "demandMatched": "【社区公益平台】您的需求「{title}」已匹配志愿者，请留意服务进度。"
}'),
('alert', '{
  "demandUnclaimedHours": 24,
  "serviceUnfinishedHours": 48,
  "fulfillmentRateThreshold": 0.8,
  "complaintRateThreshold": 0.05,
  "noShowFreezeCount": 3,
  "enableUnclaimedAlert": true,
  "enableUnfinishedAlert": true,
  "enableFulfillmentAlert": true,
  "enableComplaintAlert": true
}')
ON DUPLICATE KEY UPDATE config_key = config_key;

-- ============================================
-- 2) 公告演示数据（用于首页公告弹窗/公告列表联调）
-- 仅插入 target_scope=0（全体）且 status=1（已发布）
-- ============================================
INSERT INTO announcement
  (title, content_html, content_text, target_scope, status, is_top, top_at, publisher_user_id, published_at, created_at, updated_at, is_deleted)
VALUES
  ('【示例】社区活动通知', '<p>本周六上午9点，社区开展环境清洁志愿活动，欢迎报名参与。</p>', '本周六上午9点，社区开展环境清洁志愿活动，欢迎报名参与。', 0, 1, 1, NOW(), 1, NOW(), NOW(), NOW(), 0),
  ('【示例】便民服务安排', '<p>本周三下午，社区卫生服务站提供义诊服务，请有需要的居民前往。</p>', '本周三下午，社区卫生服务站提供义诊服务，请有需要的居民前往。', 0, 1, 0, NULL, 1, NOW(), NOW(), NOW(), 0);

-- ============================================
-- 3) 审计日志演示数据（可选）
-- ============================================
INSERT INTO audit_log (user_id, username, role, module, action, request_path, http_method, success, result_msg, risk_level, ip, elapsed_ms, created_at) VALUES
(1, 'admin', 1, 'USER_MANAGE', '登录', '/auth/login', 'POST', 1, '登录成功', 'NORMAL', '127.0.0.1', 45, NOW() - INTERVAL 2 HOUR),
(1, 'admin', 1, 'SYSTEM_CONFIG', '保存基础参数', '/admin/config/basic', 'PUT', 1, '保存成功', 'NORMAL', '127.0.0.1', 120, NOW() - INTERVAL 1 HOUR),
(1, 'admin', 1, 'USER_MANAGE', '创建用户', '/admin/users', 'POST', 1, '创建成功', 'NORMAL', '127.0.0.1', 80, NOW() - INTERVAL 30 MINUTE),
(1, 'admin', 1, 'AUTH', '登录', '/auth/login', 'POST', 0, '密码错误', 'WARN', '192.168.1.100', 12, NOW() - INTERVAL 10 MINUTE),
(1, 'admin', 1, 'USER_MANAGE', '禁用用户', '/admin/users/2/status', 'POST', 1, '更新成功', 'NORMAL', '127.0.0.1', 56, NOW());

-- ============================================
-- 4) 业务联调演示数据（原 Temp_data.sql）
-- ============================================
-- 密码统一为 123456，MD5: e10adc3949ba59abbe56e057f20f883e

-- 超级管理员
-- 说明：community_id/time_coins/points 写入 INSERT，且 ON DUPLICATE KEY 同步更新，
-- 避免“行已存在时仅更新 updated_at”导致 F12 里 /auth/me 始终没有 communityId。
INSERT INTO sys_user (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, status, created_at, updated_at, is_deleted) VALUES
(1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', 1, 1, NULL, 0, 0, NULL, '系统管理员', '13800000001', 'admin@community.com', 1, '社区服务中心', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag);

-- 社区管理员
INSERT INTO sys_user (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, status, created_at, updated_at, is_deleted) VALUES
(2, 'manager', 'e10adc3949ba59abbe56e057f20f883e', 2, 1, 3001, 0, 0, NULL, '社区管理员', '13800000002', 'manager@community.com', 2, '社区服务中心', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag);

-- 社区管理员（第二社区）
INSERT INTO sys_user (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, status, created_at, updated_at, is_deleted) VALUES
(10, 'manager2', 'e10adc3949ba59abbe56e057f20f883e', 2, 1, 3002, 0, 0, NULL, '社区管理员（二）', '13800000003', 'manager2@community.com', 1, '阳光社区服务中心', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag);

-- 普通用户 - 居民（community_id 对应上方 sys_region：3001 幸福社区 / 3002 阳光社区）
INSERT INTO sys_user (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, status, created_at, updated_at, is_deleted) VALUES
(3, 'resident1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 5, 120, '普通居民', '张大爷', '13800000011', 'zhang@example.com', 1, '幸福小区1栋101', 1, NOW(3), NOW(3), 0),
(4, 'resident2', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 80, '孤寡老人', '李奶奶', '13800000012', 'li@example.com', 2, '幸福小区2栋202', 1, NOW(3), NOW(3), 0),
(5, 'resident3', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 1, 60, '残疾人', '王阿姨', '13800000013', 'wang@example.com', 2, '阳光社区3栋301', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag);

-- 普通用户 - 志愿者
INSERT INTO sys_user (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, skill_tags, status, created_at, updated_at, is_deleted) VALUES
(6, 'volunteer1', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 200, '活力老人', '志愿者小王', '13800000021', 'volunteer1@example.com', 1, '幸福小区5栋501', '["护理", "助浴", "陪伴"]', 1, NOW(3), NOW(3), 0),
(7, 'volunteer2', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3002, 0, 150, '普通居民', '志愿者小刘', '13800000022', 'volunteer2@example.com', 2, '阳光社区6栋602', '["清洁", "维修", "教育"]', 1, NOW(3), NOW(3), 0),
(8, 'volunteer3', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 90, '普通居民', '志愿者小陈', '13800000023', 'volunteer3@example.com', 1, '和谐社区7栋703', '["助老", "陪伴", "购物"]', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag),
  skill_tags = VALUES(skill_tags);

-- 普通用户 - 志愿者（账号名沿用历史）
INSERT INTO sys_user (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, skill_tags, status, created_at, updated_at, is_deleted) VALUES
(9, 'both1', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 70, '普通居民', '赵先生', '13800000031', 'zhao@example.com', 1, '幸福小区8栋801', '["清洁", "维修"]', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag),
  skill_tags = VALUES(skill_tags);

-- ============================================
-- 1.1) 兼容旧库的手动补丁（若上面 INSERT 已全量执行，可跳过）
-- ============================================

-- 待审核的需求（status=0）
INSERT INTO service_request (requester_user_id, service_type, description, service_address, expected_time, urgency_level, special_tags, status, created_at, updated_at, is_deleted) VALUES
(3, '助老', '需要帮助购买生活用品，包括米、面、油等', '幸福小区1栋101', DATE_ADD(NOW(3), INTERVAL 2 DAY), 2, '["独居老人"]', 0, DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), 0),
(4, '清洁', '家里需要大扫除，特别是厨房和卫生间', '幸福小区2栋202', DATE_ADD(NOW(3), INTERVAL 3 DAY), 1, '["行动不便"]', 0, DATE_SUB(NOW(3), INTERVAL 2 HOUR), NOW(3), 0);

-- 已发布的需求（status=1）
INSERT INTO service_request (requester_user_id, service_type, description, service_address, expected_time, urgency_level, special_tags, status, audit_by_user_id, audit_at, published_at, created_at, updated_at, is_deleted) VALUES
(3, '助浴', '需要帮助独居老人洗澡，行动不便', '幸福小区1栋101', DATE_ADD(NOW(3), INTERVAL 1 DAY), 4, '["独居老人", "行动不便"]', 1, 2, DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(4, '教育', '需要志愿者辅导孩子作业，主要是数学和英语', '幸福小区2栋202', DATE_ADD(NOW(3), INTERVAL 5 DAY), 2, '["单亲家庭"]', 1, 2, DATE_SUB(NOW(3), INTERVAL 3 DAY), DATE_SUB(NOW(3), INTERVAL 3 DAY), DATE_SUB(NOW(3), INTERVAL 4 DAY), NOW(3), 0),
(5, '清洁', '需要定期清洁服务，每周一次', '阳光社区3栋301', DATE_ADD(NOW(3), INTERVAL 7 DAY), 1, NULL, 1, 10, DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 6 DAY), NOW(3), 0);

-- 已认领的需求（status=2）
INSERT INTO service_request (requester_user_id, service_type, description, service_address, expected_time, urgency_level, special_tags, status, audit_by_user_id, audit_at, published_at, claimed_at, created_at, updated_at, is_deleted) VALUES
(3, '陪伴', '需要志愿者陪伴聊天，缓解孤独感', '幸福小区1栋101', DATE_ADD(NOW(3), INTERVAL 1 DAY), 3, '["独居老人"]', 2, 2, DATE_SUB(NOW(3), INTERVAL 7 DAY), DATE_SUB(NOW(3), INTERVAL 7 DAY), DATE_SUB(NOW(3), INTERVAL 6 DAY), DATE_SUB(NOW(3), INTERVAL 8 DAY), NOW(3), 0),
(4, '购物', '需要帮助购买日常用品和药品', '幸福小区2栋202', DATE_ADD(NOW(3), INTERVAL 2 DAY), 2, '["行动不便"]', 2, 2, DATE_SUB(NOW(3), INTERVAL 6 DAY), DATE_SUB(NOW(3), INTERVAL 6 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), 0);

-- 已完成的需求（status=3）
INSERT INTO service_request (requester_user_id, service_type, description, service_address, expected_time, urgency_level, special_tags, status, audit_by_user_id, audit_at, published_at, claimed_at, completed_at, created_at, updated_at, is_deleted) VALUES
(3, '助老', '需要帮助整理房间，清理过期物品', '幸福小区1栋101', DATE_SUB(NOW(3), INTERVAL 3 DAY), 2, '["独居老人"]', 3, 2, DATE_SUB(NOW(3), INTERVAL 10 DAY), DATE_SUB(NOW(3), INTERVAL 10 DAY), DATE_SUB(NOW(3), INTERVAL 9 DAY), DATE_SUB(NOW(3), INTERVAL 3 DAY), DATE_SUB(NOW(3), INTERVAL 11 DAY), NOW(3), 0),
(4, '清洁', '需要深度清洁厨房和卫生间', '幸福小区2栋202', DATE_SUB(NOW(3), INTERVAL 5 DAY), 3, '["行动不便"]', 3, 2, DATE_SUB(NOW(3), INTERVAL 12 DAY), DATE_SUB(NOW(3), INTERVAL 12 DAY), DATE_SUB(NOW(3), INTERVAL 11 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 13 DAY), NOW(3), 0);

-- 已驳回的需求（status=4）
INSERT INTO service_request (requester_user_id, service_type, description, service_address, expected_time, urgency_level, special_tags, status, audit_by_user_id, audit_at, reject_reason, created_at, updated_at, is_deleted) VALUES
(5, '维修', '需要维修水管，但描述不够详细', '阳光社区3栋301', DATE_ADD(NOW(3), INTERVAL 1 DAY), 2, NULL, 4, 10, DATE_SUB(NOW(3), INTERVAL 1 DAY), '需求描述不够详细，请补充具体问题和联系方式', DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0);

-- 回填需求所属社区（按发布人所属社区写入）
UPDATE service_request sr
LEFT JOIN sys_user su ON su.id = sr.requester_user_id
SET sr.community_id = su.community_id
WHERE sr.community_id IS NULL;

-- 服务认领记录（service_claim）
INSERT INTO service_claim (request_id, volunteer_user_id, claim_at, claim_status, created_at, updated_at, is_deleted) VALUES
(6, 6, DATE_SUB(NOW(3), INTERVAL 6 DAY), 1, DATE_SUB(NOW(3), INTERVAL 6 DAY), NOW(3), 0),
(7, 7, DATE_SUB(NOW(3), INTERVAL 5 DAY), 1, DATE_SUB(NOW(3), INTERVAL 5 DAY), NOW(3), 0);

INSERT INTO service_claim (request_id, volunteer_user_id, claim_at, claim_status, service_hours, hours_submitted_at, completion_note, created_at, updated_at, is_deleted) VALUES
(8, 6, DATE_SUB(NOW(3), INTERVAL 9 DAY), 2, 3.5, DATE_SUB(NOW(3), INTERVAL 3 DAY), '已完成房间整理，清理了过期物品，房间整洁有序', DATE_SUB(NOW(3), INTERVAL 9 DAY), NOW(3), 0),
(9, 7, DATE_SUB(NOW(3), INTERVAL 11 DAY), 2, 4.0, DATE_SUB(NOW(3), INTERVAL 5 DAY), '已完成深度清洁，厨房和卫生间已彻底清洁', DATE_SUB(NOW(3), INTERVAL 11 DAY), NOW(3), 0);

-- 评价数据（service_evaluation）
INSERT INTO service_evaluation (claim_id, request_id, resident_user_id, volunteer_user_id, rating, content, created_at, updated_at, is_deleted) VALUES
(3, 8, 3, 6, 5, '志愿者小王非常认真负责，房间整理得很干净，非常感谢！', DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(4, 9, 4, 7, 5, '小刘志愿者服务态度很好，清洁工作做得非常细致，五星好评！', DATE_SUB(NOW(3), INTERVAL 4 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  rating = VALUES(rating),
  content = VALUES(content),
  updated_at = VALUES(updated_at),
  is_deleted = VALUES(is_deleted);

-- 说明：后续重复的“测试数据”块已移除，避免两份演示数据导致社区/ID 引用混乱。
--
-- 认领记录：
-- - 已认领(1): 2条
-- - 已完成(2): 2条（对应已完成的需求）
--
-- 评价记录：
-- - 2条评价，均为5星好评
