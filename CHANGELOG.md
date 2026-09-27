# 变更日志

## [0.2.5] - 2026-09-27

### gops-engineering：新增「用真实上游仓库建 mod」工作流

- 新章节 `Building a mod from a real upstream repo`：先核实上游坐标（git tag + 镜像 tag），再填 `artifact.yml`（host=git / k8s=image）、k8s 约定变量、`mod update` + `mod localize` 渲染校验、`gx run download` 端到端验证
- 强调 `IMAGE_TAG` 必须为 `module` 作用域（可覆盖升级）；`IMAGE_REPOSITORY` 保持 `immutable`
- 说明变量作用域变更不会重写已有 `values/<model>/`（需删除后重新 `mod update` + `mod localize`），以及 `.gitignore` 对 `local/cache/` 的排除
- 顶层路由补齐该主题

## [0.2.4] - 2026-09-27

### gops-engineering：对齐 galaxy-ops 的 `gops mod new` 脚手架实现

- 布局补充 k8s 模型的 `spec/confs/`（Helm chart）与 `setting.yml`
- 强调 `mod update` 必须先于 `mod localize`（否则 `values/<model>/sys_value.yml` 缺失）
- 补充 host 模型 `download` 约定：git（`repo[/tag]`）与 http（`url`）双形态、下载前 `rm -rf` 幂等、`install` 为空脚手架
- 明确 host / k8s extern 统一指向 `galaxio-hub/ops-gxl` 与 `${GXL_CHANNEL:main}`
- 补充 chart 脚手架细节：`imagePullSecret` 条件注入、缺文件才写入（保用户修改）、`[[{{ .Values.x }}]]` 嵌套小技巧

## [0.2.3] - 2026-09-27

### 修复

- `install.sh`：整包安装后从目标目录移除 `.git`，不再把 VCS 元数据拷进 skills 目录

## [0.2.2] - 2026-09-27

### gops-engineering：新增 Modules（`gops mod`）知识

- 模块布局（`gops mod new`）、`gops mod update/localize` 产物与 `--value/--default` 未消费
- `ModelSTD = CpuArch × OsCPE × RunSPC`，及其在 host（二进制）/ k8s（容器）下 OS 语义的差异
- 模块算子契约（`empty_operators` / `mod_ops`）
- k8s + Helm 约定（`helm_ops`、镜像式 `artifact.yml`、`spec/confs` chart、`setting.yml` 的 `[[ ]]` + excludes、`SPEC_DIR` env、k8s 约定变量）
- ops-gxl 来源与 `gx` vendor 缓存串味坑（缓存键不含组织，需统一到 `galaxio-hub/ops-gxl`）

## [0.2.1] - 2026-09-27

### 修复

- 修复顶层 `SKILL.md` frontmatter 非法：`description` 未加引号且含 `: `，导致安装后解析报 `invalid YAML frontmatter`
- `install.sh` 新增 `SKILL.md` frontmatter 校验：优先 `python3+PyYAML`，回退 `ruby+psych`；校验失败中止安装，两者都缺失时仅告警不阻断

## [0.2.0] - 2026-09-27

### 对齐 galaxy-ops 当前实现

- `gops-engineering`：`gxl` 分派由旧名 `gflow` 更正为 `gx`，版本要求 `>= 0.13.0`，并补充实际映射 `gx run -e <env> -d <debug> [--cmd-arg <mod>] <cmd>`
- `gops-engineering`：补充 `gops sys new` 的交互 / `TEST_MODE` 行为，以及 `sys update/package/localize/download...` 的 `--force/--output/--mod/--env` 参数
- `gops-engineering`：`gops mod new` 生成三个 `ModelSTD` 目录，`mod localize` 读取 `values/<model>/`，并标注 `--value/--default` 当前未消费
- `gops-engineering`：更正 `values/sys_value.yml` 说明（`sys update` 生成的注释模板），并说明 `sys_model.yml` 的 `kind` 在 `gxl` 时不落盘
- `gx-engineering`：`gflow` 表述更正为 `gx`，补充 `gx >= 0.13.0` 与 `$HOME/bin/gx`
- 顶层 `SKILL.md`：工作区源码路径更新到 `galaxy-labs` 下的当前仓库

## [0.1.0] - 2026-09-17

### 初始版本

- 新增顶层路由 skill `gops-skills`，按任务路由到 gops / gx 子 skill
- 新增 `gops-engineering`：`gops` CLI 用法、系统类型分派（`kind`）、`${SEC_xxx}` 密钥、`merged_vars.yml`、`values/value.yml`、`prj reimport`
- 新增 `gx-engineering`：`gx` CLI 用法、GXL 内建 `gx.*` 能力、`_gal/` 目录约定
- 附 `install.sh`（按 skill 安装 / 整包安装，本地源优先、远程 clone 兜底，支持 codex / claude / zed / 自定义目录）、`agents/openai.yaml` 元数据
