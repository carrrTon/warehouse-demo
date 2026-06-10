set shell := ["bash", "-cu"]

server_code_dir := "sample-source"

# 显示可用命令
help:
    @just --list

# 初始化本地代码快照库
# 用法：just init [服务器代码目录]
init source=server_code_dir:
    @test -d "{{source}}" || (echo "错误：源目录不存在：{{source}}" && exit 1)
    @mkdir -p current reports docs
    @if [ ! -d .git ]; then git init; fi
    @rsync -av --delete "{{source}}/" current/
    @timestamp=$(date +"%Y-%m-%d-%H%M"); \
      git diff --name-status -- current > "reports/$timestamp-diff-name-status.txt" 2>/dev/null || true; \
      git diff -- current > "reports/$timestamp-diff-detail.txt" 2>/dev/null || true; \
      git add current reports README.md CLAUDE.md justfile docs .gitignore 2>/dev/null || true; \
      git commit -m "server snapshot $timestamp" || true; \
      echo "初始化完成：server snapshot $timestamp"

# 同步新的服务器代码
# 用法：just sync [服务器代码目录]
sync source=server_code_dir:
    @test -d "{{source}}" || (echo "错误：源目录不存在：{{source}}" && exit 1)
    @test -d .git || (echo "错误：当前目录还不是快照库，请先执行 just init <服务器代码目录>" && exit 1)
    @timestamp=$(date +"%Y-%m-%d-%H%M"); \
      before=$(git rev-parse --short HEAD 2>/dev/null || echo "none"); \
      rsync -av --delete "{{source}}/" current/; \
      if [ -z "$(git status --porcelain -- current)" ]; then \
        echo "本次同步完成，但 current/ 与上一个版本没有差异。"; \
      else \
        git diff --name-status -- current > "reports/$timestamp-diff-name-status.txt"; \
        git diff -- current > "reports/$timestamp-diff-detail.txt"; \
        git add current reports; \
        git commit -m "server snapshot $timestamp"; \
        after=$(git rev-parse --short HEAD); \
        echo "同步完成：$before -> $after"; \
        echo ""; \
        echo "本次变化文件："; \
        cat "reports/$timestamp-diff-name-status.txt"; \
        echo ""; \
        echo "差异报告：reports/$timestamp-diff-name-status.txt"; \
      fi

# 恢复到上一次提交前的内容
rollback:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git revert --no-edit HEAD

# 查看最近一次同步改了哪些文件
recent:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git diff --name-status HEAD~1 HEAD -- current || true

# 查看最近一次同步的详细差异
recent-detail:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git diff HEAD~1 HEAD -- current || true

# 查看历史版本
versions:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git log --oneline --decorate --date=format:'%Y-%m-%d %H:%M' --pretty=format:'%h  %ad  %s'

# 查看两个版本之间改了哪些文件
# 用法：just diff-files 旧版本ID 新版本ID
diff-files old new:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git diff --name-status "{{old}}" "{{new}}" -- current

# 查看两个版本之间的详细差异
# 用法：just diff 旧版本ID 新版本ID
diff old new:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git diff "{{old}}" "{{new}}" -- current

# 搜索表名、字段名、SQL 片段
# 用法：just search 关键词
search keyword:
    @if command -v rg >/dev/null 2>&1; then \
      rg -n "{{keyword}}" current; \
    else \
      grep -RIn "{{keyword}}" current; \
    fi

# 查看当前代码快照状态
status:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git status --short -- current reports

# 查看整个仓库状态
repo-status:
    @test -d .git || (echo "错误：当前目录还不是快照库" && exit 1)
    @git status --short
