package com.community.platform.controller;

import com.community.platform.common.Result;
import com.community.platform.dto.InviteCodeVerifyRequest;
import com.community.platform.dto.InviteCodeVerifyVO;
import com.community.platform.dto.JoinCommunityRequest;
import com.community.platform.dto.UserInfo;
import com.community.platform.generated.entity.SysRegion;
import com.community.platform.generated.mapper.SysRegionMapper;
import com.community.platform.generated.mapper.SysUserMapper;
import com.community.platform.security.UserDetailsImpl;
import com.community.platform.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 移动端加入/改绑社区（邀请码/扫码，无审核）
 */
@RestController
@RequestMapping("/community")
public class CommunityJoinController {

    @Autowired
    private JdbcTemplate jdbcTemplate;
    @Autowired
    private SysRegionMapper sysRegionMapper;
    @Autowired
    private SysUserMapper sysUserMapper;
    @Autowired
    private AuthService authService;

    @PostMapping("/invite/verify")
    @PreAuthorize("hasRole('USER')")
    public Result<InviteCodeVerifyVO> verify(@Valid @RequestBody InviteCodeVerifyRequest request) {
        try {
            String code = normalizeCode(request.getCode());
            InviteRow row = loadValidInvite(code);
            if (row == null) {
                return Result.error("邀请码无效或已过期");
            }
            SysRegion region = sysRegionMapper.selectById(row.communityId);
            if (region == null) {
                return Result.error("邀请码对应社区不存在");
            }
            InviteCodeVerifyVO vo = new InviteCodeVerifyVO();
            vo.setCommunityId(row.communityId);
            vo.setCommunityName(region.getName());
            vo.setExpiresAt(row.expiresAt);
            vo.setMaxUses(row.maxUses);
            vo.setUsedCount(row.usedCount);
            return Result.success(vo);
        } catch (Exception e) {
            return Result.error("校验失败: " + e.getMessage());
        }
    }

    @PostMapping("/join")
    @PreAuthorize("hasRole('USER')")
    @Transactional
    public Result<UserInfo> join(@Valid @RequestBody JoinCommunityRequest request) {
        try {
            Long userId = getCurrentUserId();
            String code = normalizeCode(request.getCode());

            InviteRow row = loadValidInvite(code);
            if (row == null) {
                return Result.error("邀请码无效或已过期");
            }
            SysRegion region = sysRegionMapper.selectById(row.communityId);
            if (region == null) {
                return Result.error("邀请码对应社区不存在");
            }

            int inc = jdbcTemplate.update(
                    "UPDATE community_invite_code SET used_count=used_count+1, updated_at=NOW(3) " +
                            "WHERE id=? AND status=1 AND (expires_at IS NULL OR expires_at>NOW(3)) AND used_count < max_uses",
                    row.id
            );
            if (inc <= 0) {
                return Result.error("邀请码已被用尽或不可用");
            }

            // 改绑/绑定：直接覆盖 sys_user.community_id
            int updated = jdbcTemplate.update(
                    "UPDATE sys_user SET community_id=?, updated_at=NOW(3) WHERE id=? AND is_deleted=0",
                    row.communityId, userId
            );
            if (updated <= 0) {
                throw new RuntimeException("用户不存在或已被删除");
            }

            return Result.success("社区绑定成功", authService.getUserInfoById(userId));
        } catch (Exception e) {
            return Result.error("绑定失败: " + e.getMessage());
        }
    }

    private static String normalizeCode(String code) {
        return code == null ? "" : code.trim();
    }

    private InviteRow loadValidInvite(String code) {
        List<InviteRow> list = jdbcTemplate.query(
                "SELECT id, community_id, expires_at, max_uses, used_count " +
                        "FROM community_invite_code " +
                        "WHERE code=? AND status=1 AND (expires_at IS NULL OR expires_at>NOW(3)) AND used_count < max_uses " +
                        "LIMIT 1",
                (rs, rowNum) -> {
                    InviteRow r = new InviteRow();
                    r.id = rs.getLong("id");
                    r.communityId = rs.getLong("community_id");
                    Timestamp ts = rs.getTimestamp("expires_at");
                    r.expiresAt = ts == null ? null : ts.toLocalDateTime();
                    r.maxUses = rs.getInt("max_uses");
                    r.usedCount = rs.getInt("used_count");
                    return r;
                },
                code
        );
        return list.isEmpty() ? null : list.get(0);
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserDetailsImpl userDetails) {
            return userDetails.getUser().getId();
        }
        throw new RuntimeException("未登录");
    }

    private static class InviteRow {
        long id;
        long communityId;
        LocalDateTime expiresAt;
        int maxUses;
        int usedCount;
    }
}

