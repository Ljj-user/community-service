package com.community.platform.common;

/**
 * 常量类
 */
public class Constants {
    
    /**
     * 角色常量
     */
    public static final Byte ROLE_SUPER_ADMIN = 1;  // 超级管理员
    public static final Byte ROLE_COMMUNITY_ADMIN = 2;  // 社区管理员
    public static final Byte ROLE_NORMAL_USER = 3;  // 普通用户

    /**
     * 普通用户身份常量（仅 role=3 时使用）：1 居民老人，2 志愿者，互斥。
     */
    public static final Byte IDENTITY_RESIDENT = 1;
    public static final Byte IDENTITY_VOLUNTEER = 2;

    /**
     * 需求状态常量
     */
    public static final Byte REQUEST_STATUS_PENDING = 0;  // 待审核
    public static final Byte REQUEST_STATUS_PUBLISHED = 1;  // 已发布
    public static final Byte REQUEST_STATUS_CLAIMED = 2;  // 已认领
    public static final Byte REQUEST_STATUS_COMPLETED = 3;  // 已完成
    public static final Byte REQUEST_STATUS_REJECTED = 4;  // 已驳回

    /**
     * 用户状态常量
     */
    public static final Byte USER_STATUS_DISABLED = 0;  // 禁用
    public static final Byte USER_STATUS_ENABLED = 1;  // 启用
    
    /**
     * 认领状态常量
     */
    public static final Byte CLAIM_STATUS_CLAIMED = 1;  // 已认领
    public static final Byte CLAIM_STATUS_COMPLETED = 2;  // 已完成
    public static final Byte CLAIM_STATUS_CANCELLED = 3;  // 已取消

    /**
     * 站内通知分类：1业务待办 2系统公告
     */
    public static final Byte NOTIFICATION_CATEGORY_BUSINESS = 1;
    public static final Byte NOTIFICATION_CATEGORY_ANNOUNCEMENT = 2;

    public static final Byte NOTIFICATION_UNREAD = 0;
    public static final Byte NOTIFICATION_READ = 1;

    /**
     * 站内通知关联类型（ref_type）
     */
    public static final String NOTIF_REF_REQUEST_AUDIT = "REQUEST_AUDIT";
    public static final String NOTIF_REF_SERVICE_CLAIM = "SERVICE_CLAIM";
    public static final String NOTIF_REF_ANNOUNCEMENT = "ANNOUNCEMENT";
    public static final String NOTIF_REF_CARE_ALERT = "CARE_ALERT";
}
