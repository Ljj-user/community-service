USE community_service;

ALTER TABLE service_request
    ADD COLUMN emergency_contact_name VARCHAR(64) NULL COMMENT '紧急联系人姓名' AFTER urgency_level,
  ADD COLUMN emergency_contact_phone VARCHAR(32) NULL COMMENT '紧急联系人电话' AFTER emergency_contact_name,
  ADD COLUMN emergency_contact_relation VARCHAR(32) NULL COMMENT '与服务对象关系（子女/邻居等）' AFTER emergency_contact_phone;