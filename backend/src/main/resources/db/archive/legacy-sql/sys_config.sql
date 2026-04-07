-- 系统配置表（key-value，存储 basic/notice/alert 三类 JSON 配置）
CREATE TABLE IF NOT EXISTS sys_config (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  config_key VARCHAR(64) NOT NULL UNIQUE COMMENT '配置键: basic/notice/alert',
  config_value JSON NOT NULL COMMENT '配置值 JSON',
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- 初始化默认配置
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
