package com.community.platform.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 服务过程监控 VO
 */
@Data
public class ServiceMonitorVO {

    /**
     * 需求ID
     */
    private Long requestId;

    /**
     * 需求状态
     */
    private Byte status;

    /**
     * 风险类型：1超时未认领 2超时未完成
     */
    private Integer riskType;

    /**
     * 服务类型
     */
    private String serviceType;

    /**
     * 服务地址
     */
    private String serviceAddress;

    /**
     * 期望服务时间
     */
    private LocalDateTime expectedTime;

    /**
     * 紧急程度
     */
    private Byte urgencyLevel;

    /**
     * 需求发起人姓名
     */
    private String requesterName;

    /**
     * 认领志愿者姓名
     */
    private String volunteerName;

    /**
     * 认领记录ID
     */
    private Long claimId;

    /**
     * 认领状态
     */
    private Byte claimStatus;

    /**
     * 超时时长（分钟）
     */
    private Long overtimeMinutes;

    /**
     * 评价星级（如有）
     */
    private Byte rating;

    private LocalDateTime claimedAt;

    private LocalDateTime completedAt;
}

