package com.community.platform.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.community.platform.dto.AuditLogListQuery;
import com.community.platform.dto.AuditLogVO;
import com.community.platform.dto.PageResult;
import com.community.platform.generated.entity.AuditLog;
import com.community.platform.generated.mapper.AuditLogMapper;
import com.community.platform.service.AdminAuditService;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 审计日志服务实现
 */
@Service
public class AdminAuditServiceImpl implements AdminAuditService {

    @Autowired
    private AuditLogMapper auditLogMapper;

    @Override
    public PageResult<AuditLogVO> list(AuditLogListQuery query) {
        int page = query.getPage() == null || query.getPage() < 1 ? 1 : query.getPage();
        int size = query.getSize() == null || query.getSize() < 1 ? 10 : query.getSize();

        LambdaQueryWrapper<AuditLog> wrapper = new LambdaQueryWrapper<>();
        if (query.getUsername() != null && !query.getUsername().isBlank()) {
            wrapper.like(AuditLog::getUsername, query.getUsername().trim());
        }
        if (query.getRole() != null) {
            wrapper.eq(AuditLog::getRole, query.getRole());
        }
        if (query.getModule() != null && !query.getModule().isBlank()) {
            wrapper.eq(AuditLog::getModule, query.getModule().trim());
        }
        if (query.getAction() != null && !query.getAction().isBlank()) {
            wrapper.like(AuditLog::getAction, query.getAction().trim());
        }
        if (query.getSuccess() != null) {
            wrapper.eq(AuditLog::getSuccess, query.getSuccess());
        }
        if (query.getRiskLevel() != null && !query.getRiskLevel().isBlank()) {
            wrapper.eq(AuditLog::getRiskLevel, query.getRiskLevel().trim());
        }
        if (query.getStartTime() != null && !query.getStartTime().isBlank()) {
            LocalDateTime start = parseDateTime(query.getStartTime());
            if (start != null) {
                wrapper.ge(AuditLog::getCreatedAt, start);
            }
        }
        if (query.getEndTime() != null && !query.getEndTime().isBlank()) {
            LocalDateTime end = parseDateTime(query.getEndTime());
            if (end != null) {
                wrapper.le(AuditLog::getCreatedAt, end);
            }
        }
        wrapper.orderByDesc(AuditLog::getCreatedAt);

        Page<AuditLog> p = auditLogMapper.selectPage(new Page<>(page, size), wrapper);
        List<AuditLogVO> records = p.getRecords().stream().map(this::toVO).collect(Collectors.toList());
        return PageResult.of(records, p.getTotal(), p.getCurrent(), p.getSize());
    }

    @Override
    public AuditLogVO getById(Long id) {
        AuditLog log = auditLogMapper.selectById(id);
        return log == null ? null : toVO(log);
    }

    @Override
    public void record(Long userId, String username, Byte role, String module, String action,
                       String requestPath, String httpMethod, boolean success, String resultMsg,
                       String riskLevel, String ip, String userAgent, Integer elapsedMs) {
        AuditLog log = new AuditLog();
        log.setUserId(userId);
        log.setUsername(username);
        log.setRole(role);
        log.setModule(module);
        log.setAction(action);
        log.setRequestPath(requestPath);
        log.setHttpMethod(httpMethod);
        log.setSuccess(success ? (byte) 1 : (byte) 0);
        log.setResultMsg(resultMsg);
        log.setRiskLevel(riskLevel != null ? riskLevel : "NORMAL");
        log.setIp(ip);
        log.setUserAgent(userAgent);
        log.setElapsedMs(elapsedMs);
        log.setCreatedAt(LocalDateTime.now());
        auditLogMapper.insert(log);
    }

    private AuditLogVO toVO(AuditLog e) {
        AuditLogVO vo = new AuditLogVO();
        BeanUtils.copyProperties(e, vo);
        return vo;
    }

    private static LocalDateTime parseDateTime(String iso) {
        if (iso == null || iso.isBlank()) return null;
        try {
            return LocalDateTime.parse(iso.replace("Z", "").substring(0, 19));
        } catch (DateTimeParseException e) {
            try {
                return LocalDateTime.parse(iso.substring(0, Math.min(19, iso.length())).replace("Z", ""));
            } catch (Exception ignored) {
                return null;
            }
        }
    }
}
