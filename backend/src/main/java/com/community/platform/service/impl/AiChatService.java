package com.community.platform.service.impl;

import com.community.platform.dto.AiChatResponseVO;
import com.community.platform.dto.AiOrderDraftVO;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class AiChatService {

    @Value("${app.ai.enabled:false}")
    private boolean aiEnabled;

    @Value("${app.ai.base-url:https://api.deepseek.com}")
    private String aiBaseUrl;

    @Value("${app.ai.model:deepseek-chat}")
    private String aiModel;

    @Value("${app.ai.api-key:}")
    private String aiApiKey;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public AiChatResponseVO chat(String message) {
        String text = message == null ? "" : message.trim();
        if (text.isEmpty()) {
            throw new RuntimeException("消息不能为空");
        }
        if (looksLikeDemand(text)) {
            return buildDemandDraft(text);
        }
        if (aiEnabled && aiApiKey != null && !aiApiKey.isBlank()) {
            AiChatResponseVO byModel = callModelForFaq(text);
            if (byModel != null) {
                return byModel;
            }
        }
        return buildFaqFallback(text);
    }

    private boolean looksLikeDemand(String text) {
        return text.contains("帮我")
                || text.contains("需求")
                || text.contains("找人")
                || text.contains("发布")
                || text.contains("买菜")
                || text.contains("陪诊")
                || text.contains("打扫");
    }

    private AiChatResponseVO buildDemandDraft(String text) {
        AiOrderDraftVO draft = new AiOrderDraftVO();
        draft.setServiceType(detectServiceType(text));
        draft.setUrgencyLevel(detectUrgency(text));
        draft.setExpectedTime(detectExpectedTime(text));
        draft.setTags(detectTags(text));
        draft.setDescription(buildDescription(text, draft));

        AiChatResponseVO vo = new AiChatResponseVO();
        vo.setMode("DEMAND_DRAFT");
        vo.setOrderDraft(draft);
        vo.setReply("我已根据你的描述生成需求草稿，你可以一键创建订单。");
        return vo;
    }

    private String detectServiceType(String text) {
        // 必须命中后端发布白名单（存中文），否则 AI 草稿无法“一键发布”
        if (text.contains("紧急") || text.contains("求助") || text.contains("摔倒") || text.contains("晕") || text.contains("救")) {
            return "应急帮助（紧急求助）";
        }
        if (text.contains("活动") || text.contains("志愿") || text.contains("签到") || text.contains("布置") || text.contains("搬运")) {
            return "社区活动支持";
        }
        if (text.contains("聊天") || text.contains("陪伴") || text.contains("倾诉") || text.contains("心理")) {
            return "心理陪伴 / 聊天";
        }
        if (text.contains("清洁") || text.contains("打扫") || text.contains("家政")) {
            return "家政清洁";
        }
        if (text.contains("买") || text.contains("跑腿") || text.contains("取药") || text.contains("代办")) {
            return "代办服务（买菜 / 取药）";
        }
        // 默认归到助老
        return "助老服务（陪护 / 陪诊）";
    }

    private int detectUrgency(String text) {
        if (text.contains("立刻") || text.contains("马上") || text.contains("非常紧急")) return 4;
        if (text.contains("尽快") || text.contains("紧急")) return 3;
        return 2;
    }

    private String detectExpectedTime(String text) {
        LocalDate targetDay = LocalDate.now();
        LocalTime targetTime = LocalTime.of(9, 0);
        if (text.contains("明天")) targetDay = targetDay.plusDays(1);
        if (text.contains("后天")) targetDay = targetDay.plusDays(2);
        if (text.contains("下午")) targetTime = LocalTime.of(15, 0);
        if (text.contains("晚上")) targetTime = LocalTime.of(19, 0);
        if (text.contains("中午")) targetTime = LocalTime.NOON;
        return LocalDateTime.of(targetDay, targetTime).toString();
    }

    private List<String> detectTags(String text) {
        List<String> tags = new ArrayList<>();
        if (text.contains("老人") || text.contains("老年")) tags.add("老人");
        if (text.contains("残疾")) tags.add("残疾");
        if (text.contains("独居")) tags.add("独居");
        if (tags.isEmpty()) tags.add("社区互助");
        return tags;
    }

    private String buildDescription(String raw, AiOrderDraftVO draft) {
        return String.format(Locale.ROOT, "AI生成：%s；类型=%s；标签=%s。", raw, draft.getServiceType(), String.join("、", draft.getTags()));
    }

    private AiChatResponseVO buildFaqFallback(String text) {
        String answer;
        if (text.contains("怎么发布") || text.contains("发布需求")) {
            answer = "在“任务中心”点击“我要发布”，填写服务类型、地址和描述后提交即可。";
        } else if (text.contains("积分") || text.contains("时间币")) {
            answer = "完成服务并确认后会进行积分/时间币结算；居民发布需求时会做基础余额校验。";
        } else if (text.contains("规则") || text.contains("服务规则")) {
            answer = "需求流程为：发布->审核->认领->完成。系统会限制非法状态回退，并支持申诉与管理员干预。";
        } else {
            answer = "你可以问我：怎么发布需求、积分怎么算、服务规则是什么；也可以直接说需求，我会帮你生成订单草稿。";
        }
        AiChatResponseVO vo = new AiChatResponseVO();
        vo.setMode("FAQ");
        vo.setReply(answer);
        return vo;
    }

    private AiChatResponseVO callModelForFaq(String text) {
        try {
            String prompt = """
                    你是社区公益服务平台助手。请返回 JSON：
                    {
                      "mode": "FAQ",
                      "reply": "回答内容"
                    }
                    用户问题：%s
                    """.formatted(text);

            String body = objectMapper.writeValueAsString(java.util.Map.of(
                    "model", aiModel,
                    "messages", List.of(
                            java.util.Map.of("role", "system", "content", "你是社区公益服务平台问答助手，回答简短清晰。"),
                            java.util.Map.of("role", "user", "content", prompt)
                    ),
                    "temperature", 0.2
            ));

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(aiBaseUrl + "/chat/completions"))
                    .header("Content-Type", "application/json")
                    .header("Authorization", "Bearer " + aiApiKey)
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();
            HttpResponse<String> response = HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() / 100 != 2) return null;
            JsonNode root = objectMapper.readTree(response.body());
            String content = root.path("choices").path(0).path("message").path("content").asText("");
            if (content.isBlank()) return null;
            JsonNode parsed = objectMapper.readTree(content);
            AiChatResponseVO vo = new AiChatResponseVO();
            vo.setMode(parsed.path("mode").asText("FAQ"));
            vo.setReply(parsed.path("reply").asText("已收到你的问题。"));
            return vo;
        } catch (Exception ignored) {
            return null;
        }
    }
}
