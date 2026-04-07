package com.community.platform.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 数据看板统计 VO
 */
@Data
public class DashboardStatsVO {
    /**
     * 总需求数
     */
    private Long totalRequests;
    
    /**
     * 待审核需求数
     */
    private Long pendingRequests;
    
    /**
     * 已发布需求数
     */
    private Long publishedRequests;
    
    /**
     * 已完成需求数
     */
    private Long completedRequests;
    
    /**
     * 总服务时长（小时）
     */
    private BigDecimal totalServiceHours;
    
    /**
     * 活跃志愿者数
     */
    private Long activeVolunteers;
    
    /**
     * 本月新增需求数
     */
    private Long monthlyNewRequests;
    
    /**
     * 本月完成需求数
     */
    private Long monthlyCompletedRequests;

    /**
     * 需求对接率（completedRequests / totalRequests，0-1 之间的小数）
     */
    private BigDecimal matchRate;

    /**
     * 服务覆盖率（活跃志愿者数 / 有效志愿者总数，0-1 之间的小数）
     */
    private BigDecimal coverageRate;
}
