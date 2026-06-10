# just 使用说明

本项目用 `justfile` 把同步服务器代码、生成差异报告、查看历史版本和回滚误操作封装成简单命令。

## 核心命令

| 命令 | 含义 |
| --- | --- |
| `just init` | 第一次初始化快照库，默认读取 `sample-source` |
| `just sync` | 后续同步新的服务器代码，默认读取 `sample-source` |
| `just rollback` | 撤销最近一次提交，恢复到上一次提交前的内容 |
| `just recent` | 查看最近一次同步改了哪些文件 |
| `just recent-detail` | 查看最近一次同步的详细差异 |
| `just versions` | 查看历史快照版本 |
| `just search <关键词>` | 在 `current/` 中搜索表名、字段名或 SQL 片段 |

## 设计思路

`rsync` 负责把输入源目录同步成 `current/`，Git 负责记录每一次快照和差异。`reports/` 保存同步后的差异报告，便于 review 本次变化。

`just rollback` 基于 `git revert --no-edit HEAD`，用于撤销最近一次提交。它不会删除历史，而是在当前分支新增恢复提交。
