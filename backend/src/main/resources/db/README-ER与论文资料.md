# 数据库说明与 ER 图资料

完整表结构脚本：**本目录 `schema.sql`**（权威）。

用于生成 ER 图、撰写论文「数据库设计」章节的整理文档在：

**`backend/docs/`**

| 文件 | 说明 |
|------|------|
| `database-design.md` | 表清单、外键与逻辑关联、业务流程、Mermaid ER 图、工具使用说明 |
| `schema-for-er.dbml` | 导入 [dbdiagram.io](https://dbdiagram.io) 生成可导出图片的 ER 图 |
| `schema-clean-for-er.sql` | 无 DROP、无动态 SQL 的建表脚本，便于导入空库后用 Navicat / Workbench 逆向 |
