package com.community.platform.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.community.platform.generated.entity.AuditLog;
import com.community.platform.generated.entity.ServiceRequest;
import com.community.platform.generated.entity.SysUser;
import com.community.platform.generated.mapper.AuditLogMapper;
import com.community.platform.generated.mapper.ServiceRequestMapper;
import com.community.platform.generated.mapper.SysUserMapper;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * 超级管理员：数据导出（简化版：先输出 CSV）
 */
@RestController
@RequestMapping("/admin/export")
public class AdminExportController {

    @Autowired
    private ServiceRequestMapper serviceRequestMapper;

    @Autowired
    private SysUserMapper sysUserMapper;

    @Autowired
    private AuditLogMapper auditLogMapper;

    @GetMapping("/{module}")
    public void export(@PathVariable("module") String module,
                       String format,
                       String startTime,
                       String endTime,
                       HttpServletResponse response) throws IOException {
        // 目前仅支持 csv（前端可用 excel 格式请求，后端会以 CSV 返回）
        String ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String filename = module + "-" + ts + ".csv";

        response.setCharacterEncoding("UTF-8");
        response.setContentType("text/csv;charset=UTF-8");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + urlEncode(filename) + "\"");

        String csv;
        if ("service_request".equalsIgnoreCase(module)) {
            csv = exportServiceRequest(startTime, endTime);
        } else if ("users".equalsIgnoreCase(module)) {
            csv = exportUsers(startTime, endTime);
        } else if ("audit".equalsIgnoreCase(module)) {
            csv = exportAudit(startTime, endTime);
        } else {
            csv = "error,unknown_module\n";
        }

        response.getWriter().write("\uFEFF"); // BOM for Excel
        response.getWriter().write(csv);
        response.getWriter().flush();
    }

    private String exportServiceRequest(String startTime, String endTime) {
        LambdaQueryWrapper<ServiceRequest> w = new LambdaQueryWrapper<>();
        w.eq(ServiceRequest::getIsDeleted, 0);
        applyTimeRange(w, ServiceRequest::getCreatedAt, startTime, endTime);
        w.orderByDesc(ServiceRequest::getCreatedAt);
        List<ServiceRequest> list = serviceRequestMapper.selectList(w);

        StringBuilder sb = new StringBuilder();
        sb.append("id,requesterUserId,serviceType,serviceAddress,urgencyLevel,status,createdAt\n");
        for (ServiceRequest r : list) {
            sb.append(n(r.getId())).append(',')
                    .append(n(r.getRequesterUserId())).append(',')
                    .append(q(r.getServiceType())).append(',')
                    .append(q(r.getServiceAddress())).append(',')
                    .append(n(r.getUrgencyLevel())).append(',')
                    .append(n(r.getStatus())).append(',')
                    .append(q(String.valueOf(r.getCreatedAt())))
                    .append('\n');
        }
        return sb.toString();
    }

    private String exportUsers(String startTime, String endTime) {
        LambdaQueryWrapper<SysUser> w = new LambdaQueryWrapper<>();
        w.eq(SysUser::getIsDeleted, 0);
        applyTimeRange(w, SysUser::getCreatedAt, startTime, endTime);
        w.orderByDesc(SysUser::getCreatedAt);
        List<SysUser> list = sysUserMapper.selectList(w);

        StringBuilder sb = new StringBuilder();
        sb.append("id,username,role,identityType,realName,phone,email,status,createdAt\n");
        for (SysUser u : list) {
            sb.append(n(u.getId())).append(',')
                    .append(q(u.getUsername())).append(',')
                    .append(n(u.getRole())).append(',')
                    .append(n(u.getIdentityType())).append(',')
                    .append(q(u.getRealName())).append(',')
                    .append(q(u.getPhone())).append(',')
                    .append(q(u.getEmail())).append(',')
                    .append(n(u.getStatus())).append(',')
                    .append(q(String.valueOf(u.getCreatedAt())))
                    .append('\n');
        }
        return sb.toString();
    }

    private String exportAudit(String startTime, String endTime) {
        LambdaQueryWrapper<AuditLog> w = new LambdaQueryWrapper<>();
        applyTimeRange(w, AuditLog::getCreatedAt, startTime, endTime);
        w.orderByDesc(AuditLog::getCreatedAt);
        List<AuditLog> list = auditLogMapper.selectList(w);

        StringBuilder sb = new StringBuilder();
        sb.append("id,username,role,module,action,success,riskLevel,ip,createdAt\n");
        for (AuditLog a : list) {
            sb.append(n(a.getId())).append(',')
                    .append(q(a.getUsername())).append(',')
                    .append(n(a.getRole())).append(',')
                    .append(q(a.getModule())).append(',')
                    .append(q(a.getAction())).append(',')
                    .append(n(a.getSuccess())).append(',')
                    .append(q(a.getRiskLevel())).append(',')
                    .append(q(a.getIp())).append(',')
                    .append(q(String.valueOf(a.getCreatedAt())))
                    .append('\n');
        }
        return sb.toString();
    }

    private static String urlEncode(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8).replaceAll("\\+", "%20");
    }

    private static String q(String s) {
        if (s == null) return "";
        String v = s.replace("\"", "\"\"");
        return "\"" + v + "\"";
    }

    private static String n(Object v) {
        return v == null ? "" : String.valueOf(v);
    }

    private static <T> void applyTimeRange(LambdaQueryWrapper<T> w,
                                           com.baomidou.mybatisplus.core.toolkit.support.SFunction<T, LocalDateTime> col,
                                           String startTime,
                                           String endTime) {
        LocalDateTime start = parseIso(startTime);
        LocalDateTime end = parseIso(endTime);
        if (start != null) w.ge(col, start);
        if (end != null) w.le(col, end);
    }

    private static LocalDateTime parseIso(String iso) {
        if (iso == null || iso.isBlank()) return null;
        // 兼容前端传入的 toISOString：2026-03-03T12:34:56.789Z
        String s = iso.replace("Z", "");
        if (s.length() >= 19) s = s.substring(0, 19);
        try {
            return LocalDateTime.parse(s);
        } catch (Exception e) {
            return null;
        }
    }
}

