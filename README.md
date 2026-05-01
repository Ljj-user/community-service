# 社区公益服务对接管理平台

一个面向社区场景的公益服务平台。

它解决的是三类人的协作问题：

- 居民发布求助
- 志愿者接单服务
- 社区管理员审核和跟进

系统主线围绕一条闭环展开：

`发布需求 -> 审核 -> 推荐/接单 -> 服务执行 -> 确认完成 -> 评价反馈 -> 数据沉淀 -> 异常预警`

## 项目组成

```text
backend/      Spring Boot 后端
frontend/     Vue 3 管理端
basic-main/   Vue 3 + NutUI 移动端
docs/         研究资料、系统设计、导出文档
```

## 当前范围

这版仓库已经收束为“社区公益服务对接”主线，不再做闲置交易、论坛、跑腿下单、在线支付这类偏题功能。

当前重点模块：

- 公益需求发布与审核
- 志愿者认证与服务接单
- 社区绑定与加入审核
- 重点关怀对象管理
- 便民信息与社区公告
- 数据统计与异常预警
- AI 需求草稿与分析记录

## 技术栈

### 后端

- Java 17
- Spring Boot 3
- Spring Security
- MyBatis-Plus
- MySQL 8

### 管理端

- Vue 3
- Vite
- TypeScript
- Naive UI
- Pinia
- ECharts

### 移动端

- Vue 3
- Vite
- TypeScript
- NutUI
- Pinia

## 目录入口

- 产品需求文档：[`docs/产品与技术资料/PRD.md`](D:/Coding/毕设/毕设/docs/产品与技术资料/PRD.md)
- 文档索引：[`docs/README.md`](D:/Coding/毕设/毕设/docs/README.md)
- 数据库设计：[`backend/docs/database-design.md`](D:/Coding/毕设/毕设/backend/docs/database-design.md)
- 数据库脚本说明：[`backend/src/main/resources/db/README-ER-notes.md`](D:/Coding/毕设/毕设/backend/src/main/resources/db/README-ER-notes.md)

## 环境要求

- JDK 17+
- Maven 3.6+
- Node.js 22+
- pnpm 10+
- MySQL 8.0

## 快速启动

### 1. 创建数据库

```sql
CREATE DATABASE IF NOT EXISTS community_service
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;
```

### 2. 导入表结构

```sql
USE community_service;
SOURCE backend/src/main/resources/db/schema_v2_prd.sql;
```

### 3. 导入演示数据

```sql
USE community_service;
SOURCE backend/src/main/resources/db/min_demo_data_v2.sql;
```

说明：

- 演示账号已保留
- 演示口令已脱敏
- 请在本地按自己的环境设置密码

### 4. 配置后端环境变量

`backend/src/main/resources/application-dev.yml` 已改成环境变量读取方式。

PowerShell 示例：

```powershell
$env:DB_URL="jdbc:mysql://localhost:3306/community_service?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true"
$env:DB_USERNAME="your_mysql_username"
$env:DB_PASSWORD="your_mysql_password"
```

如需启用 AI：

```powershell
$env:APP_AI_API_KEY="your_api_key"
```

### 5. 启动后端

```bash
cd backend
mvn spring-boot:run
```

默认地址：`http://localhost:8080`

### 6. 启动管理端

```bash
cd frontend
pnpm install
pnpm dev
```

默认地址：`http://localhost:7000`

### 7. 启动移动端

```bash
cd basic-main
pnpm install
pnpm run dev
```

默认地址：`http://localhost:9000`

## 主要角色

### 居民

- 发布求助
- 查看我的求助
- 确认服务完成
- 评价志愿者
- 查看公告和便民信息

### 志愿者

- 提交志愿者认证
- 查看推荐需求
- 接单和更新进度
- 查看我的服务

### 社区管理员

- 审核求助单
- 审核社区加入
- 审核志愿者认证
- 维护重点关怀对象
- 发布公告和便民信息
- 处理异常预警
- 查看 AI 分析记录和统计数据

## 当前演示地址

- 后端：`http://localhost:8080`
- 管理端：`http://localhost:7000`
- 移动端：`http://localhost:9000`

## 已实现的关键亮点

### 1. 公益服务闭环

不是单纯信息展示，而是完整流程管理：

- 需求发布
- 后台审核
- 志愿者认领
- 服务完成
- 双方反馈

### 2. 统一账号，多角色切换

移动端不拆成两套账号。

同一个用户既可以是居民，也可以在认证后成为志愿者。这样更符合真实社区场景，也方便论文里的权限设计说明。

### 3. 社区归属与数据边界

用户先注册，再通过邀请码或管理员审核加入社区。

绑定社区后，数据按 `community_id` 进行隔离：

- 用户只看自己社区的数据
- 管理员只管自己辖区的数据

### 4. 主动关怀与异常预警

系统支持基于规则的异常检测，例如：

- 重点关怀对象连续多日未登录
- 某社区短时间求助量异常上涨

这类记录会进入管理员预警列表，用来支撑“被动响应”到“主动关怀”的转变。

### 5. AI 辅助

当前 AI 能力主要用于：

- 生成求助草稿
- 生成结构化需求建议
- 记录 AI 分析过程
- 在管理端查看 AI 分析记录

本轮没有做“AI 自动替用户提交表单”，而是停在“生成草稿，人工确认提交”这一层。

## 文档建议阅读顺序

如果你是继续开发这个项目，建议按这个顺序看：

1. [`docs/产品与技术资料/PRD.md`](D:/Coding/毕设/毕设/docs/产品与技术资料/PRD.md)
2. [`backend/docs/database-design.md`](D:/Coding/毕设/毕设/backend/docs/database-design.md)
3. [`docs/系统设计/系统架构与功能初步设计.md`](D:/Coding/毕设/毕设/docs/系统设计/系统架构与功能初步设计.md)
4. [`docs/系统设计/需求可行性优先级分析.md`](D:/Coding/毕设/毕设/docs/系统设计/需求可行性优先级分析.md)

## 常见问题

### 后端连不上数据库

重点检查三件事：

- MySQL 是否已启动
- `community_service` 数据库是否存在
- `DB_URL / DB_USERNAME / DB_PASSWORD` 是否已注入

### 前端登录后接口 401

通常是这几种情况：

- 后端没启动
- Token 过期
- 前端本地缓存还是旧登录态

### 移动端和管理端都能登录吗

可以，但角色入口不同：

- 管理端主要给管理员
- 移动端主要给居民和志愿者

### 数据是正式数据吗

不是。

仓库内默认是演示数据和本地开发配置，不包含生产环境凭据。

## 说明

这是一个毕业设计项目仓库，同时也已经按“可演示、可讲解、可继续开发”的方向做过一轮重构和脱敏整理。
