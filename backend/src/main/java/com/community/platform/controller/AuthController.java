package com.community.platform.controller;

import com.community.platform.common.Result;
import com.community.platform.dto.LoginRequest;
import com.community.platform.dto.LoginResponse;
import com.community.platform.dto.RegisterRequest;
import com.community.platform.dto.UserInfo;
import com.community.platform.dto.ChangePasswordRequest;
import com.community.platform.security.UserDetailsImpl;
import com.community.platform.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

/**
 * 认证控制器（登录/注册）
 */
@RestController
@RequestMapping("/auth")
public class AuthController {
    
    @Autowired
    private AuthService authService;
    
    /**
     * 登录
     */
    @PostMapping("/login")
    public Result<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            LoginResponse response = authService.login(request);
            return Result.success("登录成功", response);
        } catch (Exception e) {
            return Result.error("登录失败: " + e.getMessage());
        }
    }
    
    /**
     * 注册
     */
    @PostMapping("/register")
    public Result<UserInfo> register(@Valid @RequestBody RegisterRequest request) {
        try {
            UserInfo userInfo = authService.register(request);
            return Result.success("注册成功", userInfo);
        } catch (Exception e) {
            return Result.error("注册失败: " + e.getMessage());
        }
    }
    
    /**
     * 获取当前用户信息
     */
    @GetMapping("/me")
    public Result<UserInfo> getCurrentUser() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication == null || !(authentication.getPrincipal() instanceof UserDetailsImpl)) {
                return Result.error(401, "未登录");
            }
            
            UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
            UserInfo userInfo = authService.getUserInfoById(userDetails.getUser().getId());

            return Result.success(userInfo);
        } catch (Exception e) {
            return Result.error("获取用户信息失败: " + e.getMessage());
        }
    }

    /**
     * 修改当前登录用户密码
     */
    @PostMapping("/change-password")
    public Result<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        try {
            authService.changePassword(request);
            return Result.success("密码修改成功", null);
        } catch (Exception e) {
            return Result.error("修改密码失败: " + e.getMessage());
        }
    }
}
