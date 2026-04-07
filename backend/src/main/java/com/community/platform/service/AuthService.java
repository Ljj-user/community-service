package com.community.platform.service;

import com.community.platform.dto.LoginRequest;
import com.community.platform.dto.LoginResponse;
import com.community.platform.dto.RegisterRequest;
import com.community.platform.dto.UserInfo;
import com.community.platform.dto.ChangePasswordRequest;

/**
 * 认证服务接口
 */
public interface AuthService {
    
    /**
     * 登录
     */
    LoginResponse login(LoginRequest request);
    
    /**
     * 注册
     */
    UserInfo register(RegisterRequest request);

    /**
     * 修改当前登录用户密码
     */
    void changePassword(ChangePasswordRequest request);

    /**
     * 按主键加载用户并转换为前端用户信息（含社区名称等扩展字段）
     */
    UserInfo getUserInfoById(Long userId);
}
