package com.community.platform.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class VerificationCodeTicketVO {
    private Long ticketId;
    private String scene;
    private String target;
    private LocalDateTime expiresAt;
    /** 演示环境返回验证码，生产可隐藏 */
    private String devCode;
}

