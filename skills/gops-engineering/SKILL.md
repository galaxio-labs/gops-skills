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
- `gops mod localize` — reads `values/<model>/` and writes `mod/<model>/local/`. The declared `--value` / `--default` flags are currently NOT consumed; values always come from `values/<model>/`.

### gops sys

- `gops sys new --name <n> [--kind gxl|docker-compose]` — without `--kind` it is **interactive** (choose kind, then `ModelSTD` for `gxl`); `TEST_MODE=1` auto-selects `gxl` + the first supported model. There is currently no `--model` flag.
- `gops sys update [--force]` — resolve vars, generates `sys/merged_vars.yml` and a `values/sys_value.yml` comment template
- `gops sys package [--force] [--output <path>]` — update then package into `<name>-<version>.tar.gz`
- `gops sys localize [--mod <module>] [--only]` — auto `update` if values missing, then merge default ⊕ `values/sys_value.yml` ⊕ `values/value.yml` → `.env` (`--only` skips update)
- `gops sys setting --init`
- `gops sys download/install/start/stop/uninstall/status/diagnose [--mod <module>] [--env <env>]` (`--env` defaults to `default`)

### gops prj

- `gops prj new --name <n>`, `gops prj import --path <pkg> [--force <0..3>]`, `gops prj update [--force <0..3>]`, `gops prj reimport [--force <0..3>]`.

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
   - container image + tags: open the registry packages page, e.g. `https://github.com/<owner>/<repo>/pkgs/container/<repo>` (GHCR lists `latest` and version tags).
   - The git tag and image tag normally share the version (tag `v0.7.0-alpha` ⇔ image `0.7.0-alpha`).
2. **Scaffold:** `gops mod new --name <mod>`.
3. **Fill `mod/<model>/spec/artifact.yml`:**
   - host models → git artifact:
     ```yaml
     - name: <mod>
       version: <version>                 # e.g. 0.27.1-alpha
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
6. **Real end-to-end check (host):** `gx run -e <env> download` clones the tag into `mod/<model>/local/cache/<mod>`
   (verify with `git -C mod/<model>/local/cache/<mod> describe --tags`). k8s `download`/`install` need docker/helm/kubectl.

Notes / gotchas:

- **`IMAGE_TAG` MUST be `module` scope** (overridable for upgrades); `IMAGE_REPOSITORY` stays `immutable`. Older modules put `IMAGE_TAG` under `immutable` — if you inherit one, move it to `module`.
- Changing a var's scope does **not** rewrite existing `values/<model>/` files: `init_setting_value` writes them only when `sys_value.yml` is absent. To regenerate after a scope change, delete `values/<model>/` and re-run `gops mod update` + `gops mod localize`; the resulting `.used_value.yml` shows each var's true `origin` (e.g. `mod-setting`).
- The module `.gitignore` ignores `**/local`, `.*`, `artifacts` — the clone cache under `local/cache/` stays out of git.
- `gops mod localize` requires a prior `gops mod update` (see Layout above).

### `ModelSTD` = `CpuArch × OsCPE × RunSPC`

Supported: `arm-mac14-host`, `x86-ubt22-host`, `x86-ubt22-k8s` (`RunSPC` = `host` | `k8s`).

- `host` (binary): OS + arch matter — the artifact is OS/arch specific (e.g. `...-x86_64-unknown-linux-gnu.tar.gz`).
- `k8s` (container): the container OS is baked into the image; what matters is **arch** (amd64/arm64) and container-OS family (linux), not the host `OsCPE`. A multi-arch image tag resolves per node at pull time. (There is currently no `arm + k8s` model.)

### Module op-flow contract (ops-gxl)

Module flows follow the `empty_operators` contract: `download / install / start / stop / restart / update / status / uninstall` (defaults are no-ops that echo `need Todo....`). `mod_ops` dispatches system-level ops to `./mod/<model>` per env.

Host-model scaffold (`empty_operators` subclass) that `gops mod new` writes:

- `download` reads `local/artifact.yml` and fetches each artifact **either** a git repo (`origin_addr.repo` + optional `origin_addr.tag` → `git clone --depth 1 [--branch <tag>]`) **or** an HTTP(S) archive (`origin_addr.url` → `gx.download`). It `rm -rf`s the target cache dir first, so re-download is idempotent. Cache lands in `local/cache/`.
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

- Two `ops-gxl` repos exist: `galaxy-operators/ops-gxl` (`mod_ops`/`empty_operators`) and `galaxio-hub/ops-gxl` (superset incl. **`helm_ops`**). Use **`galaxio-hub`**.
- `gx`'s vendor cache dir is keyed by `<repo-basename>.<channel>` **without the org** — both repos map to `~/.galaxy/vendor/ops-gxl.git_main`. Mixing orgs causes `read mod file fail!`.
- Fix: point every `extern` at `galaxio-hub/ops-gxl`; if stale, delete `~/.galaxy/vendor/ops-gxl.git_main` and `~/.cache/galaxy/ops-gxl.git_main`, then rerun `gx run`.

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

To make an existing docker-compose stack manageable by `gops sys`, mark `kind` in `sys/sys_model.yml`:

```yaml
name: web-stack
kind: docker-compose
vender: ''
```

## Files

- `sys-prj.yml`: `SysConf` (`test_envs`).
- `sys/sys_model.yml`: system definition (`name` / `model` optional / `kind` / `vender`); `kind` defaults to `gxl` and is **omitted from the file when it is `gxl`** (only `docker-compose` is serialized).
- `sys/mod_list.yml`: module list (optional for pure compose).
- `sys/setting/vars.yml`: system variable definitions (source, versioned).
- `sys/merged_vars.yml`: aggregated vars — module vars ⊕ system vars (generated by `sys update`; must be committed — required by `prj import`).
- `sys/workflows/`: GXL ops flows (optional for pure compose).
- `sys/setting/list.yml`: per-module localize list (optional).
- `values/sys_value.yml`: value file generated by `sys update` as a **fully commented template** (inert by default; uncomment to override).
- `values/value.yml`: customer override (versioned — keep this; ignore generated value files).
- `.env`: generated (gitignored), non-secret config only.
- `docker-compose.yml`: system-level compose definition (`sys new` generates a template).

## Secrets (docker-compose)

Secrets are NOT written to `.env`. Use `${SEC_xxx}` placeholders in `docker-compose.yml`:

- `sys start` loads secrets from `~/.galaxy/sec_value.yml` (or `./.galaxy/sec_value.yml`) via `orion_sec::load_sec_dict()`, injecting `SEC_*` env vars into the `docker compose` subprocess (not persisted to disk).
- Keys normalize to uppercase with a `SEC_` prefix (`db_password` → `SEC_DB_PASSWORD`).
- `sys diagnose` (`docker compose config`) injects masked `********` instead of plaintext.
- `sys localize` exports only non-secret config to `.env`.

## Values / localize flow

1. `sys update` resolves variables → `sys/merged_vars.yml` (system defaults) and generates `values/sys_value.yml` as a **fully commented template** (inert by default): uncomment the entries you want to override.
2. `sys localize` builds `.env` = `sys/merged_vars.yml` defaults ⊕ `values/sys_value.yml` ⊕ `values/value.yml`.

Both value files are **optional and may be partial**: list only the entries you want to override; the rest fall back to the system defaults. In an ops project, put your deltas in `values/<sys_name>/sys_value.yml`.

`sys localize` auto-runs `update` when the system variables are not resolved yet, so a single `sys localize` is enough for a fresh system; `--only` skips the update step. Explicit `sys update` remains useful to pre-resolve before packaging and to print the variable reference.

Inside an ops project: when the system dir sits under a project root whose `ops-prj.yml` lists it, `sys localize` / `sys update` read and write the project values at `values/<sys_name>/` (resolved from `ops-prj.yml`), so customer values win even if `<sys>/values` is not a symlink. Run `gops prj reimport` to (re)establish the `<sys>/values` symlink.

## prj import / reimport

- `prj import --path <pkg>` imports a packaged system. `<pkg>` must be a local `.tar.gz`, a `.git` / `git@` repo URL, or an http(s) `.tar.gz` / `.git` URL — **NOT a bare directory** (`convert_addr` rejects anything else). The archive must contain a `sys/` dir at its root.
- `prj reimport` re-imports from `ops-prj.yml` `sys_models`, preserving `values/`; import/reimport create `<sys>/values` as a symlink to `<project>/values/<sys_name>`.
- `ops-prj.yml` merged the old `ops-systems.yml` (fields: `name` + `work_envs` + `sys_models`).

## Pitfalls

- Generated files under `values/` are overwritten by `sys update`; keep customer overrides in `values/value.yml` or list them in `values/sys_value.yml` (partial is fine — the rest come from `sys/merged_vars.yml`).
- `prj import` requires `sys/merged_vars.yml` to be committed (generated by `sys update`); `sys package` runs `update` first, so packaged systems always contain it.
- A stale PATH `gops` may be an old version; build and use `target/debug/gops` (1.3.0+) for docker-compose type dispatch.
- `gxl` dispatch shells out to `$HOME/bin/gx` and checks `gx >= 0.13.0`; if the version check fails the deploy commands abort before running.
