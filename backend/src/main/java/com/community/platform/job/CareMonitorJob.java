package com.community.platform.job;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.community.platform.common.Constants;
import com.community.platform.generated.entity.SysNotification;
import com.community.platform.generated.entity.SysUser;
import com.community.platform.generated.mapper.SysNotificationMapper;
import com.community.platform.generated.mapper.SysUserMapper;
import com.community.platform.util.SubsidyUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 主动关怀监测：连续 3 天未登录且 identity_tag 含“孤寡老人”的用户 -> 推送给社区管理员
 */
@Component
public class CareMonitorJob {

    @Autowired
    private SysUserMapper sysUserMapper;

    @Autowired
    private SysNotificationMapper sysNotificationMapper;

    /**
     * 每 6 小时检查一次（开发态更容易看到效果）
     */
    @Scheduled(fixedDelay = 6 * 60 * 60 * 1000L, initialDelay = 60 * 1000L)
    public void run() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(3);

        LambdaQueryWrapper<SysUser> w = new LambdaQueryWrapper<>();
        w.eq(SysUser::getIsDeleted, 0)
                .eq(SysUser::getStatus, Constants.USER_STATUS_ENABLED)
                .eq(SysUser::getRole, Constants.ROLE_NORMAL_USER)
                .isNotNull(SysUser::getCommunityId)
                .lt(SysUser::getLastLoginAt, cutoff);

        List<SysUser> candidates = sysUserMapper.selectList(w).stream()
                .filter(u -> SubsidyUtil.isSubsidized(u.getIdentityTag()) && (u.getIdentityTag() != null && u.getIdentityTag().contains("孤寡老人")))
                .toList();

        if (candidates.isEmpty()) {
            return;
        }

        Map<Long, Long> communityToCount = new HashMap<>();
        for (SysUser u : candidates) {
            if (u.getCommunityId() == null) continue;
            communityToCount.merge(u.getCommunityId(), 1L, Long::sum);
        }

        LocalDate today = LocalDate.now();
        LocalDateTime todayStart = today.atStartOfDay();

        for (Map.Entry<Long, Long> e : communityToCount.entrySet()) {
            Long communityId = e.getKey();
            Long cnt = e.getValue();

            // 找本社区管理员
            LambdaQueryWrapper<SysUser> aw = new LambdaQueryWrapper<>();
            aw.eq(SysUser::getIsDeleted, 0)
                    .eq(SysUser::getStatus, Constants.USER_STATUS_ENABLED)
                    .eq(SysUser::getRole, Constants.ROLE_COMMUNITY_ADMIN)
                    .eq(SysUser::getCommunityId, communityId);
            List<SysUser> admins = sysUserMapper.selectList(aw);
            if (admins.isEmpty()) continue;

            for (SysUser admin : admins) {
                // 当天去重：同社区只发一条 CARE_ALERT
                LambdaQueryWrapper<SysNotification> nw = new LambdaQueryWrapper<>();
                nw.eq(SysNotification::getRecipientUserId, admin.getId())
                        .eq(SysNotification::getRefType, Constants.NOTIF_REF_CARE_ALERT)
                        .eq(SysNotification::getRefId, communityId)
                        .ge(SysNotification::getCreatedAt, todayStart)
                        .last("LIMIT 1");
                if (sysNotificationMapper.selectOne(nw) != null) {
                    continue;
                }

                SysNotification n = new SysNotification();
                n.setRecipientUserId(admin.getId());
                n.setMsgCategory(Constants.NOTIFICATION_CATEGORY_BUSINESS);
                n.setReadStatus(Constants.NOTIFICATION_UNREAD);
                n.setRefType(Constants.NOTIF_REF_CARE_ALERT);
                n.setRefId(communityId);
                n.setTitle("关怀预警：孤寡老人久未登录");
                n.setSummary("该社区有 " + cnt + " 位“孤寡老人”连续 3 天未登录，建议主动电话关怀或上门核实。");
                n.setCreatedAt(LocalDateTime.now());
                sysNotificationMapper.insert(n);
            }
        }
    }
}

