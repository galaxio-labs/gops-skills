---
name: gops-skills
description: "Use when working with gops (galaxy-ops): creating/updating/localizing modules, systems and ops projects; module layout & ModelSTD; building mods/systems from real upstream repos; localize semantics; runtime ops; k8s modules with Helm (helm_ops); docker-compose systems; ${SEC_xxx} secrets; and upgrading gops. Routes to the gops-engineering skill."
---

# Gops Skills

Top-level collection for `gops` (galaxy-ops) skills. `gx` (galaxy-flow) skills live separately in https://github.com/galaxio-labs/gx-skills.

## Routing

- For `gops` — `gops mod/sys/prj`, module layout / `ModelSTD`, building a mod from a real upstream repo (host release artifacts), `gops mod localize` semantics (`setting.yml` includes/excludes, the `local/` wipe), module runtime ops + embedded app project layout (`start`/`stop`), building a system from real modules, delivery audits (`gops sys check` drift, `deliver.lock`, `gops prj doctor`), k8s modules with Helm (`helm_ops`), the ops-gxl op-flow contract, docker-compose system type dispatch, `${SEC_xxx}` secrets, `sys/sys_model.yml` `kind`, `merged_vars.yml`, `values/value.yml` customer overrides, `prj reimport`, value/localize flows, and **upgrading gops** (`self update` + the post-upgrade migration checklist) — read `skills/gops-engineering/SKILL.md`.
- For `gx` — GXL workflows and `gx.*` authoring — use the separate **gx-skills** collection: https://github.com/galaxio-labs/gx-skills (skills `gx-cli` / `gxl-authoring`).
- If a nested skill references files, resolve them relative to its own directory.
- Do not load every nested skill by default. Pick only the one matching the user's task.

## Workspace Assumptions

- `galaxy-ops` (gops) source: https://github.com/galaxio-labs/galaxy-ops
- `galaxy-flow` (gx) source: https://github.com/galaxio-labs/galaxy-flow
- Prefer source and tests over stale docs when they disagree.

## Validation

- gops: `cargo build` / `cargo test` in `galaxy-ops`.
