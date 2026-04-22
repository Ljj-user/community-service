-- 社区公益服务对接管理平台 - 临时/演示数据（MySQL 8.0）
-- 只包含 DML：INSERT / UPDATE 等，用于联调与演示

USE community_service;

-- ============================================
-- 0) 网格化区域（sys_region）演示数据：真实地名示例（方案A）
-- 说明：
-- - 采用真实省市区名称增强答辩可信度
-- - 结构仍使用：1区(县/区) -> 2街道 -> 3社区
-- - 保持原 id（100/110/3001/3002）不变，避免破坏其他演示数据里的 community_id 引用
-- ============================================
INSERT INTO sys_region (id, name, level, parent_id, province, city) VALUES
(100, '西湖区', 1, NULL, '浙江省', '杭州市'),
(110, '文新街道', 2, 100, '浙江省', '杭州市'),
(3001, '翠苑社区', 3, 110, '浙江省', '杭州市'),
(3002, '文苑社区', 3, 110, '浙江省', '杭州市'),
-- 扩展示例：同区另一街道/社区（可选，用于展示多社区）
(120, '古荡街道', 2, 100, '浙江省', '杭州市'),
(3003, '古荡社区', 3, 120, '浙江省', '杭州市')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  level = VALUES(level),
  parent_id = VALUES(parent_id),
  province = VALUES(province),
  city = VALUES(city);

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

-- ============================================
-- 4.1) 移动端首页轮播图（community_banner）演示数据
-- 说明：优先匹配社区 banner；若为空则回落到 community_id=NULL 的全局默认
-- ============================================
INSERT INTO community_banner (id, community_id, title, subtitle, image_url, link_url, sort_no, status, created_by, created_at, updated_at) VALUES
(1, NULL, '春季互助行动', '邻里协作让生活更轻松', NULL, NULL, 1, 1, 1, NOW(3), NOW(3)),
(2, NULL, '积分激励周', '完成服务可获额外时币奖励', NULL, NULL, 2, 1, 1, NOW(3), NOW(3)),
(3, NULL, '社区关怀日', '优先帮助独居老人和行动不便居民', NULL, NULL, 3, 1, 1, NOW(3), NOW(3)),
(11, 3001, '翠苑社区 · 便民服务', '本周三下午义诊，欢迎前往', NULL, NULL, 1, 1, 2, NOW(3), NOW(3)),
(12, 3002, '文苑社区 · 志愿招募', '周末环境清洁活动开放报名', NULL, NULL, 1, 1, 10, NOW(3), NOW(3))
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  title = VALUES(title),
  subtitle = VALUES(subtitle),
  image_url = VALUES(image_url),
  link_url = VALUES(link_url),
  sort_no = VALUES(sort_no),
  status = VALUES(status),
  updated_at = VALUES(updated_at);

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

-- ============================================================
-- 5) 追加：50 用户 + 3 社区的“逻辑闭环”演示数据（可重复执行）
-- 目标：
-- - 3 个社区：3001/3002/3003（sys_region 已在本文件开头插入）
-- - 总用户数达到 50（在现有 10 个用户基础上，新增 40 个：1 个第三社区管理员 + 39 个普通用户）
-- - 覆盖闭环：加入社区(community_id) -> 发布需求 -> 审核/发布 -> 认领 -> 完成 -> 评价
-- - 时间银行闭环：service_order + time_transaction，并回填志愿者 time_coins/points
-- - 移动端：community_invite_code / community_banner 覆盖 3 社区
-- 约束：
-- - 避免与现有演示数据的自增 ID 冲突，新增业务表显式使用大 ID 段（10000+）
-- ============================================================

-- 5.1) 第三社区管理员（3003：古荡社区）
INSERT INTO sys_user (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, status, created_at, updated_at, is_deleted) VALUES
(11, 'manager3', 'e10adc3949ba59abbe56e057f20f883e', 2, 1, 3003, 0, 0, NULL, '社区管理员（三）', '13800000004', 'manager3@community.com', 1, '古荡社区服务中心', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag);

-- 5.2) 新增 39 个普通用户（24 居民 + 15 志愿者），分布到 3 个社区
-- 用户名规则：r_社区_序号 / v_社区_序号
INSERT INTO sys_user
  (id, username, password_md5, role, identity_type, community_id, time_coins, points, identity_tag, real_name, phone, email, gender, address, skill_tags, status, created_at, updated_at, is_deleted)
VALUES
-- 3001：居民 8
(1001, 'r_3001_01', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 10, '普通居民', '居民-翠苑-01', '13800001001', 'r3001_01@example.com', 2, '翠苑社区A区1号楼101', NULL, 1, NOW(3), NOW(3), 0),
(1002, 'r_3001_02', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 15, '独居老人', '居民-翠苑-02', '13800001002', 'r3001_02@example.com', 1, '翠苑社区A区2号楼202', NULL, 1, NOW(3), NOW(3), 0),
(1003, 'r_3001_03', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 12, '普通居民', '居民-翠苑-03', '13800001003', 'r3001_03@example.com', 1, '翠苑社区B区3号楼303', NULL, 1, NOW(3), NOW(3), 0),
(1004, 'r_3001_04', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 18, '残疾人', '居民-翠苑-04', '13800001004', 'r3001_04@example.com', 2, '翠苑社区B区4号楼404', NULL, 1, NOW(3), NOW(3), 0),
(1005, 'r_3001_05', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 9, '普通居民', '居民-翠苑-05', '13800001005', 'r3001_05@example.com', 1, '翠苑社区C区5号楼505', NULL, 1, NOW(3), NOW(3), 0),
(1006, 'r_3001_06', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 11, '普通居民', '居民-翠苑-06', '13800001006', 'r3001_06@example.com', 2, '翠苑社区C区6号楼606', NULL, 1, NOW(3), NOW(3), 0),
(1007, 'r_3001_07', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 20, '孤寡老人', '居民-翠苑-07', '13800001007', 'r3001_07@example.com', 2, '翠苑社区D区7号楼707', NULL, 1, NOW(3), NOW(3), 0),
(1008, 'r_3001_08', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 0, 14, '普通居民', '居民-翠苑-08', '13800001008', 'r3001_08@example.com', 1, '翠苑社区D区8号楼808', NULL, 1, NOW(3), NOW(3), 0),
-- 3002：居民 8
(1011, 'r_3002_01', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 13, '普通居民', '居民-文苑-01', '13800002001', 'r3002_01@example.com', 1, '文苑社区A区1号楼101', NULL, 1, NOW(3), NOW(3), 0),
(1012, 'r_3002_02', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 7, '独居老人', '居民-文苑-02', '13800002002', 'r3002_02@example.com', 2, '文苑社区A区2号楼202', NULL, 1, NOW(3), NOW(3), 0),
(1013, 'r_3002_03', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 16, '普通居民', '居民-文苑-03', '13800002003', 'r3002_03@example.com', 2, '文苑社区B区3号楼303', NULL, 1, NOW(3), NOW(3), 0),
(1014, 'r_3002_04', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 19, '普通居民', '居民-文苑-04', '13800002004', 'r3002_04@example.com', 1, '文苑社区B区4号楼404', NULL, 1, NOW(3), NOW(3), 0),
(1015, 'r_3002_05', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 8, '残疾人', '居民-文苑-05', '13800002005', 'r3002_05@example.com', 2, '文苑社区C区5号楼505', NULL, 1, NOW(3), NOW(3), 0),
(1016, 'r_3002_06', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 12, '普通居民', '居民-文苑-06', '13800002006', 'r3002_06@example.com', 1, '文苑社区C区6号楼606', NULL, 1, NOW(3), NOW(3), 0),
(1017, 'r_3002_07', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 21, '孤寡老人', '居民-文苑-07', '13800002007', 'r3002_07@example.com', 2, '文苑社区D区7号楼707', NULL, 1, NOW(3), NOW(3), 0),
(1018, 'r_3002_08', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3002, 0, 17, '普通居民', '居民-文苑-08', '13800002008', 'r3002_08@example.com', 1, '文苑社区D区8号楼808', NULL, 1, NOW(3), NOW(3), 0),
-- 3003：居民 8
(1021, 'r_3003_01', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 10, '普通居民', '居民-古荡-01', '13800003001', 'r3003_01@example.com', 1, '古荡社区A区1号楼101', NULL, 1, NOW(3), NOW(3), 0),
(1022, 'r_3003_02', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 9, '独居老人', '居民-古荡-02', '13800003002', 'r3003_02@example.com', 2, '古荡社区A区2号楼202', NULL, 1, NOW(3), NOW(3), 0),
(1023, 'r_3003_03', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 13, '普通居民', '居民-古荡-03', '13800003003', 'r3003_03@example.com', 1, '古荡社区B区3号楼303', NULL, 1, NOW(3), NOW(3), 0),
(1024, 'r_3003_04', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 15, '残疾人', '居民-古荡-04', '13800003004', 'r3003_04@example.com', 2, '古荡社区B区4号楼404', NULL, 1, NOW(3), NOW(3), 0),
(1025, 'r_3003_05', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 11, '普通居民', '居民-古荡-05', '13800003005', 'r3003_05@example.com', 1, '古荡社区C区5号楼505', NULL, 1, NOW(3), NOW(3), 0),
(1026, 'r_3003_06', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 12, '普通居民', '居民-古荡-06', '13800003006', 'r3003_06@example.com', 2, '古荡社区C区6号楼606', NULL, 1, NOW(3), NOW(3), 0),
(1027, 'r_3003_07', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 16, '孤寡老人', '居民-古荡-07', '13800003007', 'r3003_07@example.com', 2, '古荡社区D区7号楼707', NULL, 1, NOW(3), NOW(3), 0),
(1028, 'r_3003_08', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 0, 18, '普通居民', '居民-古荡-08', '13800003008', 'r3003_08@example.com', 1, '古荡社区D区8号楼808', NULL, 1, NOW(3), NOW(3), 0),
-- 3001：志愿者 5
(1031, 'v_3001_01', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 50, '普通居民', '志愿者-翠苑-01', '13800011001', 'v3001_01@example.com', 1, '翠苑社区志愿者之家1', '["助老","陪伴","购物"]', 1, NOW(3), NOW(3), 0),
(1032, 'v_3001_02', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 55, '普通居民', '志愿者-翠苑-02', '13800011002', 'v3001_02@example.com', 2, '翠苑社区志愿者之家2', '["清洁","维修"]', 1, NOW(3), NOW(3), 0),
(1033, 'v_3001_03', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 60, '活力老人', '志愿者-翠苑-03', '13800011003', 'v3001_03@example.com', 1, '翠苑社区志愿者之家3', '["助浴","护理"]', 1, NOW(3), NOW(3), 0),
(1034, 'v_3001_04', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 48, '普通居民', '志愿者-翠苑-04', '13800011004', 'v3001_04@example.com', 2, '翠苑社区志愿者之家4', '["教育","陪诊"]', 1, NOW(3), NOW(3), 0),
(1035, 'v_3001_05', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 0, 52, '普通居民', '志愿者-翠苑-05', '13800011005', 'v3001_05@example.com', 1, '翠苑社区志愿者之家5', '["清洁","助老","陪伴"]', 1, NOW(3), NOW(3), 0),
-- 3002：志愿者 5
(1036, 'v_3002_01', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3002, 0, 50, '普通居民', '志愿者-文苑-01', '13800012001', 'v3002_01@example.com', 2, '文苑社区志愿者之家1', '["清洁","维修","跑腿"]', 1, NOW(3), NOW(3), 0),
(1037, 'v_3002_02', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3002, 0, 58, '普通居民', '志愿者-文苑-02', '13800012002', 'v3002_02@example.com', 1, '文苑社区志愿者之家2', '["教育","陪伴"]', 1, NOW(3), NOW(3), 0),
(1038, 'v_3002_03', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3002, 0, 62, '活力老人', '志愿者-文苑-03', '13800012003', 'v3002_03@example.com', 1, '文苑社区志愿者之家3', '["助老","陪诊","购物"]', 1, NOW(3), NOW(3), 0),
(1039, 'v_3002_04', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3002, 0, 49, '普通居民', '志愿者-文苑-04', '13800012004', 'v3002_04@example.com', 2, '文苑社区志愿者之家4', '["助浴","护理"]', 1, NOW(3), NOW(3), 0),
(1040, 'v_3002_05', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3002, 0, 53, '普通居民', '志愿者-文苑-05', '13800012005', 'v3002_05@example.com', 1, '文苑社区志愿者之家5', '["清洁","教育"]', 1, NOW(3), NOW(3), 0),
-- 3003：志愿者 5
(1041, 'v_3003_01', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3003, 0, 54, '普通居民', '志愿者-古荡-01', '13800013001', 'v3003_01@example.com', 1, '古荡社区志愿者之家1', '["助老","陪伴","心理疏导"]', 1, NOW(3), NOW(3), 0),
(1042, 'v_3003_02', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3003, 0, 51, '普通居民', '志愿者-古荡-02', '13800013002', 'v3003_02@example.com', 2, '古荡社区志愿者之家2', '["清洁","维修"]', 1, NOW(3), NOW(3), 0),
(1043, 'v_3003_03', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3003, 0, 63, '活力老人', '志愿者-古荡-03', '13800013003', 'v3003_03@example.com', 1, '古荡社区志愿者之家3', '["教育","陪诊"]', 1, NOW(3), NOW(3), 0),
(1044, 'v_3003_04', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3003, 0, 47, '普通居民', '志愿者-古荡-04', '13800013004', 'v3003_04@example.com', 2, '古荡社区志愿者之家4', '["购物","跑腿"]', 1, NOW(3), NOW(3), 0),
(1045, 'v_3003_05', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3003, 0, 59, '普通居民', '志愿者-古荡-05', '13800013005', 'v3003_05@example.com', 1, '古荡社区志愿者之家5', '["助浴","护理","陪伴"]', 1, NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  community_id = VALUES(community_id),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag),
  skill_tags = VALUES(skill_tags),
  status = VALUES(status),
  is_deleted = VALUES(is_deleted);

-- 5.3) 邀请码（3 社区各 1 个主码 + 1 个备用码）
INSERT INTO community_invite_code
  (id, community_id, code, status, expires_at, max_uses, used_count, created_by, created_at, updated_at)
VALUES
(9001, 3001, 'CY3001MAIN', 1, NULL, 200, 19, 2, NOW(3), NOW(3)),
(9002, 3001, 'CY3001BK',   1, DATE_ADD(NOW(3), INTERVAL 180 DAY), 100, 6, 2, NOW(3), NOW(3)),
(9003, 3002, 'WY3002MAIN', 1, NULL, 200, 16, 10, NOW(3), NOW(3)),
(9004, 3002, 'WY3002BK',   1, DATE_ADD(NOW(3), INTERVAL 180 DAY), 100, 3, 10, NOW(3), NOW(3)),
(9005, 3003, 'GD3003MAIN', 1, NULL, 200, 14, 11, NOW(3), NOW(3)),
(9006, 3003, 'GD3003BK',   1, DATE_ADD(NOW(3), INTERVAL 180 DAY), 100, 1, 11, NOW(3), NOW(3))
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  status = VALUES(status),
  expires_at = VALUES(expires_at),
  max_uses = VALUES(max_uses),
  used_count = VALUES(used_count),
  updated_at = VALUES(updated_at);

-- 5.4) 第三社区 Banner（3003）
INSERT INTO community_banner (id, community_id, title, subtitle, image_url, link_url, sort_no, status, created_by, created_at, updated_at) VALUES
(13, 3003, '古荡社区 · 便民互助', '需要帮忙就发布需求，志愿者就近服务', NULL, NULL, 1, 1, 11, NOW(3), NOW(3))
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  title = VALUES(title),
  subtitle = VALUES(subtitle),
  image_url = VALUES(image_url),
  link_url = VALUES(link_url),
  sort_no = VALUES(sort_no),
  status = VALUES(status),
  updated_at = VALUES(updated_at);

-- 5.5) 用户引导问卷（抽样 12 人，便于移动端“引导资料”展示）
INSERT INTO user_onboarding_profile (user_id, skill_tags_json, preferred_features_json, intent_note, created_at, updated_at) VALUES
(1031, '["助老","陪伴","购物"]', '["一键认领","语音输入"]', '希望周末参加陪伴类服务', NOW(), NOW()),
(1033, '["助浴","护理"]', '["紧急联系人","大字模式"]', '擅长护理类服务', NOW(), NOW()),
(1037, '["教育","陪伴"]', '["任务提醒","积分激励"]', '愿意辅导社区孩子作业', NOW(), NOW()),
(1038, '["助老","陪诊"]', '["就近匹配","时间银行"]', '更偏好白天服务', NOW(), NOW()),
(1042, '["清洁","维修"]', '["快速发布","电话预约"]', '可提供上门维修', NOW(), NOW()),
(1045, '["助浴","护理","陪伴"]', '["一键认领","大字模式"]', '擅长助浴与陪伴', NOW(), NOW()),
(1002, NULL, '["紧急联系人","大字模式"]', '希望快速找到志愿者帮忙购物', NOW(), NOW()),
(1012, NULL, '["电话预约","消息通知"]', '不会操作手机，偏好电话预约', NOW(), NOW()),
(1022, NULL, '["紧急联系人","语音输入"]', '希望能语音发布需求', NOW(), NOW()),
(1007, NULL, '["消息通知"]', '希望服务完成后能及时提醒评价', NOW(), NOW()),
(1017, NULL, '["大字模式"]', '界面希望字体更大', NOW(), NOW()),
(1027, NULL, '["消息通知","电话预约"]', '希望有人定期上门陪伴', NOW(), NOW())
ON DUPLICATE KEY UPDATE
  skill_tags_json = VALUES(skill_tags_json),
  preferred_features_json = VALUES(preferred_features_json),
  intent_note = VALUES(intent_note),
  updated_at = VALUES(updated_at);

-- 5.6) 需求/认领/完成/评价（显式 ID，覆盖三社区）
-- 说明：每社区 6 条需求：2 完成、2 已认领、1 已发布、1 待审核/驳回

-- 3001：需求
INSERT INTO service_request
  (id, requester_user_id, community_id, service_type, description, service_address, expected_time, urgency_level,
   emergency_contact_name, emergency_contact_phone, emergency_contact_relation, special_tags, status,
   audit_by_user_id, audit_at, reject_reason, published_at, claimed_at, completed_at, created_at, updated_at, is_deleted)
VALUES
(10001, 1002, 3001, '购物', '需要购买米面油及常用药', '翠苑社区A区2号楼202', DATE_ADD(NOW(3), INTERVAL 1 DAY), 3,
 '张阿姨', '13800009901', '邻居', '["独居老人"]', 3, 2, DATE_SUB(NOW(3), INTERVAL 6 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 6 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY),
 DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), 0),
(10002, 1004, 3001, '清洁', '厨房油污较重，需要深度清洁', '翠苑社区B区4号楼404', DATE_ADD(NOW(3), INTERVAL 2 DAY), 2,
 '李先生', '13800009902', '子女', '["行动不便"]', 3, 2, DATE_SUB(NOW(3), INTERVAL 9 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 9 DAY), DATE_SUB(NOW(3), INTERVAL 8 DAY), DATE_SUB(NOW(3), INTERVAL 8 DAY),
 DATE_SUB(NOW(3), INTERVAL 10 DAY), NOW(3), 0),
(10003, 1007, 3001, '陪伴', '希望有人周末陪伴聊天', '翠苑社区D区7号楼707', DATE_ADD(NOW(3), INTERVAL 3 DAY), 2,
 NULL, NULL, NULL, '["孤寡老人"]', 2, 2, DATE_SUB(NOW(3), INTERVAL 2 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 3 DAY), NOW(3), 0),
(10004, 1006, 3001, '维修', '门锁松动，需要上门调整', '翠苑社区C区6号楼606', DATE_ADD(NOW(3), INTERVAL 4 DAY), 1,
 NULL, NULL, NULL, NULL, 2, 2, DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 12 HOUR), NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(10005, 1005, 3001, '教育', '辅导孩子数学作业（四年级）', '翠苑社区C区5号楼505', DATE_ADD(NOW(3), INTERVAL 5 DAY), 1,
 NULL, NULL, NULL, '["单亲家庭"]', 1, 2, DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL, NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(10006, 1003, 3001, '助浴', '希望协助洗澡，注意安全', '翠苑社区B区3号楼303', DATE_ADD(NOW(3), INTERVAL 1 DAY), 4,
 '王先生', '13800009903', '子女', '["行动不便"]', 4, 2, DATE_SUB(NOW(3), INTERVAL 1 DAY), '当前联系方式不完整，请补充电话后再提交',
 NULL, NULL, NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  status = VALUES(status),
  community_id = VALUES(community_id),
  audit_by_user_id = VALUES(audit_by_user_id),
  audit_at = VALUES(audit_at),
  reject_reason = VALUES(reject_reason),
  published_at = VALUES(published_at),
  claimed_at = VALUES(claimed_at),
  completed_at = VALUES(completed_at),
  is_deleted = VALUES(is_deleted);

-- 3001：认领（2 已完成 + 2 已认领）
INSERT INTO service_claim
  (id, request_id, volunteer_user_id, claim_at, claim_status, service_hours, hours_submitted_at, completion_note, created_at, updated_at, is_deleted)
VALUES
(20001, 10001, 1031, DATE_SUB(NOW(3), INTERVAL 5 DAY), 2, 2.0, DATE_SUB(NOW(3), INTERVAL 5 DAY), '已陪同购买并送达', DATE_SUB(NOW(3), INTERVAL 5 DAY), NOW(3), 0),
(20002, 10002, 1032, DATE_SUB(NOW(3), INTERVAL 8 DAY), 2, 3.0, DATE_SUB(NOW(3), INTERVAL 8 DAY), '已完成深度清洁', DATE_SUB(NOW(3), INTERVAL 8 DAY), NOW(3), 0),
(20003, 10003, 1035, DATE_SUB(NOW(3), INTERVAL 1 DAY), 1, NULL, NULL, NULL, DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), 0),
(20004, 10004, 1032, DATE_SUB(NOW(3), INTERVAL 12 HOUR), 1, NULL, NULL, NULL, DATE_SUB(NOW(3), INTERVAL 12 HOUR), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  claim_status = VALUES(claim_status),
  service_hours = VALUES(service_hours),
  hours_submitted_at = VALUES(hours_submitted_at),
  completion_note = VALUES(completion_note),
  is_deleted = VALUES(is_deleted);

-- 3001：评价（仅完成的 2 条）
INSERT INTO service_evaluation
  (id, claim_id, request_id, resident_user_id, volunteer_user_id, rating, content, created_at, updated_at, is_deleted)
VALUES
(30001, 20001, 10001, 1002, 1031, 5, '非常感谢，物品送得很及时，态度也很好。', DATE_SUB(NOW(3), INTERVAL 4 DAY), NOW(3), 0),
(30002, 20002, 10002, 1004, 1032, 5, '清洁很到位，细节处理得很认真。', DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  rating = VALUES(rating),
  content = VALUES(content),
  updated_at = VALUES(updated_at),
  is_deleted = VALUES(is_deleted);

-- 3002：需求
INSERT INTO service_request
  (id, requester_user_id, community_id, service_type, description, service_address, expected_time, urgency_level,
   emergency_contact_name, emergency_contact_phone, emergency_contact_relation, special_tags, status,
   audit_by_user_id, audit_at, reject_reason, published_at, claimed_at, completed_at, created_at, updated_at, is_deleted)
VALUES
(11001, 1012, 3002, '陪诊', '需要陪同去社区卫生站复诊', '文苑社区A区2号楼202', DATE_ADD(NOW(3), INTERVAL 2 DAY), 3,
 '刘女士', '13800008801', '子女', '["独居老人"]', 3, 10, DATE_SUB(NOW(3), INTERVAL 6 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 6 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY),
 DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), 0),
(11002, 1015, 3002, '维修', '灯具不亮，疑似开关接触不良', '文苑社区C区5号楼505', DATE_ADD(NOW(3), INTERVAL 1 DAY), 2,
 NULL, NULL, NULL, NULL, 3, 10, DATE_SUB(NOW(3), INTERVAL 9 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 9 DAY), DATE_SUB(NOW(3), INTERVAL 8 DAY), DATE_SUB(NOW(3), INTERVAL 8 DAY),
 DATE_SUB(NOW(3), INTERVAL 10 DAY), NOW(3), 0),
(11003, 1017, 3002, '助老', '需要协助整理药盒并提醒服药', '文苑社区D区7号楼707', DATE_ADD(NOW(3), INTERVAL 3 DAY), 2,
 NULL, NULL, NULL, '["孤寡老人"]', 2, 10, DATE_SUB(NOW(3), INTERVAL 2 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 3 DAY), NOW(3), 0),
(11004, 1014, 3002, '清洁', '需要简单打扫房间及阳台', '文苑社区B区4号楼404', DATE_ADD(NOW(3), INTERVAL 4 DAY), 1,
 NULL, NULL, NULL, NULL, 2, 10, DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 12 HOUR), NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(11005, 1011, 3002, '教育', '需要辅导英语口语（初中）', '文苑社区A区1号楼101', DATE_ADD(NOW(3), INTERVAL 5 DAY), 1,
 NULL, NULL, NULL, NULL, 1, 10, DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL, NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(11006, 1013, 3002, '助浴', '希望协助洗澡，但时间不确定', '文苑社区B区3号楼303', DATE_ADD(NOW(3), INTERVAL 2 DAY), 3,
 NULL, NULL, NULL, '["行动不便"]', 0, NULL, NULL, NULL,
 NULL, NULL, NULL,
 DATE_SUB(NOW(3), INTERVAL 12 HOUR), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  status = VALUES(status),
  community_id = VALUES(community_id),
  audit_by_user_id = VALUES(audit_by_user_id),
  audit_at = VALUES(audit_at),
  reject_reason = VALUES(reject_reason),
  published_at = VALUES(published_at),
  claimed_at = VALUES(claimed_at),
  completed_at = VALUES(completed_at),
  is_deleted = VALUES(is_deleted);

-- 3002：认领
INSERT INTO service_claim
  (id, request_id, volunteer_user_id, claim_at, claim_status, service_hours, hours_submitted_at, completion_note, created_at, updated_at, is_deleted)
VALUES
(21001, 11001, 1038, DATE_SUB(NOW(3), INTERVAL 5 DAY), 2, 2.5, DATE_SUB(NOW(3), INTERVAL 5 DAY), '已陪同复诊并取药', DATE_SUB(NOW(3), INTERVAL 5 DAY), NOW(3), 0),
(21002, 11002, 1036, DATE_SUB(NOW(3), INTERVAL 8 DAY), 2, 1.5, DATE_SUB(NOW(3), INTERVAL 8 DAY), '已排查并更换开关', DATE_SUB(NOW(3), INTERVAL 8 DAY), NOW(3), 0),
(21003, 11003, 1037, DATE_SUB(NOW(3), INTERVAL 1 DAY), 1, NULL, NULL, NULL, DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), 0),
(21004, 11004, 1040, DATE_SUB(NOW(3), INTERVAL 12 HOUR), 1, NULL, NULL, NULL, DATE_SUB(NOW(3), INTERVAL 12 HOUR), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  claim_status = VALUES(claim_status),
  service_hours = VALUES(service_hours),
  hours_submitted_at = VALUES(hours_submitted_at),
  completion_note = VALUES(completion_note),
  is_deleted = VALUES(is_deleted);

-- 3002：评价
INSERT INTO service_evaluation
  (id, claim_id, request_id, resident_user_id, volunteer_user_id, rating, content, created_at, updated_at, is_deleted)
VALUES
(31001, 21001, 11001, 1012, 1038, 5, '陪诊很耐心，流程熟悉，帮了大忙。', DATE_SUB(NOW(3), INTERVAL 4 DAY), NOW(3), 0),
(31002, 21002, 11002, 1015, 1036, 5, '维修很专业，问题很快解决了。', DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  rating = VALUES(rating),
  content = VALUES(content),
  updated_at = VALUES(updated_at),
  is_deleted = VALUES(is_deleted);

-- 3003：需求
INSERT INTO service_request
  (id, requester_user_id, community_id, service_type, description, service_address, expected_time, urgency_level,
   emergency_contact_name, emergency_contact_phone, emergency_contact_relation, special_tags, status,
   audit_by_user_id, audit_at, reject_reason, published_at, claimed_at, completed_at, created_at, updated_at, is_deleted)
VALUES
(12001, 1022, 3003, '陪伴', '希望每周有人上门陪伴聊天一次', '古荡社区A区2号楼202', DATE_ADD(NOW(3), INTERVAL 3 DAY), 2,
 '陈先生', '13800007701', '子女', '["独居老人"]', 3, 11, DATE_SUB(NOW(3), INTERVAL 6 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 6 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY),
 DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), 0),
(12002, 1024, 3003, '清洁', '需要打扫卫生间并更换灯泡', '古荡社区B区4号楼404', DATE_ADD(NOW(3), INTERVAL 2 DAY), 2,
 NULL, NULL, NULL, NULL, 3, 11, DATE_SUB(NOW(3), INTERVAL 9 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 9 DAY), DATE_SUB(NOW(3), INTERVAL 8 DAY), DATE_SUB(NOW(3), INTERVAL 8 DAY),
 DATE_SUB(NOW(3), INTERVAL 10 DAY), NOW(3), 0),
(12003, 1027, 3003, '购物', '需要帮忙代买日用品并送到家', '古荡社区D区7号楼707', DATE_ADD(NOW(3), INTERVAL 1 DAY), 3,
 NULL, NULL, NULL, '["孤寡老人"]', 2, 11, DATE_SUB(NOW(3), INTERVAL 2 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 3 DAY), NOW(3), 0),
(12004, 1026, 3003, '维修', '热水器无法点火，需要上门排查', '古荡社区C区6号楼606', DATE_ADD(NOW(3), INTERVAL 4 DAY), 3,
 NULL, NULL, NULL, NULL, 2, 11, DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 12 HOUR), NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(12005, 1021, 3003, '教育', '需要辅导孩子语文阅读（五年级）', '古荡社区A区1号楼101', DATE_ADD(NOW(3), INTERVAL 5 DAY), 1,
 NULL, NULL, NULL, NULL, 1, 11, DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL, NULL,
 DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), 0),
(12006, 1023, 3003, '助浴', '需求较急，但地址描述不清', '古荡社区B区3号楼303', DATE_ADD(NOW(3), INTERVAL 1 DAY), 4,
 NULL, NULL, NULL, NULL, 4, 11, DATE_SUB(NOW(3), INTERVAL 1 DAY), '请补充具体楼栋单元信息后再提交',
 NULL, NULL, NULL,
 DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  status = VALUES(status),
  community_id = VALUES(community_id),
  audit_by_user_id = VALUES(audit_by_user_id),
  audit_at = VALUES(audit_at),
  reject_reason = VALUES(reject_reason),
  published_at = VALUES(published_at),
  claimed_at = VALUES(claimed_at),
  completed_at = VALUES(completed_at),
  is_deleted = VALUES(is_deleted);

-- 3003：认领
INSERT INTO service_claim
  (id, request_id, volunteer_user_id, claim_at, claim_status, service_hours, hours_submitted_at, completion_note, created_at, updated_at, is_deleted)
VALUES
(22001, 12001, 1041, DATE_SUB(NOW(3), INTERVAL 5 DAY), 2, 2.0, DATE_SUB(NOW(3), INTERVAL 5 DAY), '已上门陪伴并协助沟通', DATE_SUB(NOW(3), INTERVAL 5 DAY), NOW(3), 0),
(22002, 12002, 1042, DATE_SUB(NOW(3), INTERVAL 8 DAY), 2, 2.0, DATE_SUB(NOW(3), INTERVAL 8 DAY), '已完成打扫并更换灯泡', DATE_SUB(NOW(3), INTERVAL 8 DAY), NOW(3), 0),
(22003, 12003, 1044, DATE_SUB(NOW(3), INTERVAL 1 DAY), 1, NULL, NULL, NULL, DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), 0),
(22004, 12004, 1042, DATE_SUB(NOW(3), INTERVAL 12 HOUR), 1, NULL, NULL, NULL, DATE_SUB(NOW(3), INTERVAL 12 HOUR), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  claim_status = VALUES(claim_status),
  service_hours = VALUES(service_hours),
  hours_submitted_at = VALUES(hours_submitted_at),
  completion_note = VALUES(completion_note),
  is_deleted = VALUES(is_deleted);

-- 3003：评价
INSERT INTO service_evaluation
  (id, claim_id, request_id, resident_user_id, volunteer_user_id, rating, content, created_at, updated_at, is_deleted)
VALUES
(32001, 22001, 12001, 1022, 1041, 5, '很暖心，沟通也很耐心，感谢志愿者。', DATE_SUB(NOW(3), INTERVAL 4 DAY), NOW(3), 0),
(32002, 22002, 12002, 1024, 1042, 5, '清洁和更换灯泡都很利落，值得推荐。', DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  rating = VALUES(rating),
  content = VALUES(content),
  updated_at = VALUES(updated_at),
  is_deleted = VALUES(is_deleted);

-- 5.7) 时间银行：为“已完成”的 6 个需求生成订单与流水（amount=小时*10，整数）
INSERT INTO service_order (id, request_id, volunteer_user_id, community_id, status, created_at, updated_at, is_deleted) VALUES
(40001, 10001, 1031, 3001, 1, DATE_SUB(NOW(3), INTERVAL 5 DAY), NOW(3), 0),
(40002, 10002, 1032, 3001, 1, DATE_SUB(NOW(3), INTERVAL 8 DAY), NOW(3), 0),
(40003, 11001, 1038, 3002, 1, DATE_SUB(NOW(3), INTERVAL 5 DAY), NOW(3), 0),
(40004, 11002, 1036, 3002, 1, DATE_SUB(NOW(3), INTERVAL 8 DAY), NOW(3), 0),
(40005, 12001, 1041, 3003, 1, DATE_SUB(NOW(3), INTERVAL 5 DAY), NOW(3), 0),
(40006, 12002, 1042, 3003, 1, DATE_SUB(NOW(3), INTERVAL 8 DAY), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  volunteer_user_id = VALUES(volunteer_user_id),
  community_id = VALUES(community_id),
  status = VALUES(status),
  updated_at = VALUES(updated_at),
  is_deleted = VALUES(is_deleted);

INSERT INTO time_transaction (id, user_id, amount, type, order_id, create_time) VALUES
(50001, 1031, 20, 1, 40001, DATE_SUB(NOW(3), INTERVAL 5 DAY)),
(50002, 1032, 30, 1, 40002, DATE_SUB(NOW(3), INTERVAL 8 DAY)),
(50003, 1038, 25, 1, 40003, DATE_SUB(NOW(3), INTERVAL 5 DAY)),
(50004, 1036, 15, 1, 40004, DATE_SUB(NOW(3), INTERVAL 8 DAY)),
(50005, 1041, 20, 1, 40005, DATE_SUB(NOW(3), INTERVAL 5 DAY)),
(50006, 1042, 20, 1, 40006, DATE_SUB(NOW(3), INTERVAL 8 DAY))
ON DUPLICATE KEY UPDATE
  user_id = VALUES(user_id),
  amount = VALUES(amount),
  type = VALUES(type),
  order_id = VALUES(order_id),
  create_time = VALUES(create_time);

-- 5.8) 回填志愿者 time_coins/points（便于仪表盘统计展示）
-- 说明：为了保证 temp_data.sql 可重复执行，这里写成“确定值”而非累加
UPDATE sys_user
SET
  time_coins = CASE id
    WHEN 1031 THEN 20
    WHEN 1032 THEN 30
    WHEN 1036 THEN 15
    WHEN 1038 THEN 25
    WHEN 1041 THEN 20
    WHEN 1042 THEN 20
    ELSE time_coins
  END,
  points = CASE id
    -- points = 初始 points + time_transaction(服务所得)
    WHEN 1031 THEN 70  -- 50 + 20
    WHEN 1032 THEN 85  -- 55 + 30
    WHEN 1036 THEN 65  -- 50 + 15
    WHEN 1038 THEN 87  -- 62 + 25
    WHEN 1041 THEN 74  -- 54 + 20
    WHEN 1042 THEN 71  -- 51 + 20
    ELSE points
  END,
  updated_at = NOW(3)
WHERE id IN (1031, 1032, 1036, 1038, 1041, 1042);

