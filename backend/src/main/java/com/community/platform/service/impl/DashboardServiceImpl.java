package com.community.platform.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.community.platform.common.Constants;
import com.community.platform.dto.AdminDashboardPanelVO;
import com.community.platform.dto.DashboardStatsVO;
import com.community.platform.dto.FundingMonitorVO;
import com.community.platform.dto.NameCountVO;
import com.community.platform.dto.RegionStatVO;
import com.community.platform.dto.ScheduleBriefVO;
import com.community.platform.generated.entity.ServiceClaim;
import com.community.platform.generated.entity.ServiceRequest;
import com.community.platform.generated.entity.SysUser;
import com.community.platform.generated.mapper.ServiceClaimMapper;
import com.community.platform.generated.mapper.ServiceRequestMapper;
import com.community.platform.generated.mapper.SysUserMapper;
import com.community.platform.service.DashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 数据看板服务实现
 */
@Service
public class DashboardServiceImpl implements DashboardService {
    
    @Autowired
    private ServiceRequestMapper serviceRequestMapper;
    
    @Autowired
    private ServiceClaimMapper serviceClaimMapper;
    
    @Autowired
    private SysUserMapper sysUserMapper;
    
    @Override
    public DashboardStatsVO getStats() {
        DashboardStatsVO stats = new DashboardStatsVO();
        
        try {
            // 总需求数
            Long totalRequests = serviceRequestMapper.selectCount(
                    new LambdaQueryWrapper<ServiceRequest>()
                            .eq(ServiceRequest::getIsDeleted, 0)
            );
            stats.setTotalRequests(totalRequests != null ? totalRequests : 0L);
        
            // 待审核需求数
            Long pendingRequests = serviceRequestMapper.selectCount(
                    new LambdaQueryWrapper<ServiceRequest>()
                            .eq(ServiceRequest::getIsDeleted, 0)
                            .eq(ServiceRequest::getStatus, Constants.REQUEST_STATUS_PENDING)
            );
            stats.setPendingRequests(pendingRequests != null ? pendingRequests : 0L);
            
            // 已发布需求数
            Long publishedRequests = serviceRequestMapper.selectCount(
                    new LambdaQueryWrapper<ServiceRequest>()
                            .eq(ServiceRequest::getIsDeleted, 0)
                            .eq(ServiceRequest::getStatus, Constants.REQUEST_STATUS_PUBLISHED)
            );
            stats.setPublishedRequests(publishedRequests != null ? publishedRequests : 0L);
            
            // 已完成需求数
            Long completedRequests = serviceRequestMapper.selectCount(
                    new LambdaQueryWrapper<ServiceRequest>()
                            .eq(ServiceRequest::getIsDeleted, 0)
                            .eq(ServiceRequest::getStatus, Constants.REQUEST_STATUS_COMPLETED)
            );
            stats.setCompletedRequests(completedRequests != null ? completedRequests : 0L);
            
            // 总服务时长
            BigDecimal totalServiceHours = serviceClaimMapper.selectList(
                    new LambdaQueryWrapper<ServiceClaim>()
                            .eq(ServiceClaim::getIsDeleted, 0)
                            .eq(ServiceClaim::getClaimStatus, Constants.CLAIM_STATUS_COMPLETED)
                            .isNotNull(ServiceClaim::getServiceHours)
            ).stream()
                    .map(ServiceClaim::getServiceHours)
                    .filter(hours -> hours != null)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            stats.setTotalServiceHours(totalServiceHours != null ? totalServiceHours : BigDecimal.ZERO);
            
            // 活跃志愿者数（有完成记录的志愿者）
            // 由于 MyBatis-Plus 的 selectCount 不支持 groupBy，使用 distinct 查询
            Long activeVolunteers = (long) serviceClaimMapper.selectList(
                    new LambdaQueryWrapper<ServiceClaim>()
                            .eq(ServiceClaim::getIsDeleted, 0)
                            .eq(ServiceClaim::getClaimStatus, Constants.CLAIM_STATUS_COMPLETED)
                            .select(ServiceClaim::getVolunteerUserId)
            ).stream()
                    .map(ServiceClaim::getVolunteerUserId)
                    .filter(userId -> userId != null)
                    .distinct()
                    .count();
            stats.setActiveVolunteers(activeVolunteers != null ? activeVolunteers : 0L);
            
            // 本月新增需求数
            YearMonth currentMonth = YearMonth.now();
            LocalDateTime monthStart = currentMonth.atDay(1).atStartOfDay();
            LocalDateTime monthEnd = currentMonth.atEndOfMonth().atTime(23, 59, 59, 999000000);
            
            Long monthlyNewRequests = serviceRequestMapper.selectCount(
                    new LambdaQueryWrapper<ServiceRequest>()
                            .eq(ServiceRequest::getIsDeleted, 0)
                            .between(ServiceRequest::getCreatedAt, monthStart, monthEnd)
            );
            stats.setMonthlyNewRequests(monthlyNewRequests != null ? monthlyNewRequests : 0L);
            
            // 本月完成需求数（需要同时满足：状态为已完成，且完成时间在本月）
            Long monthlyCompletedRequests = serviceRequestMapper.selectCount(
                    new LambdaQueryWrapper<ServiceRequest>()
                            .eq(ServiceRequest::getIsDeleted, 0)
                            .eq(ServiceRequest::getStatus, Constants.REQUEST_STATUS_COMPLETED)
                            .isNotNull(ServiceRequest::getCompletedAt)
                            .between(ServiceRequest::getCompletedAt, monthStart, monthEnd)
            );
            stats.setMonthlyCompletedRequests(monthlyCompletedRequests != null ? monthlyCompletedRequests : 0L);

            // 需求对接率 = 已完成需求数 / 总需求数
            if (stats.getTotalRequests() != null && stats.getTotalRequests() > 0) {
                BigDecimal matchRate = BigDecimal.valueOf(stats.getCompletedRequests())
                        .divide(BigDecimal.valueOf(stats.getTotalRequests()), 4, BigDecimal.ROUND_HALF_UP);
                stats.setMatchRate(matchRate);
            } else {
                stats.setMatchRate(BigDecimal.ZERO);
            }

            // 服务覆盖率 = 活跃志愿者数 / 有效志愿者总数（role=3 且 identity=志愿者，且启用）
            Long totalVolunteers = sysUserMapper.selectCount(
                    new LambdaQueryWrapper<SysUser>()
                            .eq(SysUser::getIsDeleted, 0)
                            .eq(SysUser::getRole, Constants.ROLE_NORMAL_USER)
                            .eq(SysUser::getIdentityType, Constants.IDENTITY_VOLUNTEER)
                            .eq(SysUser::getStatus, 1)
            );
            if (totalVolunteers != null && totalVolunteers > 0) {
                BigDecimal coverageRate = BigDecimal.valueOf(stats.getActiveVolunteers())
                        .divide(BigDecimal.valueOf(totalVolunteers), 4, BigDecimal.ROUND_HALF_UP);
                stats.setCoverageRate(coverageRate);
            } else {
                stats.setCoverageRate(BigDecimal.ZERO);
            }
            
            return stats;
        } catch (Exception e) {
            // 记录异常并返回默认值，避免整个接口失败
            e.printStackTrace();
            // 返回部分数据，至少保证接口能正常返回
            if (stats.getTotalRequests() == null) {
                stats.setTotalRequests(0L);
            }
            if (stats.getPendingRequests() == null) {
                stats.setPendingRequests(0L);
            }
            if (stats.getPublishedRequests() == null) {
                stats.setPublishedRequests(0L);
            }
            if (stats.getCompletedRequests() == null) {
                stats.setCompletedRequests(0L);
            }
            if (stats.getTotalServiceHours() == null) {
                stats.setTotalServiceHours(BigDecimal.ZERO);
            }
            if (stats.getActiveVolunteers() == null) {
                stats.setActiveVolunteers(0L);
            }
            if (stats.getMonthlyNewRequests() == null) {
                stats.setMonthlyNewRequests(0L);
            }
            if (stats.getMonthlyCompletedRequests() == null) {
                stats.setMonthlyCompletedRequests(0L);
            }
            throw new RuntimeException("获取统计数据时发生错误: " + e.getMessage(), e);
        }
    }

    @Override
    public List<RegionStatVO> getRegionCoverage() {
        // 目前数据库中尚无明确的区域编码字段，这里先返回一个简单的示例数据：
        // 将所有已完成的服务视为同一“区域” CN，用于驱动前端热力图展示。
        Long completedRequests = serviceRequestMapper.selectCount(
                new LambdaQueryWrapper<ServiceRequest>()
                        .eq(ServiceRequest::getIsDeleted, 0)
                        .eq(ServiceRequest::getStatus, Constants.REQUEST_STATUS_COMPLETED)
        );
        RegionStatVO vo = new RegionStatVO();
        vo.setRegionCode("CN");
        vo.setServiceCount(completedRequests != null ? completedRequests : 0L);
        List<RegionStatVO> list = new ArrayList<>();
        list.add(vo);
        return list;
    }

    @Override
    public List<NameCountVO> getDemandByServiceType() {
        List<ServiceRequest> list = serviceRequestMapper.selectList(
                new LambdaQueryWrapper<ServiceRequest>()
                        .eq(ServiceRequest::getIsDeleted, 0)
                        .select(ServiceRequest::getServiceType));
        Map<String, Long> grouped = list.stream()
                .map(ServiceRequest::getServiceType)
                .map(t -> t == null || t.isBlank() ? "其他" : t)
                .collect(Collectors.groupingBy(t -> t, Collectors.counting()));
        return grouped.entrySet().stream()
                .map(e -> {
                    NameCountVO vo = new NameCountVO();
                    vo.setName(e.getKey());
                    vo.setCount(e.getValue());
                    return vo;
                })
                .sorted(Comparator.comparingLong(NameCountVO::getCount).reversed())
                .toList();
    }

    @Override
    public FundingMonitorVO getFundingMonitorPlaceholder() {
        FundingMonitorVO vo = new FundingMonitorVO();
        vo.setFundIn(BigDecimal.ZERO);
        vo.setFundOut(BigDecimal.ZERO);
        vo.setMaterialIn(BigDecimal.ZERO);
        vo.setMaterialOut(BigDecimal.ZERO);
        vo.setNote("演示占位：后续可对接财务/物资子系统，汇总捐赠与物资流转。");
        return vo;
    }

    @Override
    public List<ScheduleBriefVO> getUpcomingSchedule(int limit) {
        List<ServiceRequest> rows = serviceRequestMapper.selectList(
                new LambdaQueryWrapper<ServiceRequest>()
                        .eq(ServiceRequest::getIsDeleted, 0)
                        .isNotNull(ServiceRequest::getExpectedTime)
                        .ge(ServiceRequest::getExpectedTime, LocalDateTime.now())
                        .in(ServiceRequest::getStatus, Arrays.asList(
                                Constants.REQUEST_STATUS_PENDING,
                                Constants.REQUEST_STATUS_PUBLISHED,
                                Constants.REQUEST_STATUS_CLAIMED))
                        .orderByAsc(ServiceRequest::getExpectedTime)
                        .last("LIMIT " + Math.max(1, Math.min(limit, 50))));
        List<ScheduleBriefVO> out = new ArrayList<>();
        for (ServiceRequest r : rows) {
            ScheduleBriefVO vo = new ScheduleBriefVO();
            vo.setId(r.getId());
            vo.setServiceType(r.getServiceType());
            vo.setExpectedTime(r.getExpectedTime());
            vo.setServiceAddress(r.getServiceAddress());
            vo.setStatus(r.getStatus() != null ? r.getStatus().intValue() : null);
            out.add(vo);
        }
        return out;
    }

    @Override
    public AdminDashboardPanelVO buildAdminPanel(boolean superAdmin) {
        AdminDashboardPanelVO vo = new AdminDashboardPanelVO();
        vo.setScope(superAdmin ? "SUPER_ADMIN" : "COMMUNITY_ADMIN");
        vo.setStats(getStats());
        vo.setRegionCoverage(getRegionCoverage());
        vo.setDemandByServiceType(getDemandByServiceType());
        vo.setUpcomingSchedule(getUpcomingSchedule(12));
        if (superAdmin) {
            vo.setFundingMonitor(getFundingMonitorPlaceholder());
        }
        return vo;
    }
}
