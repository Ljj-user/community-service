package com.community.platform.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.community.platform.dto.ServiceClaimDTO;
import com.community.platform.dto.ServiceClaimVO;
import com.community.platform.dto.ServiceCompleteDTO;
import com.community.platform.dto.ServiceConfirmDTO;

/**
 * 服务认领服务接口
 */
public interface ServiceClaimService {
    
    /**
     * 认领服务（志愿者）
     */
    void claimService(Long volunteerId, ServiceClaimDTO dto);
    
    /**
     * 完成服务（志愿者提交时长）
     */
    void completeService(Long volunteerId, ServiceCompleteDTO dto);

    /**
     * 需求方核销确认（触发时间币结算）
     */
    void confirmService(Long requesterUserId, ServiceConfirmDTO dto);
    
    /**
     * 获取志愿者的服务记录
     */
    IPage<ServiceClaimVO> getMyServiceRecords(Long volunteerId, Integer current, Integer size);
}
