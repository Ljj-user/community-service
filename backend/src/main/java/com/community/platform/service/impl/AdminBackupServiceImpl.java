package com.community.platform.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.community.platform.dto.BackupScheduleDTO;
import com.community.platform.dto.PageResult;
import com.community.platform.generated.entity.BackupRecord;
import com.community.platform.generated.entity.SysConfig;
import com.community.platform.generated.mapper.BackupRecordMapper;
import com.community.platform.generated.mapper.SysConfigMapper;
import com.community.platform.service.AdminBackupService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * 数据导出与备份服务实现（毕设版：文件生成与恢复为轻量模拟，提供记录与下载能力）
 */
@Service
public class AdminBackupServiceImpl implements AdminBackupService {

    private static final String CONFIG_KEY_SCHEDULE = "backupSchedule";

    @Autowired
    private BackupRecordMapper backupRecordMapper;

    @Autowired
    private SysConfigMapper sysConfigMapper;

    @Value("${app.backup-dir:./uploads/backups}")
    private String backupDir;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BackupRecord runBackup() {
        ensureBackupDir();

        String ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String filename = "backup-" + ts + ".sql";
        Path filePath = Paths.get(backupDir, filename);

        // 轻量模拟：生成一份说明文件（真实项目可改为 mysqldump）
        String content = "-- Backup generated at " + LocalDateTime.now() + System.lineSeparator()
                + "-- TODO: replace with real database dump" + System.lineSeparator();
        writeTextFile(filePath, content);

        BackupRecord record = new BackupRecord();
        record.setRecordType("BACKUP");
        record.setFilename(filename);
        record.setFilePath(filePath.toAbsolutePath().toString());
        record.setStatus("SUCCESS");
        record.setNote("手动备份");
        record.setIsDeleted((byte) 0);
        record.setCreatedAt(LocalDateTime.now());
        record.setUpdatedAt(LocalDateTime.now());

        BigDecimal sizeMb = sizeMb(filePath);
        record.setFileSizeMb(sizeMb);

        backupRecordMapper.insert(record);
        return record;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public BackupRecord restore(MultipartFile file) {
        ensureBackupDir();
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("备份文件不能为空");
        }

        String original = file.getOriginalFilename() == null ? "restore.sql" : file.getOriginalFilename();
        String ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String filename = "restore-" + ts + "-" + original.replaceAll("[\\\\/]", "_");
        Path filePath = Paths.get(backupDir, filename);

        try (InputStream in = file.getInputStream()) {
            Files.copy(in, filePath);
        } catch (IOException e) {
            throw new RuntimeException("保存恢复文件失败: " + e.getMessage(), e);
        }

        BackupRecord record = new BackupRecord();
        record.setRecordType("RESTORE");
        record.setFilename(filename);
        record.setFilePath(filePath.toAbsolutePath().toString());
        record.setStatus("SUCCESS");
        record.setNote("上传恢复（模拟）");
        record.setIsDeleted((byte) 0);
        record.setCreatedAt(LocalDateTime.now());
        record.setUpdatedAt(LocalDateTime.now());
        record.setFileSizeMb(sizeMb(filePath));

        backupRecordMapper.insert(record);
        return record;
    }

    @Override
    public PageResult<BackupRecord> history(int page, int size) {
        int p = page < 1 ? 1 : page;
        int s = size < 1 ? 10 : size;
        LambdaQueryWrapper<BackupRecord> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(BackupRecord::getIsDeleted, 0).orderByDesc(BackupRecord::getCreatedAt);
        Page<BackupRecord> result = backupRecordMapper.selectPage(new Page<>(p, s), wrapper);
        return PageResult.of(result.getRecords(), result.getTotal(), result.getCurrent(), result.getSize());
    }

    @Override
    public void deleteRecord(Long id) {
        if (id == null) return;
        BackupRecord record = backupRecordMapper.selectById(id);
        if (record == null) return;
        record.setIsDeleted((byte) 1);
        record.setUpdatedAt(LocalDateTime.now());
        backupRecordMapper.updateById(record);
    }

    @Override
    public BackupScheduleDTO getSchedule() {
        SysConfig cfg = sysConfigMapper.selectByConfigKey(CONFIG_KEY_SCHEDULE);
        BackupScheduleDTO dto = new BackupScheduleDTO();
        if (cfg == null || cfg.getConfigValue() == null) {
            dto.setEnabled(false);
            dto.setCycle("daily");
            dto.setTime("02:00");
            dto.setKeepDays(30);
            return dto;
        }
        Map<String, Object> m = cfg.getConfigValue();
        dto.setEnabled(asBool(m.get("enabled"), false));
        dto.setCycle(asStr(m.get("cycle"), "daily"));
        dto.setTime(asStr(m.get("time"), "02:00"));
        dto.setKeepDays(asInt(m.get("keepDays"), 30));
        return dto;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveSchedule(BackupScheduleDTO dto) {
        Map<String, Object> m = new HashMap<>();
        m.put("enabled", dto.getEnabled() != null && dto.getEnabled());
        m.put("cycle", dto.getCycle() == null ? "daily" : dto.getCycle());
        m.put("time", dto.getTime() == null ? "02:00" : dto.getTime());
        m.put("keepDays", dto.getKeepDays() == null ? 30 : dto.getKeepDays());

        SysConfig cfg = sysConfigMapper.selectByConfigKey(CONFIG_KEY_SCHEDULE);
        if (cfg == null) {
            cfg = new SysConfig();
            cfg.setConfigKey(CONFIG_KEY_SCHEDULE);
            cfg.setConfigValue(m);
            sysConfigMapper.insert(cfg);
        } else {
            cfg.setConfigValue(m);
            sysConfigMapper.updateById(cfg);
        }
    }

    @Override
    public DownloadFile download(Long id) {
        BackupRecord record = backupRecordMapper.selectById(id);
        if (record == null || record.getIsDeleted() != null && record.getIsDeleted() == 1) {
            throw new RuntimeException("记录不存在");
        }
        if (record.getFilePath() == null || record.getFilePath().isBlank()) {
            throw new RuntimeException("文件不存在");
        }
        Path path = Paths.get(record.getFilePath());
        if (!Files.exists(path)) {
            throw new RuntimeException("文件不存在");
        }
        try {
            InputStream in = Files.newInputStream(path);
            return new DownloadFile(record.getFilename() == null ? path.getFileName().toString() : record.getFilename(), in);
        } catch (IOException e) {
            throw new RuntimeException("下载失败: " + e.getMessage(), e);
        }
    }

    private void ensureBackupDir() {
        try {
            Files.createDirectories(Paths.get(backupDir));
        } catch (IOException e) {
            throw new RuntimeException("创建备份目录失败: " + e.getMessage(), e);
        }
    }

    private static void writeTextFile(Path path, String content) {
        try (Writer w = new OutputStreamWriter(new FileOutputStream(path.toFile()), StandardCharsets.UTF_8)) {
            w.write(content);
        } catch (IOException e) {
            throw new RuntimeException("写入备份文件失败: " + e.getMessage(), e);
        }
    }

    private static BigDecimal sizeMb(Path path) {
        try {
            long bytes = Files.size(path);
            BigDecimal mb = BigDecimal.valueOf(bytes).divide(BigDecimal.valueOf(1024 * 1024L), 2, BigDecimal.ROUND_HALF_UP);
            return mb;
        } catch (IOException e) {
            return null;
        }
    }

    private static boolean asBool(Object v, boolean def) {
        if (v == null) return def;
        if (v instanceof Boolean b) return b;
        return Boolean.parseBoolean(String.valueOf(v));
    }

    private static String asStr(Object v, String def) {
        if (v == null) return def;
        String s = String.valueOf(v);
        return s.isBlank() ? def : s;
    }

    private static int asInt(Object v, int def) {
        if (v == null) return def;
        try {
            return Integer.parseInt(String.valueOf(v));
        } catch (Exception e) {
            return def;
        }
    }
}

