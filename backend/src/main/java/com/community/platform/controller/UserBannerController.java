package com.community.platform.controller;

import com.community.platform.common.Result;
import com.community.platform.dto.BannerVO;
import com.community.platform.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 普通用户：首页轮播图（按社区下发）
 */
@RestController
@RequestMapping("/user/banner")
public class UserBannerController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/list")
    @PreAuthorize("hasRole('USER')")
    public Result<List<BannerVO>> list() {
        try {
            Long userId = getCurrentUserId();
            Long communityId = jdbcTemplate.queryForObject("SELECT community_id FROM sys_user WHERE id=? LIMIT 1", Long.class, userId);

            List<BannerVO> scoped = queryBanners(communityId);
            if (!scoped.isEmpty()) {
                return Result.success(scoped);
            }
            return Result.success(queryBanners(null));
        } catch (Exception e) {
            return Result.error("获取轮播图失败: " + e.getMessage());
        }
    }

    private List<BannerVO> queryBanners(Long communityId) {
        return jdbcTemplate.query(
                "SELECT id,title,subtitle,image_url,link_url " +
                        "FROM community_banner " +
                        "WHERE status=1 AND ((? IS NULL AND community_id IS NULL) OR community_id=?) " +
                        "ORDER BY sort_no ASC, id ASC LIMIT 10",
                (rs, rowNum) -> {
                    BannerVO vo = new BannerVO();
                    vo.setId(rs.getLong("id"));
                    vo.setTitle(rs.getString("title"));
                    vo.setSubtitle(rs.getString("subtitle"));
                    vo.setImageUrl(rs.getString("image_url"));
                    vo.setLinkUrl(rs.getString("link_url"));
                    return vo;
                },
                communityId, communityId
        );
    }

    private Long getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserDetailsImpl userDetails) {
            return userDetails.getUser().getId();
        }
        throw new RuntimeException("未登录");
    }
}

