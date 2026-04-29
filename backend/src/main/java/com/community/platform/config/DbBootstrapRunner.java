package com.community.platform.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * 杩愯鏈熷厹搴曪細褰撴湰鏈烘暟鎹簱鏈墽琛?init_all.sql 鏃讹紝纭繚鍏抽敭琛ㄥ瓨鍦紝閬垮厤鍚姩鍗虫姤閿欍€? *
 * 娉ㄦ剰锛氳繖閲屽彧鍋?CREATE TABLE IF NOT EXISTS锛堝箓绛夛級锛屼笉鍋氱牬鍧忔€у彉鏇淬€? */
@Component
public class DbBootstrapRunner implements ApplicationRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        ensurePasswordHashColumn();
        ensureSysNotification();
        ensureVerificationAndOnboarding();
        ensureMatchingTags();
        ensureCommunityInviteCode();
        ensureCommunityBanner();
        ensureAnomalyAlertAndCredit();
        ensureAiAnalysisRecord();
        ensureDualEvaluationSchema();
        ensureRuntimeConfig();
    }

    private void ensurePasswordHashColumn() {
        Integer cnt = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM information_schema.columns
                WHERE table_schema = DATABASE()
                  AND table_name='sys_user'
                  AND column_name='password_md5'
                  AND (
                    data_type <> 'varchar'
                    OR character_maximum_length < 60
                  )
                """, Integer.class);
        if (cnt != null && cnt > 0) {
            jdbcTemplate.execute("""
                    ALTER TABLE sys_user
                    MODIFY COLUMN password_md5 VARCHAR(100) NOT NULL COMMENT '瀵嗙爜鍝堝笇锛堝瓧娈靛悕娌跨敤锛涘吋瀹瑰巻鍙睲D5涓庡綋鍓岯Crypt锛?
                    """);
        }
    }

    private void ensureSysNotification() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS sys_notification (
                  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '涓婚敭',
                  recipient_user_id BIGINT UNSIGNED NOT NULL COMMENT '鎺ユ敹浜虹敤鎴稩D',
                  title             VARCHAR(200)     NOT NULL COMMENT '鏍囬',
                  summary           VARCHAR(500)     NULL COMMENT '鎽樿',
                  msg_category      TINYINT UNSIGNED NOT NULL COMMENT '1涓氬姟寰呭姙 2绯荤粺鍏憡',
                  read_status       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0鏈 1宸茶',
                  ref_type          VARCHAR(32)      NULL COMMENT '鍏宠仈涓氬姟绫诲瀷',
                  ref_id            BIGINT UNSIGNED  NULL COMMENT '鍏宠仈涓氬姟涓婚敭',
                  created_at        DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '鍒涘缓鏃堕棿',
                  PRIMARY KEY (id),
                  KEY idx_notif_user_read (recipient_user_id, read_status),
                  KEY idx_notif_user_cat_time (recipient_user_id, msg_category, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='绔欏唴娑堟伅閫氱煡';
                """);
    }

    private void ensureVerificationAndOnboarding() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS verify_code_ticket (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  scene VARCHAR(32) NOT NULL,
                  target VARCHAR(128) NOT NULL,
                  verify_code VARCHAR(16) NOT NULL,
                  expires_at DATETIME NOT NULL,
                  is_used TINYINT NOT NULL DEFAULT 0,
                  used_at DATETIME NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  INDEX idx_verify_target_scene (target, scene),
                  INDEX idx_verify_expire (expires_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='楠岃瘉鐮佺エ鎹〃';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS user_onboarding_profile (
                  user_id BIGINT PRIMARY KEY,
                  skill_tags_json JSON NULL,
                  preferred_features_json JSON NULL,
                  intent_note VARCHAR(500) NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='鐢ㄦ埛寮曞闂嵎涓昏〃';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS user_onboarding_answer (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  question_key VARCHAR(64) NOT NULL,
                  answer_value VARCHAR(255) NOT NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_onboarding_answer_user (user_id),
                  INDEX idx_onboarding_answer_key (question_key)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='鐢ㄦ埛寮曞闂嵎绛旀琛?;
                """);
    }

    private void ensureMatchingTags() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS sys_user_skill (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  skill_tag VARCHAR(64) NOT NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_user_skill (user_id, skill_tag),
                  INDEX idx_user_skill_user (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='鐢ㄦ埛鎶€鑳借〃';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS service_request_tag (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  request_id BIGINT NOT NULL,
                  tag_name VARCHAR(64) NOT NULL,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_request_tag (request_id, tag_name),
                  INDEX idx_request_tag_req (request_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='闇€姹傛爣绛捐〃';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS skill_tag_stat (
                  skill_tag VARCHAR(64) PRIMARY KEY,
                  user_count INT NOT NULL DEFAULT 0,
                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='鎶€鑳界儹搴︾粺璁★紙鐢ㄤ簬鏂扮敤鎴锋帹鑽愬喎鍚姩锛?;
                """);
    }


    private void ensureCommunityInviteCode() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS community_invite_code (
                  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '涓婚敭',
                  community_id  BIGINT UNSIGNED NOT NULL COMMENT '绀惧尯ID锛坰ys_region.id锛岄€氬父 level=3锛?,
                  code          VARCHAR(32)      NOT NULL COMMENT '閭€璇风爜锛堢煭鐮侊級',
                  status        TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0绂佺敤 1鍚敤',
                  expires_at    DATETIME(3)      NULL COMMENT '杩囨湡鏃堕棿锛圢ULL=涓嶈繃鏈燂級',
                  max_uses      INT UNSIGNED     NOT NULL DEFAULT 100 COMMENT '鏈€澶у彲鐢ㄦ鏁?,
                  used_count    INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '宸蹭娇鐢ㄦ鏁?,
                  created_by    BIGINT UNSIGNED  NULL COMMENT '鍒涘缓浜虹敤鎴稩D',
                  created_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '鍒涘缓鏃堕棿',
                  updated_at    DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '鏇存柊鏃堕棿',
                  PRIMARY KEY (id),
                  UNIQUE KEY uk_invite_code (code),
                  KEY idx_invite_comm_status (community_id, status),
                  KEY idx_invite_expire (expires_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='绀惧尯閭€璇风爜';
                """);
    }

    private void ensureCommunityBanner() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS community_banner (
                  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '涓婚敭',
                  community_id BIGINT UNSIGNED NULL COMMENT '绀惧尯ID锛圢ULL=鍏ㄥ眬榛樿锛?,
                  title        VARCHAR(100)    NOT NULL COMMENT '涓绘爣棰?,
                  subtitle     VARCHAR(200)    NULL COMMENT '鍓爣棰?,
                  image_url    VARCHAR(500)    NULL COMMENT '鍥剧墖URL锛堝彲绌猴細绾枃妗堝崱鐗囷級',
                  link_url     VARCHAR(500)    NULL COMMENT '鐐瑰嚮璺宠浆閾炬帴锛堝彲绌猴級',
                  sort_no      INT             NOT NULL DEFAULT 0 COMMENT '鎺掑簭锛堝皬鍦ㄥ墠锛?,
                  status       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0绂佺敤 1鍚敤',
                  created_by   BIGINT UNSIGNED NULL COMMENT '鍒涘缓浜虹敤鎴稩D',
                  created_at   DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  updated_at   DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  KEY idx_banner_comm_status_sort (community_id, status, sort_no),
                  KEY idx_banner_comm_time (community_id, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='绀惧尯杞挱鍥?;
                """);
    }

    private void ensureAnomalyAlertAndCredit() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS anomaly_alert_event (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  alert_code VARCHAR(64) NOT NULL,
                  community_id BIGINT UNSIGNED NULL,
                  request_id BIGINT UNSIGNED NULL,
                  target_user_id BIGINT UNSIGNED NULL,
                  severity TINYINT UNSIGNED NOT NULL DEFAULT 2,
                  trigger_rule VARCHAR(255) NOT NULL,
                  suggestion_action VARCHAR(255) NULL,
                  rule_snapshot TEXT NULL,
                  dedup_key VARCHAR(128) NOT NULL,
                  occurred_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  PRIMARY KEY (id),
                  KEY idx_alert_code_time (alert_code, occurred_at),
                  KEY idx_alert_comm_time (community_id, occurred_at),
                  KEY idx_alert_req_time (request_id, occurred_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='寮傚父棰勮浜嬩欢';
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS volunteer_credit_ledger (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  user_id BIGINT UNSIGNED NOT NULL,
                  request_id BIGINT UNSIGNED NOT NULL,
                  claim_id BIGINT UNSIGNED NOT NULL,
                  hours DECIMAL(10,2) NOT NULL DEFAULT 0,
                  rating TINYINT NULL,
                  overtime_penalty DECIMAL(5,2) NOT NULL DEFAULT 1.00,
                  credit_delta DECIMAL(10,2) NOT NULL DEFAULT 0,
                  calc_version VARCHAR(32) NOT NULL DEFAULT 'v1',
                  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  PRIMARY KEY (id),
                  UNIQUE KEY uk_credit_claim (claim_id),
                  KEY idx_credit_user_time (user_id, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='蹇楁効鑰呬俊鐢ㄦ槑缁嗚处鏈?;
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS volunteer_credit_snapshot (
                  user_id BIGINT UNSIGNED NOT NULL,
                  total_hours DECIMAL(10,2) NOT NULL DEFAULT 0,
                  avg_rating_30d DECIMAL(4,2) NULL,
                  completion_rate_30d DECIMAL(5,2) NOT NULL DEFAULT 0,
                  credit_score DECIMAL(12,2) NOT NULL DEFAULT 0,
                  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  PRIMARY KEY (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='蹇楁効鑰呬俊鐢ㄥ揩鐓?;
                """);
    }

    private void ensureAiAnalysisRecord() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS ai_analysis_record (
                  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                  user_id BIGINT UNSIGNED NOT NULL,
                  community_id BIGINT UNSIGNED NULL,
                  scene VARCHAR(32) NOT NULL DEFAULT 'mobile_assistant',
                  input_text TEXT NOT NULL,
                  result_mode VARCHAR(32) NOT NULL DEFAULT 'FAQ',
                  result_json JSON NULL,
                  applied_to_form TINYINT UNSIGNED NOT NULL DEFAULT 0,
                  submitted_success TINYINT UNSIGNED NOT NULL DEFAULT 0,
                  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
                  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
                  PRIMARY KEY (id),
                  KEY idx_ai_analysis_user_time (user_id, created_at),
                  KEY idx_ai_analysis_comm_time (community_id, created_at),
                  KEY idx_ai_analysis_mode_time (result_mode, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='AI鍒嗘瀽璁板綍';
                """);
    }

    private void ensureRuntimeConfig() {
        Integer cnt = jdbcTemplate.queryForObject("SELECT COUNT(1) FROM sys_config WHERE config_key='runtime'", Integer.class);
        if (cnt == null || cnt == 0) {
            jdbcTemplate.update("""
                    INSERT INTO sys_config(config_key, config_value, created_at, updated_at)
                    VALUES('runtime', CAST(? AS JSON), NOW(3), NOW(3))
                    """, "{\"demoModeEnabled\":true}");
        }
    }

    /**
     * 鍙屽悜璇勪环瀛楁/绱㈠紩鍏滃簳锛?     * - evaluator_role 鍒?     * - 鍞竴绱㈠紩鐢?uk_eval_claim 鍗囩骇涓?uk_eval_claim_role(claim_id, evaluator_role)
     */
    private void ensureDualEvaluationSchema() {
        Integer hasColumn = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM information_schema.columns
                WHERE table_schema = DATABASE()
                  AND table_name='service_evaluation'
                  AND column_name='evaluator_role'
                """, Integer.class);
        if (hasColumn == null || hasColumn == 0) {
            jdbcTemplate.execute("""
                    ALTER TABLE service_evaluation
                    ADD COLUMN evaluator_role TINYINT UNSIGNED NOT NULL DEFAULT 1
                    COMMENT '璇勪环鏂硅鑹诧細1灞呮皯 2蹇楁効鑰?
                    AFTER volunteer_user_id
                    """);
        }

        Integer hasOldUk = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM information_schema.statistics
                WHERE table_schema = DATABASE()
                  AND table_name='service_evaluation'
                  AND index_name='uk_eval_claim'
                """, Integer.class);
        if (hasOldUk != null && hasOldUk > 0) {
            try {
                jdbcTemplate.execute("ALTER TABLE service_evaluation DROP INDEX uk_eval_claim");
            } catch (DataAccessException ex) {
                // 鍘嗗彶搴撳彲鑳藉瓨鍦ㄢ€滃閿緷璧栧悓鍚嶇储寮曗€濈殑鍦烘櫙锛屾鏃惰烦杩囧垹闄わ紝淇濊瘉搴旂敤鍙惎鍔?            }
        }

        Integer hasNewUk = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM information_schema.statistics
                WHERE table_schema = DATABASE()
                  AND table_name='service_evaluation'
                  AND index_name='uk_eval_claim_role'
                """, Integer.class);
        if (hasNewUk == null || hasNewUk == 0) {
            jdbcTemplate.execute("""
                    ALTER TABLE service_evaluation
                    ADD UNIQUE KEY uk_eval_claim_role (claim_id, evaluator_role)
                    """);
        }

        Integer hasRoleIndex = jdbcTemplate.queryForObject("""
                SELECT COUNT(*)
                FROM information_schema.statistics
                WHERE table_schema = DATABASE()
                  AND table_name='service_evaluation'
                  AND index_name='idx_eval_evaluator_role'
                """, Integer.class);
        if (hasRoleIndex == null || hasRoleIndex == 0) {
            jdbcTemplate.execute("""
                    CREATE INDEX idx_eval_evaluator_role
                    ON service_evaluation (evaluator_role)
                    """);
        }
    }
}
