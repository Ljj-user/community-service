-- 社区公益服务对接管理平台
-- 丰盈社区专用演示数据
-- 用途：在已执行 schema_v2_prd.sql 与基础演示数据后，单独补充一个“丰盈社区”用于现场演示

USE community_service;
SET NAMES utf8mb4;

-- 1) 社区区域
INSERT INTO sys_region (id, name, level, parent_id, province, city, address, contact_phone, status) VALUES
(3003, '丰盈社区', 3, 110, '浙江省', '杭州市', '杭州市西湖区文新街道丰盈社区', '0571-88880003', 1)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  level = VALUES(level),
  parent_id = VALUES(parent_id),
  province = VALUES(province),
  city = VALUES(city),
  address = VALUES(address),
  contact_phone = VALUES(contact_phone),
  status = VALUES(status);

-- 2) 丰盈社区用户
INSERT INTO sys_user (
  id, username, password_md5, role, identity_type, community_id, community_join_status,
  real_name, phone, email, avatar_url, gender, address, time_coins, points, identity_tag,
  skill_tags, status, last_login_at, created_at, updated_at, is_deleted
) VALUES
(21, 'fy_manager', 'e10adc3949ba59abbe56e057f20f883e', 2, 1, 3003, 2, '丰盈社区管理员', '13800000103', 'fy_manager@demo.com', NULL, 2, '丰盈社区党群服务中心', 0, 0, NULL, NULL, 1, NOW(3), NOW(3), NOW(3), 0),
(22, 'fy_resident1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 2, '周阿姨', '13800000111', 'fy_resident1@demo.com', NULL, 2, '丰盈社区1栋102', 12, 96, '普通居民', NULL, 1, DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), NOW(3), 0),
(23, 'fy_elder1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 2, '沈奶奶', '13800000112', 'fy_elder1@demo.com', NULL, 2, '丰盈社区2栋302', 4, 88, '独居老人', NULL, 1, DATE_SUB(NOW(3), INTERVAL 6 DAY), NOW(3), NOW(3), 0),
(24, 'fy_resident2', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 2, '刘师傅', '13800000113', 'fy_resident2@demo.com', NULL, 1, '丰盈社区3栋201', 8, 72, '慢病居民', NULL, 1, DATE_SUB(NOW(3), INTERVAL 2 DAY), NOW(3), NOW(3), 0),
(25, 'fy_volunteer1', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3003, 2, '志愿者小陈', '13800000121', 'fy_volunteer1@demo.com', NULL, 1, '丰盈社区5栋601', 0, 220, '普通居民', '["陪诊","代买取药","家务协助"]', 1, DATE_SUB(NOW(3), INTERVAL 1 HOUR), NOW(3), NOW(3), 0),
(26, 'fy_volunteer2', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3003, 2, '志愿者小许', '13800000122', 'fy_volunteer2@demo.com', NULL, 2, '丰盈社区6栋402', 0, 185, '普通居民', '["助浴","护理","陪伴聊天"]', 1, DATE_SUB(NOW(3), INTERVAL 5 HOUR), NOW(3), NOW(3), 0),
(27, 'fy_pending1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, NULL, 1, '待审核住户', '13800000131', 'fy_pending1@demo.com', NULL, 1, '丰盈社区8栋701', 0, 0, '普通居民', NULL, 1, NOW(3), NOW(3), NOW(3), 0),
(28, 'fy_care1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3003, 2, '赵伯伯', '13800000114', 'fy_care1@demo.com', NULL, 1, '丰盈社区4栋104', 3, 64, '重点关怀对象', NULL, 1, DATE_SUB(NOW(3), INTERVAL 4 DAY), NOW(3), NOW(3), 0)
ON DUPLICATE KEY UPDATE
  role = VALUES(role),
  identity_type = VALUES(identity_type),
  community_id = VALUES(community_id),
  community_join_status = VALUES(community_join_status),
  real_name = VALUES(real_name),
  phone = VALUES(phone),
  email = VALUES(email),
  gender = VALUES(gender),
  address = VALUES(address),
  time_coins = VALUES(time_coins),
  points = VALUES(points),
  identity_tag = VALUES(identity_tag),
  skill_tags = VALUES(skill_tags),
  status = VALUES(status),
  last_login_at = VALUES(last_login_at),
  updated_at = NOW(3),
  is_deleted = 0;

-- 3) 邀请码与加入申请
INSERT INTO community_invite_code
  (id, community_id, code, status, expires_at, max_uses, used_count, created_by)
VALUES
  (9003, 3003, 'FY3003', 1, DATE_ADD(NOW(3), INTERVAL 60 DAY), 300, 2, 21)
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  code = VALUES(code),
  status = VALUES(status),
  expires_at = VALUES(expires_at),
  max_uses = VALUES(max_uses),
  used_count = VALUES(used_count),
  updated_at = NOW(3);

INSERT INTO community_join_application
  (id, user_id, community_id, invite_code, real_name, phone, address, status, reviewer_user_id, reviewed_at, reject_reason)
VALUES
  (9103, 27, 3003, 'FY3003', '待审核住户', '13800000131', '丰盈社区8栋701', 0, NULL, NULL, NULL),
  (9104, 22, 3003, 'FY3003', '周阿姨', '13800000111', '丰盈社区1栋102', 1, 21, NOW(3), NULL)
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  reviewer_user_id = VALUES(reviewer_user_id),
  reviewed_at = VALUES(reviewed_at),
  reject_reason = VALUES(reject_reason),
  updated_at = NOW(3);

-- 4) 志愿者认证与重点关怀
INSERT INTO volunteer_profile
  (id, user_id, community_id, cert_status, real_name, id_card_no, skill_tags, service_radius_km, available_time, service_count, completed_count, cancelled_count, avg_rating, reviewer_user_id, certified_at)
VALUES
  (5003, 25, 3003, 2, '志愿者小陈', '330100199202020021', '["陪诊","代买取药","家务协助"]', 3.50, '工作日晚上、周末全天', 18, 16, 1, 4.90, 21, NOW(3)),
  (5004, 26, 3003, 2, '志愿者小许', '330100199405050022', '["助浴","护理","陪伴聊天"]', 2.80, '周一至周五白天', 11, 9, 1, 4.70, 21, NOW(3))
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  cert_status = VALUES(cert_status),
  skill_tags = VALUES(skill_tags),
  service_radius_km = VALUES(service_radius_km),
  available_time = VALUES(available_time),
  service_count = VALUES(service_count),
  completed_count = VALUES(completed_count),
  cancelled_count = VALUES(cancelled_count),
  avg_rating = VALUES(avg_rating),
  updated_at = NOW(3);

INSERT INTO care_subject_profile
  (id, user_id, community_id, care_type, care_level, living_status, health_note, emergency_contact_name, emergency_contact_phone, emergency_contact_relation, monitor_enabled, last_visit_at, created_by)
VALUES
  (6003, 23, 3003, '独居老人', 3, '独居', '近期腿脚不便，外出需要陪同。', '沈女士', '13900000112', '女儿', 1, DATE_SUB(NOW(3), INTERVAL 9 DAY), 21),
  (6004, 28, 3003, '慢病老人', 2, '与老伴同住', '高血压，需要定期复诊和取药。', '赵先生', '13900000114', '儿子', 1, DATE_SUB(NOW(3), INTERVAL 5 DAY), 21)
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  care_type = VALUES(care_type),
  care_level = VALUES(care_level),
  living_status = VALUES(living_status),
  health_note = VALUES(health_note),
  emergency_contact_name = VALUES(emergency_contact_name),
  emergency_contact_phone = VALUES(emergency_contact_phone),
  emergency_contact_relation = VALUES(emergency_contact_relation),
  monitor_enabled = VALUES(monitor_enabled),
  last_visit_at = VALUES(last_visit_at),
  updated_at = NOW(3),
  is_deleted = 0;

-- 5) 服务需求
INSERT INTO service_request
  (id, requester_user_id, target_user_id, community_id, title, service_type, description, service_address, contact_phone, expected_time, urgency_level, priority_flag, emergency_contact_name, emergency_contact_phone, emergency_contact_relation, special_tags, status, audit_by_user_id, audit_at, published_at, claimed_at, completed_at)
VALUES
  (8004, 23, 23, 3003, '明早陪诊去社区医院', '陪诊陪同', '需要有人陪同挂号、排队和取药。', '丰盈社区2栋302', '13800000112', DATE_ADD(NOW(3), INTERVAL 1 DAY), 4, 1, '沈女士', '13900000112', '女儿', '["独居老人","陪诊"]', 1, 21, NOW(3), NOW(3), NULL, NULL),
  (8005, 22, 22, 3003, '下午帮忙买菜', '代买取药', '需要买青菜、鸡蛋和降压药。', '丰盈社区1栋102', '13800000111', DATE_ADD(NOW(3), INTERVAL 6 HOUR), 2, 0, NULL, NULL, NULL, '["代买","慢病家庭"]', 2, 21, DATE_SUB(NOW(3), INTERVAL 2 DAY), DATE_SUB(NOW(3), INTERVAL 2 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), NULL),
  (8006, 28, 28, 3003, '周末上门整理房间', '家务协助', '帮忙整理卧室和客厅，顺便检查家电开关。', '丰盈社区4栋104', '13800000114', DATE_SUB(NOW(3), INTERVAL 2 DAY), 2, 0, '赵先生', '13900000114', '儿子', '["家务","重点关怀"]', 5, 21, DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 5 DAY), DATE_SUB(NOW(3), INTERVAL 4 DAY), DATE_SUB(NOW(3), INTERVAL 3 DAY)),
  (8007, 24, 24, 3003, '急需上门助浴', '助浴护理', '老人洗澡不方便，希望安排有经验志愿者。', '丰盈社区3栋201', '13800000113', DATE_ADD(NOW(3), INTERVAL 12 HOUR), 4, 1, '刘女士', '13900000113', '女儿', '["助浴","护理"]', 3, 21, DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 20 HOUR), NULL),
  (8008, 22, 22, 3003, '下周证件代办咨询', '政务代办', '想咨询老年卡补办流程，先做线下引导。', '丰盈社区1栋102', '13800000111', DATE_ADD(NOW(3), INTERVAL 4 DAY), 1, 0, NULL, NULL, NULL, '["政务","咨询"]', 0, NULL, NULL, NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  service_type = VALUES(service_type),
  description = VALUES(description),
  service_address = VALUES(service_address),
  contact_phone = VALUES(contact_phone),
  expected_time = VALUES(expected_time),
  urgency_level = VALUES(urgency_level),
  priority_flag = VALUES(priority_flag),
  special_tags = VALUES(special_tags),
  status = VALUES(status),
  audit_by_user_id = VALUES(audit_by_user_id),
  audit_at = VALUES(audit_at),
  published_at = VALUES(published_at),
  claimed_at = VALUES(claimed_at),
  completed_at = VALUES(completed_at),
  updated_at = NOW(3),
  is_deleted = 0;

INSERT INTO service_claim
  (id, request_id, volunteer_user_id, claim_at, claim_status, service_hours, hours_submitted_at, completion_note)
VALUES
  (8103, 8005, 25, DATE_SUB(NOW(3), INTERVAL 1 DAY), 1, NULL, NULL, NULL),
  (8104, 8006, 25, DATE_SUB(NOW(3), INTERVAL 4 DAY), 2, 2.50, DATE_SUB(NOW(3), INTERVAL 3 DAY), '已完成居室整理，并提醒关闭燃气阀门。'),
  (8105, 8007, 26, DATE_SUB(NOW(3), INTERVAL 20 HOUR), 2, 1.50, DATE_SUB(NOW(3), INTERVAL 2 HOUR), '助浴服务已完成，老人状态平稳。')
ON DUPLICATE KEY UPDATE
  request_id = VALUES(request_id),
  volunteer_user_id = VALUES(volunteer_user_id),
  claim_status = VALUES(claim_status),
  service_hours = VALUES(service_hours),
  hours_submitted_at = VALUES(hours_submitted_at),
  completion_note = VALUES(completion_note),
  updated_at = NOW(3),
  is_deleted = 0;

INSERT INTO service_order
  (id, request_id, claim_id, volunteer_user_id, community_id, status)
VALUES
  (8203, 8005, 8103, 25, 3003, 2),
  (8204, 8006, 8104, 25, 3003, 5),
  (8205, 8007, 8105, 26, 3003, 3)
ON DUPLICATE KEY UPDATE
  claim_id = VALUES(claim_id),
  volunteer_user_id = VALUES(volunteer_user_id),
  status = VALUES(status),
  updated_at = NOW(3),
  is_deleted = 0;

INSERT INTO service_evaluation
  (id, claim_id, request_id, resident_user_id, volunteer_user_id, evaluator_role, rating, content)
VALUES
  (8303, 8104, 8006, 28, 25, 1, 5, '服务很细致，还顺手帮我检查了插座。'),
  (8304, 8105, 8007, 24, 26, 1, 5, '沟通耐心，助浴过程很专业。')
ON DUPLICATE KEY UPDATE
  rating = VALUES(rating),
  content = VALUES(content),
  updated_at = NOW(3),
  is_deleted = 0;

-- 6) 公告与便民信息
INSERT INTO announcement
  (id, title, content_html, content_text, target_scope, target_community_id, status, is_top, top_at, publisher_user_id, published_at)
VALUES
  (7003, '丰盈社区周末陪诊志愿者招募', '<p>本周六上午集中安排陪诊服务，请有空的志愿者提前报名。</p>', '本周六上午集中安排陪诊服务，请有空的志愿者提前报名。', 1, 3003, 1, 1, NOW(3), 21, NOW(3)),
  (7004, '老年人防诈骗讲座通知', '<p>周四下午两点在社区活动室开展防诈骗讲座。</p>', '周四下午两点在社区活动室开展防诈骗讲座。', 1, 3003, 1, 0, NULL, 21, NOW(3)),
  (7005, '重点关怀住户本周回访安排', '<p>社区将于本周完成重点关怀对象一轮电话回访。</p>', '社区将于本周完成重点关怀对象一轮电话回访。', 1, 3003, 1, 0, NULL, 21, NOW(3))
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  content_html = VALUES(content_html),
  content_text = VALUES(content_text),
  status = VALUES(status),
  updated_at = NOW(3),
  is_deleted = 0;

INSERT INTO convenience_info
  (id, community_id, category, title, content, contact_phone, address, sort_no, status, created_by)
VALUES
  (7204, 3003, '社区电话', '丰盈社区党群服务中心', '工作日 9:00-17:30 可咨询社区公益服务与加入审核。', '0571-88880003', '丰盈社区服务中心一楼', 1, 1, 21),
  (7205, 3003, '医院药店', '文新街道社区卫生服务站', '提供基础诊疗、复诊开药和慢病建档。', '0571-88882345', '文新街道便民路18号', 2, 1, 21),
  (7206, 3003, '政务服务', '社区便民代办窗口', '可咨询老年卡、医保报销和高龄补贴流程。', '0571-88883456', '丰盈社区服务中心二楼', 3, 1, 21),
  (7207, 3003, '维修服务', '丰盈便民维修点', '提供水电小修和门锁故障上门登记。', '0571-88884567', '丰盈社区东门商铺', 4, 1, 21)
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  content = VALUES(content),
  contact_phone = VALUES(contact_phone),
  address = VALUES(address),
  sort_no = VALUES(sort_no),
  status = VALUES(status),
  updated_at = NOW(3),
  is_deleted = 0;

-- 7) 标签、匹配、信用、预警
INSERT INTO sys_user_skill (user_id, skill_tag) VALUES
  (25, '陪诊'),
  (25, '代买取药'),
  (25, '家务协助'),
  (26, '助浴'),
  (26, '护理'),
  (26, '陪伴聊天')
ON DUPLICATE KEY UPDATE created_at = NOW(3);

INSERT INTO service_request_tag (request_id, tag_name) VALUES
  (8004, '陪诊'),
  (8004, '独居老人'),
  (8005, '代买取药'),
  (8006, '重点关怀'),
  (8007, '助浴护理'),
  (8008, '政务咨询')
ON DUPLICATE KEY UPDATE created_at = NOW(3);

INSERT INTO volunteer_match_snapshot
  (id, request_id, volunteer_user_id, total_score, skill_score, area_score, priority_score, rating_score, reason_tags_json)
VALUES
  (8403, 8004, 25, 93.20, 36.00, 25.00, 20.00, 12.20, '["同社区","陪诊经验匹配","历史评分高"]'),
  (8404, 8007, 26, 94.60, 38.00, 24.00, 20.00, 12.60, '["助浴技能匹配","重点需求优先","履约稳定"]'),
  (8405, 8008, 25, 79.30, 28.00, 25.00, 14.00, 12.30, '["可做咨询引导","同社区响应快"]')
ON DUPLICATE KEY UPDATE
  total_score = VALUES(total_score),
  skill_score = VALUES(skill_score),
  area_score = VALUES(area_score),
  priority_score = VALUES(priority_score),
  rating_score = VALUES(rating_score),
  reason_tags_json = VALUES(reason_tags_json);

INSERT INTO volunteer_credit_snapshot
  (user_id, total_hours, avg_rating_30d, completion_rate_30d, credit_score)
VALUES
  (25, 38.00, 4.90, 0.95, 91.00),
  (26, 21.50, 4.75, 0.90, 86.50)
ON DUPLICATE KEY UPDATE
  total_hours = VALUES(total_hours),
  avg_rating_30d = VALUES(avg_rating_30d),
  completion_rate_30d = VALUES(completion_rate_30d),
  credit_score = VALUES(credit_score),
  updated_at = NOW(3);

INSERT INTO anomaly_alert_event
  (id, alert_code, community_id, request_id, target_user_id, severity, trigger_rule, suggestion_action, rule_snapshot, dedup_key, status)
VALUES
  (8503, 'CARE_INACTIVE', 3003, NULL, 23, 2, '重点对象连续3天未登录', '建议管理员电话回访并确认复诊安排', '{"days":3}', CONCAT('CARE_INACTIVE:23:', CURDATE()), 0),
  (8504, 'URGENT_REQUEST_PENDING', 3003, 8004, 23, 3, '高优先级需求待接单超过2小时', '建议优先推送给陪诊志愿者并电话确认', '{"hours":2}', CONCAT('URGENT_REQUEST_PENDING:8004:', CURDATE()), 0)
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  trigger_rule = VALUES(trigger_rule),
  suggestion_action = VALUES(suggestion_action);

INSERT INTO sys_notification
  (recipient_user_id, title, summary, msg_category, read_status, ref_type, ref_id)
VALUES
  (21, '关怀预警：独居老人待回访', '沈奶奶近几日未登录，建议尽快电话联系。', 1, 0, 'CARE_ALERT', 8503),
  (21, '紧急需求提醒：陪诊单待分配', '丰盈社区有一条高优先级陪诊需求待志愿者响应。', 1, 0, 'REQUEST_ALERT', 8504);
