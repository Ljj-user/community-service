# 社区公益服务对接管理平台

基于 "十五五" 规划的社区公益服务对接管理平台，通过数字化手段打通公益服务"需求-资源-监管"全链路。

## 项目结构

```
社区公益服务对接管理平台/
├── backend/              # 后端（Spring Boot 3 + MyBatis-Plus）
├── frontend/             # 管理端前端（Vue 3 + Vite + Naive UI）
├── basic-main/           # 移动端（pnpm workspace）
├── docs/                 # 项目文档（论文/开题/设计/导出，见 docs/README.md）
├── temp/                 # 临时预览与草稿（不入论文定稿）
├── init-db.ps1 / start-all.ps1
└── README.md
```

## 技术栈

### 后端

- Java 17
- Spring Boot 3.5.7（Web / Validation / Security）
- MyBatis-Plus 3.5.16（含代码生成器）
- MySQL 8.0（mysql-connector-j）
- Maven（后端构建与依赖管理）
- Lombok

### 管理端前端（frontend）

- Vue 3.5
- Vite 7（rolldown-vite）
- TypeScript 5.9
- Naive UI 2.43
- Pinia 3
- Vue Router 4
- Axios
- UnoCSS
- ECharts 5（仪表盘地图/趋势/占比图）
- Vitest
- Biome（lint/check）

### 移动端（basic-main）

- pnpm workspace（Monorepo）
- Vue 3 + Vite
- NutUI（移动端组件）
- Vue Router + Pinia
- Axios
- TypeScript
- UnoCSS
- ESLint + Stylelint

## 环境要求

- JDK 17+
- Maven 3.6.0+
- Node.js 22+（建议与 `frontend/package.json` engines 保持一致）
- pnpm 10+
- MySQL 8.0

## 快速开始

### 1. 数据库初始化

#### 1.1 创建数据库

```sql
CREATE DATABASE IF NOT EXISTS community_service 
DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
```

#### 1.2 执行建表脚本

在 MySQL 客户端执行：

```sql
USE community_service;
SOURCE E:/code/毕设/社区公益服务对接管理平台/data.sql;
```

#### 1.3 导入测试数据（可选）

```sql
USE community_service;
SOURCE E:/code/毕设/社区公益服务对接管理平台/Temp_data.sql;
```

**测试账号（密码均为 `123456`）：**

- `admin` - 超级管理员
- `manager` - 社区管理员
- `resident1` - 居民用户
- `volunteer1` - 志愿者用户

### 2. 后端启动

#### 2.1 配置数据库连接

编辑 `backend/src/main/resources/application-dev.yml`：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/community_service?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true
    username: root
    password: 123456  # 修改为你的 MySQL 密码
```

#### 2.2 启动后端服务

```bash
cd backend
mvn spring-boot:run
```

后端服务将在 `http://localhost:8080` 启动。

**API 接口：**

- `POST /api/auth/login` - 登录
- `POST /api/auth/register` - 注册
- `GET /api/auth/me` - 获取当前用户信息

### 3. 前端启动

#### 3.1 安装依赖

```bash
cd frontend
pnpm install
```

#### 3.2 启动开发服务器

```bash
pnpm dev
```

前端应用将在 `http://localhost:7000` 启动。

**访问地址：**

- 前端：[http://localhost:7000](http://localhost:7000)
- 后端 API：[http://localhost:8080](http://localhost:8080)

### 4. 代码生成（MyBatis-Plus）

如果需要重新生成 entity/mapper/service/controller：

```bash
cd backend
.\gen-code.ps1
```

生成的文件位于：

- `src/main/java/com/community/platform/generated/`
- `src/main/resources/mapper/`

## 核心功能模块

### 1. 用户与权限模块

- **登录/注册**：支持用户名密码登录和用户注册
- **角色管理**：
  - 超级管理员（role=1）：系统配置、角色权限分配
  - 社区管理员（role=2）：审核需求、管理志愿者
  - 普通用户（role=3）：居民/志愿者身份
- **MD5 密码加密**：按需求文档技术选型
- **基于 Spring Security 的权限控制**：接口级别的角色权限验证

**API 接口：**

- `POST /api/auth/login` - 用户登录
- `POST /api/auth/register` - 用户注册
- `GET /api/auth/me` - 获取当前用户信息

### 2. 需求管理业务流（闭环核心）

#### 2.1 需求发布

- 居民可发布服务需求（服务类型、地址、时间、紧急程度、特殊标签）
- 发布后状态为"待审核"（status=0）

**API 接口：**

- `POST /api/service-request` - 发布需求（需要 USER 角色）

#### 2.2 需求审核

- 社区管理员可审核需求（通过/驳回）
- 驳回需填写驳回原因
- 审核通过后状态为"已发布"（status=1），驳回为"已驳回"（status=4）

**前端页面：**

- `/request/audit` - 需求审核表格页面（仅管理员可见）
  - 表格列：ID、发布人、服务类型、服务地址、紧急程度、状态、发布时间
  - 筛选功能：按服务类型、紧急程度筛选
  - 操作功能：
    - **通过按钮**：点击后确认对话框，确认后审核通过
    - **驳回按钮**：点击后弹出对话框，需填写驳回原因（至少5个字符）
    - **详情按钮**：查看需求详情
  - 分页功能：支持分页查询和调整每页显示数量

**API 接口：**

- `POST /api/service-request/audit` - 审核需求（需要 COMMUNITY_ADMIN 或 SUPER_ADMIN 角色）

#### 2.3 需求列表查询

- 支持按状态、服务类型、紧急程度筛选
- 分页查询
- 普通用户只能看到自己发布的需求和已发布的需求
- 管理员可查看所有需求

**API 接口：**

- `GET /api/service-request/list` - 分页查询需求列表
- `GET /api/service-request/{id}` - 获取需求详情

### 3. 服务对接业务流

#### 3.1 服务认领

- 志愿者可认领已发布的需求
- 认领后创建认领记录，需求状态改为"已认领"（status=2）

**API 接口：**

- `POST /api/service-claim/claim` - 认领服务（需要 USER 角色，志愿者身份）

#### 3.2 完成服务

- 志愿者提交服务时长和完成说明
- 认领记录状态改为"已完成"（claim_status=2）
- 需求状态改为"已完成"（status=3）

**API 接口：**

- `POST /api/service-claim/complete` - 完成服务（需要 USER 角色，志愿者身份）

#### 3.3 服务评价

- 居民对已完成的服务进行评价（1-5星）
- 一个认领记录只能评价一次

**API 接口：**

- `POST /api/service-evaluation` - 评价服务（需要 USER 角色，居民身份）

#### 3.4 服务记录查询

- 志愿者可查看自己的服务记录

**API 接口：**

- `GET /api/service-claim/my-records` - 获取我的服务记录（需要 USER 角色）

### 4. 角色差异化工作台

#### 4.1 管理员工作台（超级管理员/社区管理员）

- **数据看板**：
  - 总需求数、待审核需求数、已完成需求数
  - 累计服务时长、活跃志愿者数
  - 本月新增需求、本月完成需求
- **待审核需求列表**：快速查看和审核待审核需求（工作台内嵌表格）
- **需求审核页面**：完整的审核表格页面（`/request/audit`），支持筛选、分页、批量审核
- **异常干预入口**：可查看所有需求状态，进行手动干预

**API 接口：**

- `GET /api/dashboard/stats` - 获取统计数据（需要 COMMUNITY_ADMIN 或 SUPER_ADMIN 角色）

#### 4.2 居民工作台

- **发布需求表单**：一站式发布服务需求
- **历史进度查看**：时间线展示已发布需求的进度状态

#### 4.3 志愿者工作台

- **需求大厅**：浏览可认领的已发布需求，支持一键认领
- **我的服务记录**：查看认领记录、状态、服务时长

### 5. 数据统计与展示

- **个人端**：志愿者服务时长/次数/评价，居民历史需求
- **管理端**：对接成功率、志愿者排名、服务类型占比
- **ECharts 图表展示**：柱状图、折线图、饼图（待实现）
- **ECharts 图表展示**：柱状图、折线图、饼图、中国地图热力图（已接入）

### 6. 新用户技能画像与推荐冷启动

- 注册/引导问卷会将用户技能标签写入 `sys_user_skill`
- 系统同步维护 `skill_tag_stat`（技能热度统计）
- 当新用户技能为空时，需求推荐会参考技能热度进行冷启动排序，避免固定低分

## 项目说明

本项目严格按照 `docs/论文与开题/开题报告.md` 中的业务逻辑实现，包含以下创新点：

1. **AI 智能匹配**：基于协同过滤算法的需求-志愿者匹配
2. **智能监管**：需求趋势预测，资源储备建议
3. **数据可视化报告**：月度公益服务分析报告自动生成

## API 接口汇总

### 认证相关

- `POST /api/auth/login` - 登录
- `POST /api/auth/register` - 注册
- `GET /api/auth/me` - 获取当前用户信息

### 需求管理

- `POST /api/service-request` - 发布需求（USER）
- `POST /api/service-request/audit` - 审核需求（COMMUNITY_ADMIN/SUPER_ADMIN）
- `GET /api/service-request/list` - 分页查询需求列表（支持按状态、服务类型、紧急程度筛选）
- `GET /api/service-request/{id}` - 获取需求详情

**前端页面：**

- `/request/list` - 需求列表页面
- `/request/audit` - 需求审核页面（管理员专用，包含审核表格组件）
- `/request/detail/:id` - 需求详情页面

### 服务认领

- `POST /api/service-claim/claim` - 认领服务（USER，志愿者）
- `POST /api/service-claim/complete` - 完成服务（USER，志愿者）
- `GET /api/service-claim/my-records` - 获取我的服务记录（USER）

### 服务评价

- `POST /api/service-evaluation` - 评价服务（USER，居民）

### 数据看板

- `GET /api/dashboard/stats` - 获取统计数据（COMMUNITY_ADMIN/SUPER_ADMIN）

## 开发规范

- 所有代码生成严格遵循 `docs/论文与开题/开题报告.md` 中的业务逻辑
- 数据库采用逻辑删除（`is_deleted` 字段）
- 密码加密使用 MD5（按需求文档技术选型）
- 统一使用 `Result<T>` 作为 API 响应格式
- 接口权限控制使用 Spring Security 的 `@PreAuthorize` 注解
- 前端根据用户角色动态显示不同的工作台界面

## 业务流程说明

### 完整业务流程

1. **需求发布流程**：
  - 居民登录 → 进入居民工作台 → 填写需求表单 → 提交发布
  - 需求状态：待审核（0）
2. **需求审核流程**：
  - 管理员登录 → 进入管理员工作台 → 查看待审核需求 → 点击"查看全部"进入审核页面
  - 或直接访问 `/request/audit` 进入需求审核表格页面
  - 在审核表格中：
    - 点击"通过"按钮 → 确认对话框 → 审核通过，状态变为已发布（1）
    - 点击"驳回"按钮 → 填写驳回原因对话框 → 确认驳回，状态变为已驳回（4）
  - 支持按服务类型、紧急程度筛选待审核需求
  - 支持分页浏览和查看详情
3. **服务认领流程**：
  - 志愿者登录 → 进入志愿者工作台 → 浏览需求大厅 → 认领需求
  - 需求状态：已认领（2），创建认领记录
4. **服务完成流程**：
  - 志愿者完成服务 → 提交服务时长和完成说明
  - 认领记录状态：已完成（2）
  - 需求状态：已完成（3）
5. **服务评价流程**：
  - 居民查看已完成的需求 → 对服务进行评价（1-5星）
  - 创建评价记录，完成闭环

### 角色权限说明


| 角色           | 权限说明               |
| ------------ | ------------------ |
| 超级管理员        | 系统配置、角色权限分配、所有管理功能 |
| 社区管理员        | 审核需求、管理志愿者、查看统计数据  |
| 普通用户（居民）     | 发布需求、查看历史进度、评价服务   |
| 普通用户（志愿者）    | 认领服务、完成服务、查看服务记录   |
| 普通用户（居民+志愿者） | 同时拥有居民和志愿者的所有权限    |


## 常见问题

### MySQL 连接失败

- 检查 MySQL 服务是否启动：`Get-Service MySQL80`
- 确认数据库密码是否正确（默认 `123456`）
- 检查 `application-dev.yml` 中的数据库配置
- 如果忘记密码，可通过 `--init-file` 方式重置（参考项目历史记录）

### 前端依赖安装失败

- 清除缓存：`npm cache clean --force`
- 使用国内镜像：`npm config set registry https://registry.npmmirror.com`
- 或使用 `npm install --legacy-peer-deps`

### 后端编译错误

- 确认 JDK 版本为 17+
- 确认 Maven 版本为 3.6.0+（建议升级到 3.6.3+）
- 检查 `pom.xml` 中的依赖版本

### 接口权限错误

- 确认用户已登录（Token 有效）
- 检查用户角色是否匹配接口要求的权限
- 查看后端日志确认具体的权限错误信息

### 前端工作台显示不正确

- 确认登录后用户信息已正确加载到 Pinia store
- 检查 `userInfo.role` 和 `userInfo.identityType` 的值
- 刷新页面或重新登录

### 前端代理错误（ECONNREFUSED）

- **问题**：`[vite] http proxy error: /auth/login` 或 `ECONNREFUSED`
- **原因**：后端服务未启动或端口不匹配
- **解决方案**：
  1. 确认后端服务已启动：`cd backend && mvn spring-boot:run`
  2. 检查后端服务端口是否为 8080（查看启动日志）
  3. 检查 `vite.config.js` 中的代理配置：
    ```js
     proxy: {
       '/api': {
         target: 'http://localhost:8080',
         changeOrigin: true,
         rewrite: (path) => path.replace(/^\/api/, '')
       }
     }
    ```
  4. 如果后端端口不是 8080，修改 `vite.config.js` 中的 `target` 值

### 后端启动失败（Process terminated with exit code: 1）

- **问题**：Maven 执行失败，进程退出码为 1
- **解决方案**：
  1. 查看完整错误信息：`mvn spring-boot:run -e` 或 `mvn spring-boot:run -X`
  2. 检查编译错误：`mvn clean compile`
  3. 常见原因：
    - 数据库连接失败：检查 MySQL 服务是否启动，数据库配置是否正确
    - 端口被占用：检查 8080 端口是否被其他程序占用
    - 依赖下载失败：清理 Maven 缓存后重新下载：`mvn clean install -U`
    - 代码编译错误：检查 Java 代码是否有语法错误

## 许可证

本项目为毕业设计项目。