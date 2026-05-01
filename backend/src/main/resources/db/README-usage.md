# DB 脚本使用说明

## 当前主入口

- `schema_v2_prd.sql`：当前 PRD v2 完整建表脚本
- `temp_data.sql`：当前模拟数据主入口
- `init_all.sql`：本地一键初始化入口
- `init-db.cmd`：Windows 环境下一键初始化脚本，内部调用 `init_all.sql`

## 兼容保留文件

- `min_demo_data_v2.sql`：旧的演示数据脚本，当前由 `temp_data.sql` 统一接入

## 历史保留文件

- `archive/legacy-sql/schema.sql`：旧版完整建表脚本，不再作为当前权威来源
- `archive/legacy-sql/migration_*.sql`：旧库升级用增量脚本
- `archive/legacy-sql/rollback_migration_*.sql`：对应迁移回滚脚本
- `archive/legacy-sql/patch_user_bind_community.sql`：历史演示数据修补脚本
- `archive/legacy-sql/service_request_emergency.sql`：历史字段补丁
- `archive/legacy-sql/sys_region_province_city.sql`：历史字段补丁
- `archive/legacy-sql/migration_grid_timebank.sql`：旧方向迁移脚本，和当前项目主线不再完全一致

## 演示数据

- `demo_fengying_community.sql`
- `demo_cuiyuan_rich_flow.sql`

这两个文件用于补充现场展示数据，不属于新库初始化必需步骤。

## 使用建议

1. 新库初始化时，不要再把所有 SQL 顺序执行一遍。
2. 新环境只需执行 `init_all.sql`，Windows 下也可以直接运行 `init-db.cmd`。
3. 如果只想单独补模拟数据，执行 `temp_data.sql` 即可。
3. 历史迁移脚本仅在旧库升级时按需执行。
