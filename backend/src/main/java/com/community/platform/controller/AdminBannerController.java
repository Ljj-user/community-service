package com.community.platform.controller;

import com.community.platform.common.Constants;
import com.community.platform.common.Result;
import com.community.platform.dto.AdminBannerUpsertRequest;
import com.community.platform.dto.BannerVO;
import com.community.platform.security.UserDetailsImpl;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 管理端：轮播图管理（社区管理员/系统管理员）
 */
@RestController
@RequestMapping("/admin/banner")
public class AdminBannerController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/list")
    @PreAuthorize("hasAnyRole('COMMUNITY_ADMIN', 'SUPER_ADMIN')")
    public Result<List<BannerVO>> list(@RequestParam(value = "communityId", required = false) Long communityId) {
        try {
            Operator op = currentOperator();
            Long scope = resolveScope(op, communityId);
            return Result.success(query(scope));
        } catch (Exception e) {
            return Result.error("查询失败: " + e.getMessage());
        }
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('COMMUNITY_ADMIN', 'SUPER_ADMIN')")
    public Result<Void> upsert(@Valid @RequestBody AdminBannerUpsertRequest req) {
        try {
            Operator op = currentOperator();
            Long scope = resolveScope(op, req.getCommunityId());
            if (req.getId() == null) {
                jdbcTemplate.update(
                        "INSERT INTO community_banner(community_id,title,subtitle,image_url,link_url,sort_no,status,created_by,created_at,updated_at) " +
                                "VALUES(?,?,?,?,?,?,?, ?, NOW(3), NOW(3))",
                        scope, req.getTitle().trim(), trimOrNull(req.getSubtitle()),
                        trimOrNull(req.getImageUrl()), trimOrNull(req.getLinkUrl()),
                        req.getSortNo(), req.getStatus(), op.userId
                );
            } else {
                // 限制社区管理员只能改本社区 banner
                Integer cnt = jdbcTemplate.queryForObject(
                        "SELECT COUNT(1) FROM community_banner WHERE id=? AND ((? IS NULL AND community_id IS NULL) OR community_id=?)",
                        Integer.class, req.getId(), scope, scope
                );
                if (cnt == null || cnt <= 0) {
                    return Result.error("记录不存在或无权限");
                }
                jdbcTemplate.update(
                        "UPDATE community_banner SET title=?, subtitle=?, image_url=?, link_url=?, sort_no=?, status=?, updated_at=NOW(3) WHERE id=?",
                        req.getTitle().trim(), trimOrNull(req.getSubtitle()),
                        trimOrNull(req.getImageUrl()), trimOrNull(req.getLinkUrl()),
                        req.getSortNo(), req.getStatus(), req.getId()
                );
            }
            return Result.success("保存成功", null);
        } catch (Exception e) {
            return Result.error("保存失败: " + e.getMessage());
        }
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('COMMUNITY_ADMIN', 'SUPER_ADMIN')")
    public Result<Void> delete(@PathVariable("id") Long id, @RequestParam(value = "communityId", required = false) Long communityId) {
        try {
            Operator op = currentOperator();
            Long scope = resolveScope(op, communityId);
            Integer cnt = jdbcTemplate.queryForObject(
                    "SELECT COUNT(1) FROM community_banner WHERE id=? AND ((? IS NULL AND community_id IS NULL) OR community_id=?)",
                    Integer.class, id, scope, scope
            );
            if (cnt == null || cnt <= 0) {
                return Result.error("记录不存在或无权限");
            }
            jdbcTemplate.update("DELETE FROM community_banner WHERE id=?", id);
            return Result.success("删除成功", null);
        } catch (Exception e) {
            return Result.error("删除失败: " + e.getMessage());
        }
    }

    private List<BannerVO> query(Long scopeCommunityId) {
        return jdbcTemplate.query(
                "SELECT id,title,subtitle,image_url,link_url FROM community_banner " +
                        "WHERE ((? IS NULL AND community_id IS NULL) OR community_id=?) " +
                        "ORDER BY sort_no ASC, id ASC LIMIT 50",
                (rs, rowNum) -> {
                    BannerVO vo = new BannerVO();
                    vo.setId(rs.getLong("id"));
                    vo.setTitle(rs.getString("title"));
                    vo.setSubtitle(rs.getString("subtitle"));
                    vo.setImageUrl(rs.getString("image_url"));
                    vo.setLinkUrl(rs.getString("link_url"));
                    return vo;
                },
                scopeCommunityId, scopeCommunityId
        );
    }

    private static String trimOrNull(String v) {
        if (v == null) return null;
        String t = v.trim();
        return t.isEmpty() ? null : t;
    }

    private static Long resolveScope(Operator op, Long requested) {
        if (op.role != null && op.role == Constants.ROLE_COMMUNITY_ADMIN) {
            if (op.communityId == null) throw new RuntimeException("当前社区管理员未绑定社区");
            if (requested != null && !requested.equals(op.communityId)) {
                throw new RuntimeException("社区管理员只能管理本社区轮播图");
            }
            return op.communityId;
        }
        // 超管：requested 可为 null（全局默认）
        return requested;
    }

    private Operator currentOperator() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserDetailsImpl userDetails)) {
            throw new RuntimeException("未登录");
        }
        Operator op = new Operator();
        op.userId = userDetails.getUser().getId();
        op.role = userDetails.getUser().getRole();
        op.communityId = userDetails.getUser().getCommunityId();
        return op;
    }

    private static class Operator {
        Long userId;
        Byte role;
        Long communityId;
    }
}

