# 变更日志

## [0.1.0] - 2026-09-17

### 初始版本

- 新增顶层路由 skill `gops-skills`，按任务路由到 gops / gx 子 skill
- 新增 `gops-engineering`：`gops` CLI 用法、系统类型分派（`kind`）、`${SEC_xxx}` 密钥、`effective_vars.yml`、`values/value.yml`、`prj reimport`
- 新增 `gx-engineering`：`gx` CLI 用法、GXL 内建 `gx.*` 能力、`_gal/` 目录约定
- 附 `install.sh`（按 skill 安装 / 整包安装，本地源优先、远程 clone 兜底，支持 codex / claude / zed / 自定义目录）、`agents/openai.yaml` 元数据
