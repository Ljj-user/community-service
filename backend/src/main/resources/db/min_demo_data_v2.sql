-- 社区公益服务对接管理平台 - PRD v2 最小演示数据
-- 演示账号口令已脱敏，请在本地初始化说明中自行配置。

USE community_service;
SET NAMES utf8mb4;

-- 1) 社区区域
INSERT INTO sys_region (id, name, level, parent_id, province, city, address, contact_phone, status) VALUES
(100, '西湖区', 1, NULL, '浙江省', '杭州市', NULL, NULL, 1),
(110, '文新街道', 2, 100, '浙江省', '杭州市', NULL, NULL, 1),
(3001, '翠苑社区', 3, 110, '浙江省', '杭州市', '杭州市西湖区文新街道翠苑社区', '0571-88880001', 1),
(3002, '文苑社区', 3, 110, '浙江省', '杭州市', '杭州市西湖区文新街道文苑社区', '0571-88880002', 1)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  level = VALUES(level),
  parent_id = VALUES(parent_id),
  province = VALUES(province),
  city = VALUES(city),
  address = VALUES(address),
  contact_phone = VALUES(contact_phone),
  status = VALUES(status);

-- 2) 系统配置
INSERT INTO sys_config (config_key, config_value) VALUES
('basic', '{"pointsPerHour":10,"feedbackDays":3,"enableLargeText":true}'),
('notice', '{"demandApproved":"您的求助已通过审核。","demandRejected":"您的求助未通过审核。"}'),
('alert', '{"careInactivityDays":3,"surge24hMinRequests":5,"surgeMultiplier":2,"enableCareInactivityAlert":true,"enableDemandSurgeAlert":true,"alertNotifyChannels":["IN_APP"]}'),
('ai', '{"enabled":false,"provider":"deepseek","model":"deepseek-v4-flash"}')
ON DUPLICATE KEY UPDATE
  config_value = VALUES(config_value),
  updated_at = NOW(3);

-- 3) 用户
INSERT INTO sys_user (
  id, username, password_md5, role, identity_type, community_id, community_join_status,
  real_name, phone, email, avatar_url, gender, address, time_coins, points, identity_tag,
  skill_tags, status, last_login_at, created_at, updated_at, is_deleted
) VALUES
(1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', 1, 1, NULL, 0, '系统管理员', '13800000001', 'admin@demo.com', NULL, 1, '平台管理中心', 0, 0, NULL, NULL, 1, NOW(3), NOW(3), NOW(3), 0),
(2, 'manager', 'e10adc3949ba59abbe56e057f20f883e', 2, 1, 3001, 2, '翠苑社区管理员', '13800000002', 'manager@demo.com', NULL, 2, '翠苑社区服务站', 0, 0, NULL, NULL, 1, NOW(3), NOW(3), NOW(3), 0),
(3, 'resident1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 2, '张大爷', '13800000011', 'resident1@demo.com', NULL, 1, '翠苑社区1栋101', 20, 100, '普通居民', NULL, 1, NOW(3), NOW(3), NOW(3), 0),
(4, 'elder1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, 3001, 2, '李奶奶', '13800000012', 'elder1@demo.com', NULL, 2, '翠苑社区2栋202', 10, 80, '独居老人', NULL, 1, DATE_SUB(NOW(3), INTERVAL 7 DAY), NOW(3), NOW(3), 0),
(5, 'volunteer1', 'e10adc3949ba59abbe56e057f20f883e', 3, 2, 3001, 2, '志愿者小王', '13800000021', 'vol1@demo.com', NULL, 1, '翠苑社区5栋501', 0, 200, '普通居民', '["护理","助浴","陪伴"]', 1, NOW(3), NOW(3), NOW(3), 0),
(6, 'pending1', 'e10adc3949ba59abbe56e057f20f883e', 3, 1, NULL, 1, '待审核居民', '13800000031', 'pending1@demo.com', NULL, 2, '翠苑社区7栋701', 0, 0, '普通居民', NULL, 1, NOW(3), NOW(3), NOW(3), 0)
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

-- 4) 社区邀请码与加入申请
INSERT INTO community_invite_code
  (id, community_id, code, status, expires_at, max_uses, used_count, created_by)
VALUES
  (9001, 3001, 'DEMO3001', 1, DATE_ADD(NOW(3), INTERVAL 30 DAY), 200, 1, 2),
  (9002, 3002, 'DEMO3002', 1, DATE_ADD(NOW(3), INTERVAL 30 DAY), 200, 0, 1)
ON DUPLICATE KEY UPDATE
  community_id = VALUES(community_id),
  status = VALUES(status),
  expires_at = VALUES(expires_at),
  max_uses = VALUES(max_uses),
  used_count = VALUES(used_count),
  updated_at = NOW(3);

INSERT INTO community_join_application
  (id, user_id, community_id, invite_code, real_name, phone, address, status, reviewer_user_id, reviewed_at, reject_reason)
VALUES
  (9101, 6, 3001, 'DEMO3001', '待审核居民', '13800000031', '翠苑社区7栋701', 0, NULL, NULL, NULL),
  (9102, 3, 3001, 'DEMO3001', '张大爷', '13800000011', '翠苑社区1栋101', 1, 2, NOW(3), NULL)
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  reviewer_user_id = VALUES(reviewer_user_id),
  reviewed_at = VALUES(reviewed_at),
  reject_reason = VALUES(reject_reason),
  updated_at = NOW(3);

-- 5) 志愿者认证与重点关怀
INSERT INTO volunteer_profile
  (id, user_id, community_id, cert_status, real_name, id_card_no, skill_tags, service_radius_km, available_time, service_count, completed_count, cancelled_count, avg_rating, reviewer_user_id, certified_at)
VALUES
  (5001, 5, 3001, 2, '志愿者小王', '330100199001010011', '["护理","助浴","陪伴"]', 3.00, '工作日晚上、周末全天', 12, 10, 1, 4.80, 2, NOW(3))
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
  (6001, 4, 3001, '独居老人', 3, '独居', '行动较慢，需要定期关注', '李女士', '13900000012', '女儿', 1, DATE_SUB(NOW(3), INTERVAL 10 DAY), 2)
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

-- 6) 公益需求、接单、订单、评价
INSERT INTO service_request
  (id, requester_user_id, target_user_id, community_id, title, service_type, description, service_address, contact_phone, expected_time, urgency_level, priority_flag, emergency_contact_name, emergency_contact_phone, emergency_contact_relation, special_tags, status, audit_by_user_id, audit_at, published_at, claimed_at, completed_at)
VALUES
  (8001, 4, 4, 3001, '需要陪诊去社区医院', '陪诊陪同', '上午去社区医院复诊，希望有人陪同排队取药。', '翠苑社区2栋202', '13800000012', DATE_ADD(NOW(3), INTERVAL 1 DAY), 4, 1, '李女士', '13900000012', '女儿', '["独居老人","陪诊"]', 1, 2, NOW(3), NOW(3), NULL, NULL),
  (8002, 3, 3, 3001, '帮忙买菜取药', '代买取药', '腿脚不方便，需要买青菜和降压药。', '翠苑社区1栋101', '13800000011', DATE_ADD(NOW(3), INTERVAL 2 DAY), 2, 0, NULL, NULL, NULL, '["代买","取药"]', 2, 2, DATE_SUB(NOW(3), INTERVAL 1 DAY), DATE_SUB(NOW(3), INTERVAL 1 DAY), NOW(3), NULL),
  (8003, 4, 4, 3001, '周末家务协助', '家务协助', '帮忙打扫厨房和客厅。', '翠苑社区2栋202', '13800000012', DATE_SUB(NOW(3), INTERVAL 2 DAY), 2, 0, '李女士', '13900000012', '女儿', '["家务","独居老人"]', 3, 2, DATE_SUB(NOW(3), INTERVAL 4 DAY), DATE_SUB(NOW(3), INTERVAL 4 DAY), DATE_SUB(NOW(3), INTERVAL 3 DAY), DATE_SUB(NOW(3), INTERVAL 2 DAY))
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
  updated_at = NOW(3),
  is_deleted = 0;

INSERT INTO service_claim
  (id, request_id, volunteer_user_id, claim_at, claim_status, service_hours, hours_submitted_at, completion_note)
VALUES
  (8101, 8002, 5, NOW(3), 1, NULL, NULL, NULL),
  (8102, 8003, 5, DATE_SUB(NOW(3), INTERVAL 3 DAY), 2, 2.00, DATE_SUB(NOW(3), INTERVAL 2 DAY), '已完成家务协助')
ON DUPLICATE KEY UPDATE
  request_id = VALUES(request_id),
  volunteer_user_id = VALUES(volunteer_user_id),
  claim_status = VALUES(claim_status),
  service_hours = VALUES(service_hours),
  completion_note = VALUES(completion_note),
  updated_at = NOW(3),
  is_deleted = 0;

INSERT INTO service_order
  (id, request_id, claim_id, volunteer_user_id, community_id, status)
VALUES
  (8201, 8002, 8101, 5, 3001, 2),
  (8202, 8003, 8102, 5, 3001, 5)
ON DUPLICATE KEY UPDATE
  claim_id = VALUES(claim_id),
  volunteer_user_id = VALUES(volunteer_user_id),
  status = VALUES(status),
  updated_at = NOW(3),
  is_deleted = 0;

INSERT INTO service_evaluation
  (id, claim_id, request_id, resident_user_id, volunteer_user_id, evaluator_role, rating, content)
VALUES
  (8301, 8102, 8003, 4, 5, 1, 5, '很认真，也很准时。')
ON DUPLICATE KEY UPDATE
  rating = VALUES(rating),
  content = VALUES(content),
  updated_at = NOW(3),
  is_deleted = 0;

-- 7) 公告与便民信息
INSERT INTO announcement
  (id, title, content_html, content_text, target_scope, target_community_id, status, is_top, top_at, publisher_user_id, published_at)
VALUES
  (7001, '翠苑社区志愿者招募', '<p>本周六上午9点，社区招募陪诊和代买志愿者。</p>', '本周六上午9点，社区招募陪诊和代买志愿者。', 1, 3001, 1, 1, NOW(3), 2, NOW(3)),
  (7002, '社区卫生服务站义诊通知', '<p>本周三下午两点，社区卫生服务站提供义诊。</p>', '本周三下午两点，社区卫生服务站提供义诊。', 1, 3001, 1, 0, NULL, 2, NOW(3))
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
  (7201, 3001, '社区电话', '翠苑社区服务站', '工作日 9:00-17:30 可咨询公益服务。', '0571-88880001', '翠苑社区服务站', 1, 1, 2),
  (7202, 3001, '医院药店', '文新街道社区卫生服务中心', '可提供基础诊疗和取药服务。', '0571-88881234', '文新街道卫生服务中心', 2, 1, 2),
  (7203, 3001, '维修服务', '社区便民维修点', '水电小修可先电话咨询。', '0571-88885678', '翠苑二区门口', 3, 1, 2)
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  content = VALUES(content),
  contact_phone = VALUES(contact_phone),
  address = VALUES(address),
  sort_no = VALUES(sort_no),
  status = VALUES(status),
  updated_at = NOW(3),
  is_deleted = 0;

-- 8) 推荐、信用、预警
INSERT INTO sys_user_skill (user_id, skill_tag) VALUES
  (5, '护理'),
  (5, '助浴'),
  (5, '陪伴'),
  (5, '代买取药')
ON DUPLICATE KEY UPDATE created_at = NOW(3);

INSERT INTO service_request_tag (request_id, tag_name) VALUES
  (8001, '陪诊'),
  (8001, '独居老人'),
  (8002, '代买取药'),
  (8003, '家务协助')
ON DUPLICATE KEY UPDATE created_at = NOW(3);

INSERT INTO volunteer_match_snapshot
  (id, request_id, volunteer_user_id, total_score, skill_score, area_score, priority_score, rating_score, reason_tags_json)
VALUES
  (8401, 8001, 5, 91.50, 35.00, 25.00, 20.00, 11.50, '["同社区","技能匹配","评分较高"]')
ON DUPLICATE KEY UPDATE
  total_score = VALUES(total_score),
  reason_tags_json = VALUES(reason_tags_json);

INSERT INTO volunteer_credit_snapshot
  (user_id, total_hours, avg_rating_30d, completion_rate_30d, credit_score)
VALUES
  (5, 26.50, 4.80, 0.92, 88.00)
ON DUPLICATE KEY UPDATE
  total_hours = VALUES(total_hours),
  avg_rating_30d = VALUES(avg_rating_30d),
  completion_rate_30d = VALUES(completion_rate_30d),
  credit_score = VALUES(credit_score),
  updated_at = NOW(3);

INSERT INTO anomaly_alert_event
  (id, alert_code, community_id, request_id, target_user_id, severity, trigger_rule, suggestion_action, rule_snapshot, dedup_key, status)
VALUES
  (8501, 'CARE_INACTIVE', 3001, NULL, 4, 2, '重点对象连续3天未登录', '建议社区管理员电话关怀或上门核实', '{"days":3}', CONCAT('CARE_INACTIVE:4:', CURDATE()), 0)
ON DUPLICATE KEY UPDATE
  status = VALUES(status),
  trigger_rule = VALUES(trigger_rule),
  suggestion_action = VALUES(suggestion_action);

INSERT INTO sys_notification
  (recipient_user_id, title, summary, msg_category, read_status, ref_type, ref_id)
VALUES
  (2, '关怀预警：重点对象未登录', '李奶奶已连续多日未登录，建议主动跟进。', 1, 0, 'CARE_ALERT', 8501);
