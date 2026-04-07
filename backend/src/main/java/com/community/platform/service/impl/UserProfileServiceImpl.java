package com.community.platform.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.community.platform.dto.UserProfileResponse;
import com.community.platform.dto.UserProfileUpdateRequest;
import com.community.platform.generated.entity.SysRegion;
import com.community.platform.generated.entity.SysUser;
import com.community.platform.generated.mapper.SysRegionMapper;
import com.community.platform.generated.mapper.SysUserMapper;
import com.community.platform.security.UserDetailsImpl;
import com.community.platform.common.Constants;
import com.community.platform.service.UserProfileService;
import com.community.platform.util.DefaultAvatarUtil;
import com.community.platform.util.IdentityTypeUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class UserProfileServiceImpl implements UserProfileService {

    @Autowired
    private SysUserMapper sysUserMapper;

    @Autowired
    private SysRegionMapper sysRegionMapper;

    private SysUser getCurrentSysUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserDetailsImpl)) {
            throw new RuntimeException("未登录");
        }
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        SysUser user = userDetails.getUser();
        return sysUserMapper.selectById(user.getId());
    }

    private UserProfileResponse convertToResponse(SysUser user) {
        UserProfileResponse resp = new UserProfileResponse();
        if (user == null) {
            return resp;
        }
        resp.setId(user.getId());
        resp.setUsername(user.getUsername());
        resp.setRealName(user.getRealName());
        resp.setPhone(user.getPhone());
        resp.setEmail(user.getEmail());
        resp.setAvatarUrl(user.getAvatarUrl());
        resp.setRole(user.getRole());
        if (user.getRole() != null && user.getRole().equals(Constants.ROLE_NORMAL_USER)) {
            resp.setIdentityType(IdentityTypeUtil.normalize(user.getIdentityType()));
        } else {
            resp.setIdentityType(user.getIdentityType());
        }
        resp.setCommunityId(user.getCommunityId());
        if (user.getCommunityId() != null) {
            SysRegion region = sysRegionMapper.selectById(user.getCommunityId());
            if (region != null) {
                resp.setCommunityName(region.getName());
            }
        }
        resp.setTimeCoins(user.getTimeCoins());
        resp.setPoints(user.getPoints());
        resp.setIdentityTag(user.getIdentityTag());
        resp.setAddress(user.getAddress());
        resp.setGender(user.getGender());
        resp.setSkillTags(user.getSkillTags());
        resp.setCreatedAt(user.getCreatedAt());
        return resp;
    }

    @Override
    public UserProfileResponse getCurrentUserProfile() {
        SysUser user = getCurrentSysUser();
        return convertToResponse(user);
    }

    @Override
    public UserProfileResponse updateCurrentUserProfile(UserProfileUpdateRequest request) {
        SysUser user = getCurrentSysUser();
        if (request.getUsername() != null && !request.getUsername().isBlank()) {
            String nu = request.getUsername().trim();
            if (!nu.equals(user.getUsername())) {
                if (nu.length() < 2 || nu.length() > 64) {
                    throw new RuntimeException("用户名长度为 2-64 个字符");
                }
                LambdaQueryWrapper<SysUser> uw = new LambdaQueryWrapper<>();
                uw.eq(SysUser::getUsername, nu).eq(SysUser::getIsDeleted, 0);
                if (sysUserMapper.selectOne(uw) != null) {
                    throw new RuntimeException("用户名已存在");
                }
                user.setUsername(nu);
            }
        }
        if (request.getRealName() != null) {
            user.setRealName(request.getRealName());
        }
        if (request.getPhone() != null) {
            String p = request.getPhone().trim();
            if (!p.equals(user.getPhone() == null ? "" : user.getPhone())) {
                if (!p.isEmpty()) {
                    LambdaQueryWrapper<SysUser> pw = new LambdaQueryWrapper<>();
                    pw.eq(SysUser::getPhone, p).eq(SysUser::getIsDeleted, 0).ne(SysUser::getId, user.getId());
                    if (sysUserMapper.selectOne(pw) != null) {
                        throw new RuntimeException("手机号已被使用");
                    }
                }
            }
            user.setPhone(p);
        }
        if (request.getEmail() != null) {
            user.setEmail(request.getEmail());
        }
        if (request.getAvatarUrl() != null) {
            user.setAvatarUrl(request.getAvatarUrl());
        }
        if (request.getAddress() != null) {
            user.setAddress(request.getAddress());
        }
        if (request.getCommunityId() != null) {
            SysRegion region = sysRegionMapper.selectById(request.getCommunityId());
            if (region == null) {
                throw new RuntimeException("社区/区域不存在，请从可用的 sys_region 列表中选择");
            }
            user.setCommunityId(request.getCommunityId());
        }
        if (request.getGender() != null) {
            Byte g = request.getGender();
            if (g < 0 || g > 2) {
                throw new RuntimeException("性别参数无效");
            }
            if (!java.util.Objects.equals(user.getGender(), g)) {
                user.setGender(g);
                if (DefaultAvatarUtil.isBundledDefaultPath(user.getAvatarUrl())) {
                    user.setAvatarUrl(DefaultAvatarUtil.resolve(g));
                }
            }
        }
        if (request.getSkillTags() != null
                && user.getRole() != null
                && user.getRole().equals(Constants.ROLE_NORMAL_USER)
                && IdentityTypeUtil.normalize(user.getIdentityType()).equals(Constants.IDENTITY_VOLUNTEER)) {
            user.setSkillTags(request.getSkillTags());
        }
        if (request.getIdentityTag() != null) {
            user.setIdentityTag(request.getIdentityTag());
        }
        user.setUpdatedAt(java.time.LocalDateTime.now());
        sysUserMapper.updateById(user);
        return convertToResponse(sysUserMapper.selectById(user.getId()));
    }

    @Override
    public UserProfileResponse updateAvatar(String avatarUrl) {
        SysUser user = getCurrentSysUser();
        user.setAvatarUrl(avatarUrl);
        sysUserMapper.updateById(user);
        return convertToResponse(user);
    }
}

