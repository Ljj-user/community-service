package com.community.platform.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.community.platform.common.Constants;
import com.community.platform.dto.LoginRequest;
import com.community.platform.dto.LoginResponse;
import com.community.platform.dto.RegisterRequest;
import com.community.platform.dto.UserInfo;
import com.community.platform.dto.ChangePasswordRequest;
import com.community.platform.generated.entity.SysRegion;
import com.community.platform.generated.entity.SysUser;
import com.community.platform.generated.mapper.SysRegionMapper;
import com.community.platform.generated.mapper.SysUserMapper;
import com.community.platform.security.UserDetailsImpl;
import com.community.platform.service.AuthService;
import com.community.platform.util.DefaultAvatarUtil;
import com.community.platform.util.IdentityTypeUtil;
import com.community.platform.util.MD5Util;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 认证服务实现
 */
@Service
public class AuthServiceImpl implements AuthService {
    
    @Autowired
    private SysUserMapper sysUserMapper;

    @Autowired
    private SysRegionMapper sysRegionMapper;
    
    @Autowired
    private AuthenticationManager authenticationManager;
    
    @Override
    public LoginResponse login(LoginRequest request) {
        // Spring Security 认证
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
        );
        
        SecurityContextHolder.getContext().setAuthentication(authentication);
        
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        SysUser user = userDetails.getUser();
        
        // 更新最后登录时间
        user.setLastLoginAt(LocalDateTime.now());
        sysUserMapper.updateById(user);
        
        // 生成 token
        String token = com.community.platform.security.JwtTokenUtil.generateToken(user.getUsername());
        
        // 转换为 UserInfo
        UserInfo userInfo = convertToUserInfo(user);
        
        LoginResponse response = new LoginResponse();
        response.setToken(token);
        response.setUserInfo(userInfo);
        
        return response;
    }
    
    @Override
    @Transactional
    public UserInfo register(RegisterRequest request) {
        // 检查用户名是否已存在
        LambdaQueryWrapper<SysUser> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysUser::getUsername, request.getUsername())
               .eq(SysUser::getIsDeleted, 0)
               .last("LIMIT 1");  // 确保只返回一条记录
        
        if (sysUserMapper.selectOne(wrapper) != null) {
            throw new RuntimeException("用户名已存在");
        }

        LambdaQueryWrapper<SysUser> phoneW = new LambdaQueryWrapper<>();
        phoneW.eq(SysUser::getPhone, request.getPhone())
                .eq(SysUser::getIsDeleted, 0)
                .last("LIMIT 1");
        if (sysUserMapper.selectOne(phoneW) != null) {
            throw new RuntimeException("手机号已被注册");
        }
        
        // 创建新用户
        SysUser user = new SysUser();
        user.setUsername(request.getUsername());
        user.setPasswordMd5(MD5Util.encrypt(request.getPassword()));
        user.setRealName(request.getRealName());
        user.setPhone(request.getPhone());
        user.setEmail(request.getEmail());
        // 注册只允许创建“普通用户”，禁止前端/接口参数越权注册管理员
        user.setRole(Constants.ROLE_NORMAL_USER);
        user.setIdentityType(IdentityTypeUtil.normalize(request.getIdentityType()));
        if (request.getCommunityId() != null) {
            SysRegion region = sysRegionMapper.selectById(request.getCommunityId());
            if (region == null) {
                throw new RuntimeException("所选社区不存在，community_id 必须对应 sys_region.id");
            }
            user.setCommunityId(request.getCommunityId());
        } else {
            user.setCommunityId(null);
        }
        user.setTimeCoins(0L);
        user.setPoints(0L);
        Byte g = request.getGender();
        if (g == null || g < 0 || g > 2) {
            g = (byte) 0;
        }
        user.setGender(g);
        user.setAvatarUrl(DefaultAvatarUtil.resolve(g));
        user.setStatus(Constants.USER_STATUS_ENABLED);
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        user.setIsDeleted((byte) 0);
        
        sysUserMapper.insert(user);
        SysUser persisted = sysUserMapper.selectById(user.getId());
        return convertToUserInfo(persisted != null ? persisted : user);
    }

    @Override
    public void changePassword(ChangePasswordRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserDetailsImpl)) {
            throw new RuntimeException("未登录");
        }

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        SysUser user = sysUserMapper.selectById(userDetails.getUser().getId());
        if (user == null) {
            throw new RuntimeException("用户不存在");
        }

        // 校验旧密码（MD5）
        boolean match = MD5Util.verify(request.getOldPassword(), user.getPasswordMd5());
        if (!match) {
            throw new RuntimeException("旧密码不正确");
        }

        // 更新新密码
        user.setPasswordMd5(MD5Util.encrypt(request.getNewPassword()));
        user.setUpdatedAt(LocalDateTime.now());
        sysUserMapper.updateById(user);
    }

    @Override
    public UserInfo getUserInfoById(Long userId) {
        SysUser user = sysUserMapper.selectById(userId);
        if (user == null || (user.getIsDeleted() != null && user.getIsDeleted() != 0)) {
            throw new RuntimeException("用户不存在");
        }
        return convertToUserInfo(user);
    }

    /**
     * 转换为 UserInfo DTO（身份字段归一化，避免历史脏数据）
     */
    private UserInfo convertToUserInfo(SysUser user) {
        UserInfo userInfo = new UserInfo();
        BeanUtils.copyProperties(user, userInfo);
        if (user.getRole() != null && user.getRole().equals(Constants.ROLE_NORMAL_USER)) {
            userInfo.setIdentityType(IdentityTypeUtil.normalize(user.getIdentityType()));
        }
        if (user.getCommunityId() != null) {
            SysRegion region = sysRegionMapper.selectById(user.getCommunityId());
            if (region != null) {
                userInfo.setCommunityName(region.getName());
            }
        }
        return userInfo;
    }
}
