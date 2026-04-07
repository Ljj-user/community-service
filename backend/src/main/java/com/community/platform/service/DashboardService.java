package com.community.platform.service;

import com.community.platform.dto.AdminDashboardPanelVO;
import com.community.platform.dto.DashboardStatsVO;
import com.community.platform.dto.FundingMonitorVO;
import com.community.platform.dto.NameCountVO;
import com.community.platform.dto.RegionStatVO;
import com.community.platform.dto.ScheduleBriefVO;

import java.util.List;

/**
 * 数据看板服务接口
 */
public interface DashboardService {

    /**
     * 获取统计数据（管理员）
     */
    DashboardStatsVO getStats();

    /**
     * 按区域聚合的服务覆盖统计（用于热力图）
     */
    List<RegionStatVO> getRegionCoverage();

    /**
     * 按服务类型统计需求分布
     */
    List<NameCountVO> getDemandByServiceType();

    /**
     * 资金/物资监控占位（超级管理员）
     */
    FundingMonitorVO getFundingMonitorPlaceholder();

    /**
     * 近期期望服务时间的需求排期
     */
    List<ScheduleBriefVO> getUpcomingSchedule(int limit);

    /**
     * 管理员首页看板聚合（根据是否超管附带资金监控）
     */
    AdminDashboardPanelVO buildAdminPanel(boolean superAdmin);
}
