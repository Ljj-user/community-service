package com.community.platform.dto;

import lombok.Data;

@Data
public class BannerVO {
    private Long id;
    private String title;
    private String subtitle;
    private String imageUrl;
    private String linkUrl;
}

