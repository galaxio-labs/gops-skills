# 变更日志

## [0.2.9] - 2026-09-30

### gops-engineering：值变更表（`sys diff` / `mod diff`）与文件变更表

- 新增 `gops sys diff [--json]` 与 `gops mod diff [--json]`：只读比对「初始默认值」与「生效值」，逐键列出 `KEY`/`INITIAL`/`EFFECTIVE`/`ORIGIN`/`MUTABILITY`/`STATE`（只列非 `same` 行）；`localize` 结束时打印同一张表
- `localize`（`sys` / `mod`）新增**文件变更表**：渲染落地后报 `FILE | STATE`（`created` / `replaced`），用前后内容指纹（sha256）比对（清空再重建不误报未变文件，删除不报）
- 澄清与 `sys check` 的分工：`check` 看「`.env` 与当前合并值的漂移」，`diff` 看「哪些值被覆盖、被哪一层覆盖（origin）」；新增/替换文件需基线，故只在 `localize` 呈现

## [0.2.8] - 2026-09-28

### gops-engineering：host 内嵌工程直接摊在 `spec/` 下，不再套子目录

- 新增节「Embedded app project: make `spec/` the work-root (no extra subdir)」：host 模块若内嵌一个应用工程（如 warp-parse 的 work-root：`conf/`、`connectors/`、`models/`、`topology/`），应**直接摊在 `spec/` 下**，不要再套一层子目录（否则出现 `spec/conf/conf/…` 这类多余且易混层级）
- localize 后 `spec/` → `local/`，故 `work_root = "${local_dir}"`，`setting.yml` 排除运行时的 `spec/.run`
- 应用自身必需的 `conf/` 层仍保留（app 约定，非 gops 引入）；work-root 与模块的 `cache/bin/pkg/run` 同级，app 会忽略多余目录

## [0.2.7] - 2026-09-28

### gops-engineering：host 模型改用 release 制品；补齐 `mod localize` 语义与运行时 ops

- host 模型 `artifact.yml` 优先用**预编译 release 制品**（http 归档）而非 git 源码：给出 asset 发现方式（releases API / `dist/install-manifest.json`）、`<proj>-<tag>-<target>.tar.gz` 命名、平台→target 映射（`arm-mac14-host`→`aarch64-apple-darwin`、`x86-ubt22-host`→`x86_64-unknown-linux-gnu`），`install` 只需解包 `artifacts/*`；git 形态保留为备选（需自行 build，需工具链）
- tag 坑：release notes 里的 `docker pull ...:v<ver>` 可能多带 `v`，实际镜像 tag 无 `v`，用 `docker manifest inspect` 核实
- 新增「`gops mod localize` semantics」：`setting.yml` 的 `excludes` 是**原样 copy（非渲染）**、`includes` 是白名单、无法整目录省略；`templatize_cust` 默认仅处理 `{{ }}`（TOML `[[table]]` 安全）；排除 `.run/` 等二进制/运行时目录，否则报 `stream did not contain valid UTF-8`
- **重要**：`gops mod localize` 会先 `make_clean_path(local/)` 清空 `local/`，故运行顺序为 **localize → download → install → start**；重跑 localize 会清掉 `local/bin`、`local/cache`
- 新增「Host runtime ops (`start`/`stop`)」：后台 `nohup … & echo $! > <pid>`、work-root 需**绝对路径**、`stop` 必须**等进程退出**（否则 `stop && start` 撞 `<work-root>/.run/.lock`）

### gx-engineering：新增「Authoring GXL (`gx.shell`/`gx.cmd`)」

- `silence: "true"` 隐去命令回显（`quiet: "true"` 无效）；不支持 `+` 字符串拼接；仅 `${NAME}` 插值，裸 `$!`/`$$`/`$(...)`/`$var` 透传给 `/bin/sh`；`a && b &` 会整串后台化；env 名在 module root 与 model dir 下不同；`#[task(name="gops@<op>")]`

### 其它

- Workspace Assumptions 改为 GitHub 地址（`galaxio-labs/galaxy-ops`、`galaxio-labs/galaxy-flow`），不再写本机绝对路径

## [0.2.6] - 2026-09-27

### gops-engineering：对齐 galaxy-ops 1.3.2，补充系统组合与交付审计知识

- CLI：新增 `gops sys check`、`gops prj doctor [--strict]`；`sys package` 说明会生成 `deliver.lock`
- 新增「Building a system from real modules」：`sys new` → 改 `sys_model.yml`/`mod_list.yml`(路径地址)/`setting/list.yml` → `sys update` + `sys localize`，以及变量分层（只有 `system` 作用域模块变量进 `merged_vars.yml`；模块变量按 `values/<mod>/` 分目录、不串味）
- 新增「Delivery audits (drift & lock)」：`sys check` 漂移报告、`deliver.lock` 内容与指纹、`prj doctor`
- 重写 ops-gxl 缓存小节：区分 `.cache/galaxy`（fetch 缓存）与 `.galaxy/vendor`（实际执行的 work tree）；清缓存不能修未推送的 bug；vendor 是 git 工作区会被刷新覆盖；系统模板旧组织 `galaxy-operators/ops-gxl` 坑；ops-gxl 脚本需 BSD/mawk 可移植（gawk 专有 `match(...,arr)` 会在 macOS 崩）
- Files 补充 `values/<mod>/mod_value.yml`、`sys/mods/`、`deliver.lock`

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
