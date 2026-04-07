package com.community.platform.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 志愿者个人看板
 */
@Data
public class VolunteerDashboardVO {
    private BigDecimal totalServiceHours;
    private Long pendingClaimCount;
    private Long completedClaimCount;
    /** 居民对我评价的平均分（无则 null） */
    private BigDecimal averageRating;
    private Long evaluationCount;
    /** 最近参与的需求标题 */
    private List<String> recentProjectTitles;
    /** 荣誉/排名占位说明 */
    private String honorNote;
}
