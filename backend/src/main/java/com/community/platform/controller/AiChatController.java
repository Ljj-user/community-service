package com.community.platform.controller;

import com.community.platform.common.Result;
import com.community.platform.dto.AiChatRequest;
import com.community.platform.dto.AiChatResponseVO;
import com.community.platform.service.impl.AiChatService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/ai")
public class AiChatController {

    @Autowired
    private AiChatService aiChatService;

    @PostMapping("/chat")
    @PreAuthorize("hasAnyRole('USER','COMMUNITY_ADMIN','SUPER_ADMIN')")
    public Result<AiChatResponseVO> chat(@Valid @RequestBody AiChatRequest request) {
        try {
            return Result.success(aiChatService.chat(request.getMessage(), request.getHistory()));
        } catch (Exception e) {
            return Result.error("AI 对话失败: " + e.getMessage());
        }
    }
}
