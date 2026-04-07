package com.community.platform.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * 静态资源映射配置，用于访问上传的头像文件
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${app.avatar-upload-dir:uploads/avatars}")
    private String avatarUploadDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = avatarUploadDir.replace("\\", "/");
        if (!location.endsWith("/")) {
            location = location + "/";
        }

        registry.addResourceHandler("/static/avatars/**")
                .addResourceLocations("file:" + location);
    }
}

