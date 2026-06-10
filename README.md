# Warehouse Demo

Warehouse  是一个面向数仓脚本管理的本地代码快照工具。它不直接承载业务开发，而是把每次从服务器下载下来的 SQL、Python、Shell 等脚本同步到统一入口，并基于 Git 记录版本、差异和回滚路径，为 AI agent 提供统一的代码阅读入口。

## 项目定位

在数仓开发和排查过程中，服务器脚本经常以“下载包”的形式流转。如果每次下载都散落在不同目录里，就很难回答这些问题：

- 这次下载和上次相比改了哪些脚本？
- 某个表、字段或 SQL 片段当前到底在哪个版本里？
- 如果误同步了一个不完整下载包，如何快速恢复？
- AI agent 读代码时，应该读取哪一份才是最新快照？

本项目把这些问题抽象成一个轻量级快照库：以 `current/` 作为唯一代码阅读入口，以 `reports/` 保存每次同步后的差异报告，以 Git 作为底层版本和回滚能力。

## 核心逻辑

- **复用 Git 的版本能力**：不重新发明版本系统，而是把服务器代码同步结果提交成 Git 快照，复用 Git 提交历史、diff、审计和 revert 能力。
- **用 just 封装复杂操作**：把 `rsync`、`git diff`、`git add`、`git commit` 等命令收敛成 `just sync`、`just recent`、`just rollback`，降低日常使用成本。
- **统一 AI 代码入口**：约定 agent 只读取 `current/`，避免在多个下载目录之间误读旧代码或半成品代码。
- **自动生成差异报告**：每次同步后把变化文件列表和详细 diff 写入 `reports/`，便于快速 review 本次服务器代码变化。
- **明确 Git 管理边界**：真实项目中 Git 只跟踪 `current/` 和 `reports/`；本展示版为了作品集可读性，额外纳入 README、justfile、CLAUDE.md 和 docs。
- **支持误操作恢复**：通过 `just rollback` 基于 `git revert` 撤销最近一次提交，适合处理误同步、不完整下载包等场景。

## 目录结构

```text
warehouse-demo/
  current/                  # 脱敏后的示例代码快照；agent 默认从这里读代码
  reports/                  # 示例差异报告，包括变化文件列表和详细 diff
  sample-source/            # 可选：本地同步输入目录，不提交真实下载包
  docs/                     # 项目说明和设计共识
    consensus/              # 项目长期共识
    guides/                 # 操作指南
  justfile                  # 同步、搜索、查看差异等快捷命令
```

## Git 管理范围

本展示仓库会纳入项目说明、命令脚本、示例快照和示例报告，目的是让读者完整理解项目架构。真实生产快照库可收紧 Git 范围，只跟踪：

```text
current/
reports/
```

## 常用命令

```bash
just init                    # 第一次初始化快照库，默认读取 sample-source
just init <服务器代码目录>      # 第一次初始化快照库，读取指定目录
just sync                    # 同步新的服务器代码，默认读取 sample-source
just sync <新服务器代码目录>    # 同步指定目录中的新服务器代码
just rollback                # 撤销最近一次提交，恢复到上一次提交前的内容
just search <关键词>           # 在 current/ 中搜索表名、字段名或 SQL 片段
just recent                   # 查看最近一次同步的文件变化
just recent-detail            # 查看最近一次同步的详细差异
just versions                 # 查看历史快照版本
just status                   # 查看 current/ 和 reports/ 是否有未提交变化
just repo-status              # 查看整个仓库是否有未提交变化
```

## 脱敏说明

- 示例表名统一使用 `ods_demo_*`、`dwd_demo_*`、`ads_demo_*`。
- 示例路径统一使用 `job_demo_*`。
- 示例脚本只表达数仓任务结构和同步管理思路，不对应任何真实生产逻辑。
- 示例差异报告为手工构造，用于展示 `reports/` 的用途。
