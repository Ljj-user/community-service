package com.community.platform.service.impl;

import com.community.platform.generated.entity.SysConfig;
import com.community.platform.generated.mapper.SysConfigMapper;
import com.community.platform.service.AdminConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 系统配置服务实现
 */
@Service
public class AdminConfigServiceImpl implements AdminConfigService {

    @Autowired
    private SysConfigMapper sysConfigMapper;

    private static final String KEY_BASIC = "basic";
    private static final String KEY_NOTICE = "notice";
    private static final String KEY_ALERT = "alert";

    @Override
    public Map<String, Object> getBasic() {
        return getConfig(KEY_BASIC);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveBasic(Map<String, Object> data) {
        saveConfig(KEY_BASIC, data);
    }

    @Override
    public Map<String, Object> getNotice() {
        return getConfig(KEY_NOTICE);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveNotice(Map<String, Object> data) {
        saveConfig(KEY_NOTICE, data);
    }

    @Override
    public Map<String, Object> getAlert() {
        return getConfig(KEY_ALERT);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveAlert(Map<String, Object> data) {
        saveConfig(KEY_ALERT, data);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> getConfig(String key) {
        SysConfig row = sysConfigMapper.selectByConfigKey(key);
        if (row == null || row.getConfigValue() == null) {
            return Collections.emptyMap();
        }
        Map<String, Object> val = row.getConfigValue();
        return val == null ? Collections.emptyMap() : new LinkedHashMap<>(val);
    }

    private void saveConfig(String key, Map<String, Object> data) {
        SysConfig row = sysConfigMapper.selectByConfigKey(key);
        if (row == null) {
            row = new SysConfig();
            row.setConfigKey(key);
            row.setConfigValue(data);
            sysConfigMapper.insert(row);
        } else {
            row.setConfigValue(data);
            sysConfigMapper.updateById(row);
        }
    }
}
