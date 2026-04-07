package com.community.platform.controller;

import com.community.platform.common.Result;
import com.community.platform.dto.AdminDashboardPanelVO;
import com.community.platform.dto.DashboardStatsVO;
import com.community.platform.dto.RegionStatVO;
import com.community.platform.service.DashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 数据看板控制器
 */
@RestController
@RequestMapping("/dashboard")
public class DashboardController {

    @Autowired
    private DashboardService dashboardService;

    /**
     * 获取统计数据（管理员）
     */
    @GetMapping("/stats")
    @PreAuthorize("hasAnyRole('COMMUNITY_ADMIN', 'SUPER_ADMIN')")
    public Result<DashboardStatsVO> getStats() {
        try {
            DashboardStatsVO stats = dashboardService.getStats();
            return Result.success(stats);
        } catch (Exception e) {
            return Result.error("获取统计数据失败: " + e.getMessage());
        }
    }

    /**
     * 区域服务覆盖统计（用于全局数据看板热力图）
     */
    @GetMapping("/coverage-by-region")
    @PreAuthorize("hasAnyRole('COMMUNITY_ADMIN', 'SUPER_ADMIN')")
    public Result<List<RegionStatVO>> getRegionCoverage() {
        try {
            List<RegionStatVO> list = dashboardService.getRegionCoverage();
            return Result.success(list);
        } catch (Exception e) {
            return Result.error("获取区域覆盖数据失败: " + e.getMessage());
        }
    }

    /**
     * 管理员首页看板聚合（超管含资金/物资占位监控；社区管理员为辖区视角，当前与全库统计一致，后续可按社区维度过滤）
     */
    @GetMapping("/panel")
    @PreAuthorize("hasAnyRole('COMMUNITY_ADMIN', 'SUPER_ADMIN')")
    public Result<AdminDashboardPanelVO> panel() {
        try {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            boolean isSuper = auth != null && auth.getAuthorities().stream()
                    .anyMatch(a -> "ROLE_SUPER_ADMIN".equals(a.getAuthority()));
            AdminDashboardPanelVO vo = dashboardService.buildAdminPanel(isSuper);
            return Result.success(vo);
        } catch (Exception e) {
            return Result.error("获取看板数据失败: " + e.getMessage());
        }
    }
}
