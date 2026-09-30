---
name: gops-engineering
description: "Use when working with gops (galaxy-ops): creating/updating/localizing modules, systems and ops projects; module layout and ModelSTD; k8s modules with Helm (helm_ops); the ops-gxl op-flow contract; marking a system as docker-compose type; wiring ${SEC_xxx} secrets; working with sys/sys_model.yml kind, merged_vars.yml, values/value.yml customer overrides, and prj reimport."
---

# Gops Engineering

Use this skill for source-accurate work with `gops` (the `galaxy-ops` CLI).

## Model

Three layers: `Module -> System -> Ops Project`.

- `Module` (`gops mod`): smallest reusable unit (spec, deps, vars, templates, workflows).
- `System` (`gops sys`): composes modules into a deliverable; also supports pure docker-compose systems.
- `Ops Project` (`gops prj`): imports a packaged system for a specific customer/environment.

## CLI commands

### gops mod

- `gops mod new --name <n>` — generates one `mod/<model>/` per supported `ModelSTD`: `arm-mac14-host`, `x86-ubt22-host`, `x86-ubt22-k8s`. Each model dir gets `vars.yml`, `spec/artifact.yml`, `spec/depends.yml`, `workflows/operators.gxl`, `_gal/work.gxl`.
- `gops mod example` — example module (postgresql).
- `gops mod update [--force <0..3>]` — resolve deps/refs; also writes `values/<model>/` templates (`sys_value.yml`, `mod_value.yml`).
- `gops mod localize` — reads `values/<model>/` and writes `mod/<model>/local/`. The declared `--value` / `--default` flags are currently NOT consumed; values always come from `values/<model>/`. Prints a value-change table, then a **file-change table** (`created` / `replaced`, compared by before/after content sha256, so wiping+rebuilding `local/` doesn't false-report unchanged files; deletions are not reported). The header is `<dst> ← <src template>` — a single localize renders several targets (module `spec/` **and** `sys/setting/<mod>`) into the **same** `local/`, so this shows each table's source.
- `gops mod diff [--json]` — read-only value-change table **per model**: initial `mod/<model>/vars.yml` defaults (`mod-default`) vs effective values. Columns `KEY`/`INITIAL`/`EFFECTIVE`/`ORIGIN`/`MUTABILITY`/`STATE` (`same|changed|added|removed`; only non-`same` rows are shown).

### gops sys

- `gops sys new --name <n> [--kind gxl|docker-compose]` — without `--kind` it is **interactive** (choose kind, then `ModelSTD` for `gxl`); `TEST_MODE=1` auto-selects `gxl` + the first supported model. There is currently no `--model` flag.
- `gops sys update [--force]` — resolve vars, generates `sys/merged_vars.yml` and a `values/sys_value.yml` comment template
- `gops sys package [--force] [--output <path>] [--full]` — update then package into `<name>-<version>.tar.gz`; **default packs only git-tracked files** (no artifacts), `--full` packs the whole dir (incl. artifacts/localized output, for air-gapped delivery); writes `deliver.lock` (see Delivery audits). **Both modes exclude paths listed in `sys-prj.yml`'s `ignore:`** (glob, anchored at the system root — bare `mods` matches only root-level, use `**/mods` for any depth; `*` does not cross `/`; a directory pattern like `sys/*/mods` excludes the whole subtree; leading `/` or `./` is normalized). `deliver.lock` is never ignored. Overly broad patterns (`*`) will also drop `sys/merged_vars.yml`.
- `gops sys localize [--mod <module>] [--only]` — by default **always re-resolves first** (the var-resolve stage, i.e. `update` without the localize), so editing `sys/setting/vars.yml` then running `localize` takes effect in one command. Then merges default ⊕ `values/sys_value.yml` ⊕ `values/value.yml` → `.env` (`--only` always skips the resolve step and uses the existing `sys/merged_vars.yml`). Prints a value-change table, plus a **file-change table** for rendered sys-setting templates (`created` / `replaced`, before/after content sha256).
- `gops sys check` — read-only drift check: recompute the merged values and diff against the existing `.env`; exit≠0 when drifted ("values changed but not re-localized"). Also prints `[WARN]` when a var definition is newer than `sys/merged_vars.yml` (definition-level staleness not visible in `.env`); the warning does not change the exit code.
- `gops sys diff [--json]` — read-only **value-change table**: initial `sys/merged_vars.yml` defaults (`sys-defaults`) vs effective values (⊕ `values/sys_value.yml` `sys-setting` ⊕ `values/value.yml` `customer`). Columns `KEY`/`INITIAL`/`EFFECTIVE`/`ORIGIN`/`MUTABILITY`/`STATE`; only non-`same` rows shown. Compares **un-expanded** values (before `${VAR}` eval) to avoid false changes. `gops sys localize` prints the same table at the end. `gops prj diff` is not provided.
  - **gxl systems: module groups.** `sys localize` consumes `values/<mod>/mod_value.yml` per module (`ModuleSpecRef::sys_localize`), so `sys diff`/`localize` also present `[mod: <name>]` groups (initial = `sys/<model>/mods/<mod>/vars.yml`; effective ⊕ `values/<mod>/value.yml` ⊕ `values/<mod>/mod_value.yml` ⊕ the sys layer). A module whose content dir is missing prints `[WARN]` and is skipped (`gops sys update` first).
  - `--json` shape is `{ "system": [...], "modules": [{ "module": …, "changes": [...] }], "files": [{ "target": …, "changes": [...] }] }` (only groups with changes).
  - **File overrides**: `sys diff` also lists files that `sys/setting/<mod>/**` **adds/replaces** relative to the module's `<mod>/spec/**` (both are rendered into `local/` by localize, so this is the file-level configuration delta). Pure path + content (sha256) comparison — no rendering, and independent of the last localize's on-disk state.
  - Value-file keys are **case-insensitive** (normalized to upper on load); before this, lowercase keys like `cpu: 2000` silently did not match `CPU`.
- `gops sys setting --init`

### gops run

Runtime operations on the target system (operator-flow contract); dispatch by `sys/sys_model.yml` `kind` — `gxl` → `gx run <cmd>`, `docker-compose` → a `docker compose` subcommand.

- `gops run download|install|uninstall|start|stop|status|diagnose [--mod <module>] [--env <env>]` (`--env` defaults to `default`). Compose mapping: `download`→`pull`, `install`→`create`, `uninstall`→`down`, `start`→`up -d`, `stop`→`stop`, `status`→`ps`, `diagnose`→`config` (secrets injected as `********` masks).

### gops prj

- `gops prj new --name <n>`, `gops prj import --path <pkg> [--force <0..3>]`, `gops prj update [--force <0..3>]`, `gops prj reimport [--force <0..3>]`.
- `gops prj doctor [--strict]` — check that the project's `values/` is tracked by git (exists, a `values/<sys>/` per imported system, not `.gitignore`d, no uncommitted changes under `values/`); `--strict` escalates warnings to errors (CI gate).

### gops self

- `gops self status` — current version, install dir, and the last self-update state.
- `gops self check [--channel stable|alpha|beta] [--json]` — query the channel manifest for a newer release; `--json` prints a machine-readable blob on a banner-free stdout.
- `gops self update [--channel …] [--to <ver>] [--yes] [--dry-run] [--force]` — download, verify (sha256), install, and back up the current binary; auto-rolls back if the new `--version` health check fails.
- `gops self rollback [--id <14-digit>]` — restore the most recent (or given) backup.
- Source of truth is the same `galaxio-labs/get` manifest as `inst-x.sh gops <channel>`; state/lock/backups live in `~/.galaxy/self_update/gops` (namespaced apart from `gx`).
- Upgrading the binary is only part of the work — see **Upgrading gops** below for the post-upgrade migration steps.

## Upgrading gops

Releases are published per channel (`v<x.y.z>-alpha|beta|stable`) and self-update from the same `galaxio-labs/get` manifest `inst-x.sh` uses:

```bash
gops self check  --channel alpha          # what is available
gops self update --channel alpha --yes    # install + back up the current binary
gops self rollback                        # undo the last update
```

**After upgrading, do this (once per system / project):**

1. **Read that release's notes first** — `galaxy-ops/CHANGELOG.md`, plus `UPGRADE.md` for breaking changes.
2. **Run `gops sys update` on each existing system.** This performs the layout migration and is idempotent: modules materialize under `sys/<model>/mods/<mod>/`, the legacy `sys/mods/` is removed, `.gitignore` gains `sys/*/mods`, and legacy `dst` entries in `sys/setting/list.yml` are rewritten. Reads already fall back to the legacy layout, so systems keep working before you run it — run it anyway, then commit the result.
3. **Re-`localize` and re-check** — `gops sys localize` (and `gops mod localize` for mod repos). The value/file change tables show exactly what moved; afterwards `gops sys check` must be clean (exit 0).
4. **Re-`package`** anything you ship (`gops sys package`) so `deliver.lock` matches the upgraded layout.
5. **Grep your scripts / CI** for the renamed commands and flags (table below).

**Breaking changes to expect (2.x):**

| Change | From → To |
|---|---|
| Runtime ops moved out of `gops sys` | `gops sys start` / `stop` / `status` / `download` / `install` / `uninstall` / `diagnose` → **`gops run <cmd>`** |
| Package mode flag | `sys package --no-git` → `--full` (old name still works as a hidden alias) |
| Module layout | `sys/mods/<mod>/<model>/` → `sys/<model>/mods/<mod>/` (auto-migrated by `sys update`) |
| Op-flow channel | scaffolded `extern` must point at `galaxio-hub/ops-gxl` **`2.0`** (`main` only serves the legacy layout) |
| `sys diff --json` | flat array → `{ "system": [...], "modules": [...], "files": [...] }` |

**Behaviour fixes that change results (not just polish):**

- **Value-file keys are case-insensitive now** (normalized to uppercase on load). Long-standing overrides that “never seemed to apply” because they were written lowercase (`cpu: 2000`) now take effect — after upgrading, re-read `gops sys diff` / `gops mod diff` and confirm the effective values are what you want.
- **`sys check` flags definition staleness**: `[WARN]` when `sys/setting/vars.yml` (or other definitions) is newer than `sys/merged_vars.yml`; it does **not** change the exit code.
- **Downloads no longer leave partial files**: an interrupted `gops run download` / `gx.download` writes `<file>.part` and renames on success. Files truncated by an **older** `gops` are still trusted by `reuse_cache` — delete them (or force a re-download) once after upgrading.

**Version traps:**

- `gxl` dispatch shells out to `$HOME/bin/gx`, so a **stale `gx` on PATH** silently keeps old behaviour; `gx >= 0.13` is required, `>= 0.14` for the `gx run --exists` probe used by docker-compose stage flows.
- Same for `gops` itself: after `self update`, confirm the binary you exercise is the new one (`gops --version` / the `gops: x.y.z` banner).

## Modules (`gops mod`)

### Layout (`gops mod new`)

```
<module>/
├── .gitignore, version.txt, mod-prj.yml      # ModConf (test_envs)
├── _gal/{work.gxl, adm.gxl, project.toml}
└── mod/<model>/
    ├── vars.yml                              # immutable / system / module vars
    ├── spec/{artifact.yml, depends.yml}
    ├── spec/confs/{Chart.yaml,values.yaml,templates/*}   # k8s model only: Helm chart
    ├── workflows/operators.gxl
    ├── _gal/work.gxl
    └── setting.yml                           # k8s model: [[ ]] labels + excludes templates/
```

- `gops mod update [--force <0..3>]` writes `values/<model>/{sys_value.yml, mod_value.yml}`.
- `gops mod localize` renders `spec/*` → `local/*` and writes `mod/<model>/_used.json`. The `--value` / `--default` flags are declared but **NOT consumed**; values always come from `values/<model>/`.
- Order matters: run `gops mod update` **before** `gops mod localize` — localize reads `values/<model>/sys_value.yml`, which `update` creates (otherwise it fails `read file ... sys_value.yml`).
- `gops mod example` emits only the *spec* tree (`spec/`, `workflows/`, `mod/…`) with no `mod-prj.yml`, so it is not directly runnable — but it *does* generate the k8s Helm chart.

### Building a mod from a real upstream repo

End-to-end recipe (verified against `wp-labs/warp-parse` and `wp-labs/warp-fusion`):

1. **Resolve the upstream coordinates first — do not guess:**
   - latest git tag: `git ls-remote --tags --refs <repo-url> | sed 's#.*/##' | sort -V | tail`
   - release artifacts: `GET https://api.github.com/repos/<owner>/<repo>/releases/tags/<tag>` → `assets[].name` (or the project's `dist/install-manifest.json`); download url is `https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>`.
   - container image + tags: the registry packages page, e.g. `https://github.com/<owner>/<repo>/pkgs/container/<repo>`.
   - **Tag gotcha:** the release notes may print `docker pull ...:<tag>` with a `v` the registry tag does not have (`v0.27.1-alpha` vs the real `0.27.1-alpha`). Verify before writing the k8s artifact: `docker manifest inspect ghcr.io/<owner>/<repo>:<tag>`.
2. **Scaffold:** `gops mod new --name <mod>`.
3. **Fill `mod/<model>/spec/artifact.yml`:**
   - host models → **prebuilt release artifact** (http archive) — **preferred**:
     ```yaml
     - name: <mod>
       version: <version>                 # e.g. 0.27.1-alpha
       origin_addr:
         url: <release-asset-url>         # https://github.com/<owner>/<repo>/releases/download/<tag>/<asset>
       cache_enable: false
       local: <asset>.tar.gz              # cached under local/cache/
     ```
     Asset names are `<proj>-<tag>-<target>.tar.gz`. Platform→target: `arm-mac14-host` → `aarch64-apple-darwin`,
     `x86-ubt22-host` → `x86_64-unknown-linux-gnu` (`aarch64-unknown-linux-gnu` ships too, but no ModelSTD maps to it).
     These tarballs expand to an `artifacts/` root, so `install` is just extract + copy:
     ```gxl
     gx.cmd ( "tar -xzf ${cache_dir}/${ITEM.LOCAL} -C ${pkg_dir}" );
     gx.cmd ( "install -m 0755 ${pkg_dir}/artifacts/* ${bin_dir}/" );
     ```
   - host models → git source (alternative; `install` must **build** it — needs a toolchain, avoid when a release exists):
     ```yaml
     - name: <mod>
       version: <version>
       origin_addr:
         repo: <repo-url>
         tag: v<version>
       local: <mod>                       # cache dir name under local/cache/
     ```
   - k8s model → image artifact:
     ```yaml
     - name: <owner>/<repo>
       version: <version>
       origin_addr:
         url: <registry>                  # e.g. ghcr.io
       cache_enable: false
       local: docker_image
     ```
4. **Fill `mod/x86-ubt22-k8s/vars.yml`** so the chart renders the real image:
   - `immutable:` `IMAGE_REPOSITORY = <owner>/<repo>` (module identity, not overridable)
   - `module:` `IMAGE_TAG = "<version>"`, `APP_NAME`, `NAMESPACE`, `IMAGE_REGISTRY`, `IMAGE_PULL_SECRET`, `REPLICA_COUNT`, `SERVICE_TYPE`, `SERVICE_PORT`
   - `system:` `RUNTIME`, `AIR_GAPPED`, `KUBECONFIG`
   - `IMAGE_REGISTRY` must match the artifact registry (e.g. `ghcr.io`).
5. **Render & inspect:** `gops mod update` then `gops mod localize`
   - host: `mod/<model>/local/artifact.yml`
   - k8s: `mod/x86-ubt22-k8s/local/confs/values.yaml` → `image: "<registry>/<owner>/<repo>:<version>"`; `templates/` copied verbatim.
6. **Real end-to-end check (host):** `gx run -e <env> download` then `gx run -e <env> install`; then
   `mod/<model>/local/bin/<bin> --version` should match the pinned version. Under a system, `download` clones the tag into the **host-level shared** cache `sys/<model>/local/cache/<mod>` (verify with `git -C sys/<model>/local/cache/<mod> describe --tags`); standalone falls back to the module-local `local/cache/<mod>`.
   k8s `download`/`install` need docker/helm/kubectl.

Notes / gotchas:

- **`IMAGE_TAG` MUST be `module` scope** (overridable for upgrades); `IMAGE_REPOSITORY` stays `immutable`. Older modules put `IMAGE_TAG` under `immutable` — if you inherit one, move it to `module`.
- Changing a var's scope does **not** rewrite existing `values/<model>/` files: `init_setting_value` writes them only when `sys_value.yml` is absent. To regenerate after a scope change, delete `values/<model>/` and re-run `gops mod update` + `gops mod localize`; the resulting `.used_value.yml` shows each var's true `origin` (e.g. `mod-setting`).
- The module `.gitignore` ignores `**/local`, `.*`, `artifacts` — the clone cache under `local/cache/` stays out of git.
- `gops mod localize` requires a prior `gops mod update` (see Layout above).

### `gops mod localize` semantics (and why order matters)

`gops mod localize` **cleans `local/` first** (`make_clean_path`), then renders `spec/` → `local/`.
So the runtime order is **localize → download → install → start**; re-running `localize` wipes
`local/cache` (downloads), `local/bin` (installed binaries) and `local/run`.

`mod/<model>/setting.yml` controls rendering:

- `localize.templatize_path.excludes` → matching paths are **copied verbatim, not rendered** (this is how
  k8s models keep Helm `{{ }}` intact in `spec/confs/templates`). It is **not** "omit from output".
- `localize.templatize_path.includes` → whitelist; files that don't match are skipped (`is_include` false). Empty ⇒ all included.
- No config omits a path from the output entirely — directories are always created; only files are filtered.
- Matching is `PathBuf::starts_with` **or** glob; paths are relative to the model dir (e.g. `spec/confs/templates`, `spec/conf/.run`).
- `templatize_cust` default is unset ⇒ only Handlebars `{{ }}` is processed (TOML `[[table]]` like `[[stat.pick]]` stays intact);
  set `label_beg`/`label_end` to `[[`/`]]` to render `[[VAR]]` (what k8s models do).

Exclude binary/runtime dirs, or localize aborts on them:

```yaml
localize:
  templatize_path:
    excludes:
    - spec/conf/.run          # binary sqlite/lock → otherwise "stream did not contain valid UTF-8"
```

### Host runtime ops (`start` / `stop`)

The scaffold leaves `install` / `start` / `stop` as no-ops (`empty_operators` subclass); fill them per module.

- `start` (daemon): guard the binary + work-root, idempotent "already running" check, then background:
  `nohup <bin> daemon --work-root <abs> > <log> 2>&1 < /dev/null & echo $! > <pid>`.
  Some apps **require an absolute work-root** — compute `root=$(cd <dir> && pwd)`.
- `stop`: `cat` the pid file → `kill` → **wait for exit** → remove the pid file. The wait matters:
  without it, `gx run stop && gx run start` races on the app's per-work-root lock
  (`<work-root>/.run/.lock`) and the new instance exits non-zero (`another wparse instance is already using work-root`).
- Silence the command echo in `gx.shell`/`gx.cmd` with `silence: "true"` (see the separate **gx-skills** collection, skill `gxl-authoring`: https://github.com/galaxio-labs/gx-skills),
  otherwise the whole shell one-liner is printed and the real one-line status is buried.

### Embedded app project: make `spec/` the work-root (no extra subdir)

When a host module ships an app project (e.g. warp-parse's work-root: `conf/`, `connectors/`, `models/`, `topology/`):

- **Put the project directly under `spec/`** — do **not** wrap it in a subdirectory. A wrapper (e.g. `spec/conf/`)
  just yields a confusing `spec/conf/conf/…` plus an extra indirection. `localize` turns `spec/` into `local/`, so:
  - `work_root = "${local_dir}"` — the app then reads `local/conf/wparse.toml`, `local/connectors/`, …
  - `setting.yml` excludes the runtime dir at its real path: `spec/.run`.
- The app's **own** config dir (`conf/` for warp-parse) must still exist inside the work-root — that layer is an
  app convention, not something gops added; only the gops-side wrapper is dropped.
- Side effect: the work-root (`local/`) then also holds the module's `cache/`, `bin/`, `pkg/`, `run/` — the app
  ignores the extra directories, so this is fine.

### `ModelSTD` = `CpuArch × OsCPE × RunSPC`

Supported: `arm-mac14-host`, `x86-ubt22-host`, `x86-ubt22-k8s` (`RunSPC` = `host` | `k8s`).

- `host` (binary): OS + arch matter — the artifact is OS/arch specific (e.g. `...-x86_64-unknown-linux-gnu.tar.gz`).
- `k8s` (container): the container OS is baked into the image; what matters is **arch** (amd64/arm64) and container-OS family (linux), not the host `OsCPE`. A multi-arch image tag resolves per node at pull time. (There is currently no `arm + k8s` model.)

### Module op-flow contract (ops-gxl)

Module flows follow the `empty_operators` contract: `download / install / start / stop / restart / update / status / uninstall` (defaults are no-ops that echo `need Todo....`). `mod_ops` dispatches system-level ops to `./mod/<model>` per env.

Host-model scaffold (`empty_operators` subclass) that `gops mod new` writes:

- `download` reads `local/artifact.yml` and fetches each artifact **either** a git repo (`origin_addr.repo` + optional `origin_addr.tag` → `git clone --depth 1 [--branch <tag>]`) **or** an HTTP(S) archive (`origin_addr.url` → `gx.download`). It `rm -rf`s the target cache dir first, so re-download is idempotent. When run under a system (i.e. `ENV_SYS_MODEL` is defined) the cache is **host-level and shared per model**: `sys/<model>/local/cache/`; standalone falls back to the module-local `local/cache/`.
- `install` is intentionally empty — fill it per module (build/install the binary).
- Both the host and k8s externs point at `galaxio-hub/ops-gxl` and share the `${GXL_CHANNEL:main}` channel var.

### k8s module with Helm (`helm_ops`)

The canonical k8s pattern (as in `galaxio-hub/victoria-logs`):

- `workflows/operators.gxl`:
  ```gxl
  extern mod helm_ops { git = "https://github.com/galaxio-hub/ops-gxl.git", channel = "${GXL_CHANNEL:main}" }
  mod operators : helm_ops { }
  ```
  `helm_ops` implements `download/install/uninstall/update/status` (start/stop/restart are no-ops) via `helm`/`kubectl` (+ `sudo` image save/load scripts for air-gapped).
- `spec/artifact.yml` — the artifact is the **container image**:
  ```yaml
  - name: <repo>
    version: <tag>
    origin_addr:
      url: <registry>
    local: docker_image
  ```
- `spec/confs/` — the Helm chart; `helm_ops` consumes `local/confs/`.
- `setting.yml` — render `values.yaml` with gops `[[ ]]` while excluding Helm's `templates/`:
  ```yaml
  localize:
    templatize_path:
      excludes: [spec/confs/templates]
    templatize_cust:
      label_beg: '[['
      label_end: ']]'
  ```
- `_gal/work.gxl` — define the `SPEC_DIR` env:
  ```gxl
  mod envs { env local { SPEC_DIR = "local"; } env spec { SPEC_DIR = "spec"; } env default : local; }
  ```
- `vars.yml` — convention vars: `APP_NAME`, `NAMESPACE`, `IMAGE_REGISTRY`, `IMAGE_REPOSITORY`, `IMAGE_TAG`, `IMAGE_PULL_SECRET`, `REPLICA_COUNT`, `SERVICE_TYPE`, `SERVICE_PORT`; system `KUBECONFIG`, `AIR_GAPPED`, `RUNTIME`.
- `spec/confs/` scaffold that `gops mod new` writes (auto, for every k8s node, on save):
  - `values.yaml` (gops `[[ ]]` labels): `image: "[[IMAGE_REGISTRY]]/[[IMAGE_REPOSITORY]]:[[IMAGE_TAG]]"`, `imagePullSecret: "[[IMAGE_PULL_SECRET]]"`, `replicaCount`, `service.{type,port}`, `resources`.
  - `templates/deployment.yaml` + `templates/service.yaml` (Helm `{{ }}`): the deployment injects `imagePullSecrets` **only if** `.Values.imagePullSecret` is non-empty.
  - Files are written **only if absent**, so user edits to the chart survive re-`save()` / `gops mod update`.

Rendering: `gops mod localize` → `local/confs/` (values rendered with `[[ ]]`, `templates/` copied verbatim) + `local/artifact.yml`.

The current `galaxy-ops` source scaffolds all of the above for `x86-ubt22-k8s` automatically on `gops mod new` (and `gops mod example`).

> Need a gops var **inside** a Helm template? Wrap it in the outer `[[ ]]` labels: e.g. `image: [[{{ .Values.image }}]]` — gops renders the outer, Helm the inner.

> Template-label clash: gops localize defaults to `{{ }}`, which collides with Helm. That is exactly why k8s models set `setting.yml` to `[[ ]]` and exclude `templates/`.

### ops-gxl source & vendor-cache gotcha

- Two `ops-gxl` repos exist: `galaxy-operators/ops-gxl` (old org, `mod_ops`/`empty_operators`) and `galaxio-hub/ops-gxl` (current, superset incl. **`helm_ops`** and `sys_ops`). Use **`galaxio-hub`**.
- `gx` keys caches by `<repo-basename>.<channel>` **without the org**, so both repos map to the same names. There are **two layers**:
  - `~/.cache/galaxy/<repo>.<channel>` — the git clone/fetch cache;
  - `~/.galaxy/vendor/<repo>.<channel>` — the materialized **work tree that `gx` actually executes scripts/mods from** (it is a git checkout).
- Consequences:
  - Mixing orgs across `extern` lines causes `read mod file fail!` (same cache key, different content).
  - A **stale vendor** keeps running old scripts even after upstream is fixed — `vendor` is what runs, `.cache` only feeds it.
  - Clearing the cache does **not** fix a bug that is still on the remote: `gx` re-clones the same tip. Fix/push upstream **first**, then `rm -rf ~/.cache/galaxy/<repo>.<channel> ~/.galaxy/vendor/<repo>.<channel>` and rerun `gx run`.
  - The vendor work tree is a git checkout: hand-patching files there works only until `gx` refreshes (`checkout/reset`).
- The galaxy-ops **system** template has historically written `sys/workflows/operators.gxl` with the **old org** (`galaxy-operators/ops-gxl`) while module templates use `galaxio-hub/ops-gxl` — fix the generated file (or the template) before running the system via `gx`.
- ops-gxl shell scripts must be **BSD/mawk-portable**: gawk-only constructs (e.g. the 3-arg `match(str,/re/,arr)`) fail on macOS `awk`. (`save_docker_images.sh` had this and broke image packaging on macOS.)

## Building a system from real modules

End-to-end recipe (verified composing `warp-parse` + `warp-fusion` into one `x86-ubt22-k8s` system):

1. **Scaffold:** `TEST_MODE=1 gops sys new --name <sys>` (there is no `--model` yet, so it auto-picks the first supported `ModelSTD` — fix it in the file afterwards).
2. **Pin the target model** in `sys/sys_model.yml` (`model: x86-ubt22-k8s`). Omit `kind` for GXL (only `docker-compose` is serialized).
3. **List the modules** in `sys/mod_list.yml` — each ref has `name` / `addr` / `model` / `enable`. Use a **path address** for local modules (keeps everything offline):
   ```yaml
   - name: warp-parse
     addr: { path: ../warp-parse }   # resolved relative to the cwd of `gops sys update`
     model: x86-ubt22-k8s
     enable: true
   ```
4. **Per-module localize list** `sys/setting/list.yml` (optional): `module -> {enable, localize:{src,dst}}`, where `src` = `${GXL_PRJ_ROOT}/sys/setting/<mod>` and `dst` = `${GXL_PRJ_ROOT}/sys/<model>/mods/<mod>/local/`.
5. `sys/setting/vars.yml` holds **system-level** vars (may be empty).
6. **`gops sys update`** then **`gops sys localize`**:
   - copies each module's `mod/<model>/` into `sys/<model>/mods/<name>/` (modules are grouped by target model);
   - `sys/merged_vars.yml` merges **only the `system`-scope** vars of the modules (module-scope vars are not hoisted);
   - writes per-module `values/<mod>/mod_value.yml`, so two modules with the same var name (e.g. `IMAGE_TAG`) do **not** collide;
   - localize renders each module's `local/` and writes the system `.env`.

Notes:

- For a `kind: gxl` system the scaffold's `sys/docker-compose.yaml` is dead weight (and its demo `${SERVICE_*}` vars are undefined once you empty `sys/setting/vars.yml`) — delete it.
- Point `sys/workflows/operators.gxl` at `galaxio-hub/ops-gxl` (see the ops-gxl gotcha above).
- Only `system`-scope module vars surface in `sys/merged_vars.yml`; per-module (module-scope) vars stay in `values/<mod>/`.

## System type dispatch (`kind`)

`sys/sys_model.yml` has a `kind` field (`gxl` | `docker-compose`). It decides how the `sys` deploy commands dispatch:

| `gops sys` | `kind: gxl` (default) | `kind: docker-compose` |
|---|---|---|
| download | `gx run download` | `docker compose pull` |
| install | `gx run install` | `docker compose create` |
| start | `gx run start` | `docker compose up -d` |
| stop | `gx run stop` | `docker compose stop` |
| uninstall | `gx run uninstall` | `docker compose down` |
| status | `gx run status` | `docker compose ps` |
| diagnose | `gx run diagnose` | `docker compose config` |

- `gxl` dispatches to `$HOME/bin/gx` as `gx run -e <env> -d <debug> [--cmd-arg <mod>] <cmd>` (requires `gx >= 0.13.0`).
- `docker-compose` dispatches to `docker compose` (no `gx` needed); `--mod` is ignored.
- Missing `kind` defaults to `gxl` (backward compatible). For `gxl`, `sys_model.yml` also carries `model`; for `docker-compose` the `kind` line is written and `model` is omitted.
- The compose file is resolved in priority order: `sys/compose.yaml` → `sys/compose.yml` → `sys/docker-compose.yaml` → `sys/docker-compose.yml` → `<root>/compose.yaml` → `<root>/compose.yml` → `<root>/docker-compose.yaml` → `<root>/docker-compose.yml`.
- When the file is under `sys/`, `gops sys` runs `docker compose -f <file> --project-directory <root> <cmd>`: the **project directory is the system root** (project name = root basename; relative mounts and `.env` resolve against the root, not `sys/`). An explicit `-f` disables docker's override auto-merge, so `gops sys` explicitly merges `<sys>/<stem>.override.{yaml,yml}` if present.
- Legacy root layout still works: when the file sits at the system root, `gops sys` passes no `-f`/global args, so `docker-compose.override.yml` auto-merge and the `COMPOSE_FILE` env var behave exactly as before.
- `.env`, `values/` and `sys-prj.yml` stay at the system root regardless of where the compose file lives.

To make an existing docker-compose stack manageable by `gops sys`, mark `kind` in `sys/sys_model.yml`:

```yaml
name: web-stack
kind: docker-compose
vender: ''
```

## Files

- `sys-prj.yml`: `SysConf` (`test_envs`; optional `ignore:` glob list applied by `sys package` in both modes).
- `sys/sys_model.yml`: system definition (`name` / `model` optional / `kind` / `vender`); `kind` defaults to `gxl` and is **omitted from the file when it is `gxl`** (only `docker-compose` is serialized).
- `sys/mod_list.yml`: module list (optional for pure compose).
- `sys/setting/vars.yml`: system variable definitions (source, versioned).
- `sys/merged_vars.yml`: aggregated vars — module vars ⊕ system vars (generated by `sys update`; must be committed — required by `prj import`).
- `sys/workflows/`: GXL ops flows (optional for pure compose).
- `sys/setting/list.yml`: per-module localize list (optional).
- `values/sys_value.yml`: value file generated by `sys update` as a **fully commented template** (inert by default; uncomment to override).
- `values/value.yml`: customer override (versioned — keep this; ignore generated value files).
- `values/<mod>/mod_value.yml`: per-module value templates written by `sys update` (module-scope vars kept **per module**, so same-named vars across modules do not collide).
- `sys/<model>/mods/<name>/`: modules materialized by `sys update` from each ref's `addr`, grouped by target model (gitignored).
- `deliver.lock`: deliver lock written by `sys package` (see Delivery audits).
- `.env`: generated (gitignored), non-secret config only.
- `sys/docker-compose.yaml`: system-level compose definition (`sys new` generates a template). `gops sys` resolves it through a fallback chain (incl. the legacy system-root layout) — see System type dispatch.

## Secrets (docker-compose)

Secrets are NOT written to `.env`. Use `${SEC_xxx}` placeholders in the compose file (`sys/docker-compose.yaml` by default):

- `sys start` loads secrets from `~/.galaxy/sec_value.yml` (or `./.galaxy/sec_value.yml`) via `orion_sec::load_sec_dict()`, injecting `SEC_*` env vars into the `docker compose` subprocess (not persisted to disk).
- Keys normalize to uppercase with a `SEC_` prefix (`db_password` → `SEC_DB_PASSWORD`).
- `sys diagnose` (`docker compose config`) injects masked `********` instead of plaintext.
- `sys localize` exports only non-secret config to `.env`.

## Values / localize flow

1. `sys update` resolves variables → `sys/merged_vars.yml` (system defaults) and generates `values/sys_value.yml` as a **fully commented template** (inert by default): uncomment the entries you want to override.
2. `sys localize` builds `.env` = `sys/merged_vars.yml` defaults ⊕ `values/sys_value.yml` ⊕ `values/value.yml`.

Both value files are **optional and may be partial**: list only the entries you want to override; the rest fall back to the system defaults. In an ops project, put your deltas in `values/<sys_name>/sys_value.yml`.

To see **which** values are overridden and by which layer, use `gops sys diff` (per system) or `gops mod diff` (per module model) — same table `localize` prints at the end.

`sys localize` 默认先解析变量（等价于先跑一次 `sys update`），所以新系统一条 `sys localize` 就够；`--only` 跳过解析（用现有 `sys/merged_vars.yml`，缺失则报错）。显式 `sys update` 仍适用于打包前预解析、打印变量参考等场景。

Inside an ops project: when the system dir sits under a project root whose `ops-prj.yml` lists it, `sys localize` / `sys update` read and write the project values at `values/<sys_name>/` (resolved from `ops-prj.yml`), so customer values win even if `<sys>/values` is not a symlink. Run `gops prj reimport` to (re)establish the `<sys>/values` symlink.

## Delivery audits (drift & lock)

- **`gops sys check`** — read-only **drift** report. Re-computes the merged values (same order as `sys localize`) and diffs them against the existing `<sys>/.env`, printing `KEY: old -> new` / `+key` / `-key`. Exit≠0 when drifted ("values changed but not re-localized"); exits 0 with `[INFO] 尚无 .env 基线` when never localized. No reconcile.
- **`gops sys diff` / `gops mod diff`** — read-only **value-change table** (initial defaults vs effective), answering *which* values are overridden and by which layer (origin) — not the same question as `check` (`.env` drift vs current merge). See CLI section.
- **`deliver.lock`** — written by `gops sys package` at the system root and shipped inside the tarball. Records `lockfile_version` / `name` / `version` / `kind` / `model` / module refs (`name`/`model`/`enable`/`addr`) and `sha256:` fingerprints of `sys/merged_vars.yml` and the whole `values/` tree. Answers "which version, which values"; `generated_at` changes per package (expect churn).
- **`gops prj doctor [--strict]`** — read-only check that a project's customer values are version-controlled (see CLI section).

## prj import / reimport

- `prj import --path <pkg>` imports a packaged system. `<pkg>` must be a local `.tar.gz`, a `.git` / `git@` repo URL, or an http(s) `.tar.gz` / `.git` URL — **NOT a bare directory** (`convert_addr` rejects anything else). The archive must contain a `sys/` dir at its root.
- `prj reimport` re-imports from `ops-prj.yml` `sys_models`, preserving `values/`; import/reimport create `<sys>/values` as a symlink to `<project>/values/<sys_name>`.
- `ops-prj.yml` merged the old `ops-systems.yml` (fields: `name` + `work_envs` + `sys_models`).

## Pitfalls

- Generated files under `values/` are overwritten by `sys update`; keep customer overrides in `values/value.yml` or list them in `values/sys_value.yml` (partial is fine — the rest come from `sys/merged_vars.yml`).
- `prj import` requires `sys/merged_vars.yml` (generated by `sys update`) to be in the package. `sys package` runs `update` first, but by default packs **only git-tracked files** — so `sys/merged_vars.yml` (and anything else the customer needs) must be **committed**; use `--full` to pack the working tree as-is (incl. artifacts).
- A stale PATH `gops` may be an old version; build and use `target/debug/gops` (1.3.0+) for docker-compose type dispatch.
- `gxl` dispatch shells out to `$HOME/bin/gx` and checks `gx >= 0.13.0`; if the version check fails the deploy commands abort before running.
