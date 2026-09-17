---
name: gops-skills
description: Use when working with Galaxy project tooling — the gops CLI (galaxy-ops: organizing, configuring and delivering modules, systems and ops projects) and the gx CLI (galaxy-flow: defining and running GXL workflows). This collection routes to nested skills for gops and gx usage.
---

# Gops Skills

Top-level collection for Galaxy project skills: `gops` (galaxy-ops) and `gx` (galaxy-flow).

## Routing

- For `gops` — `gops mod/sys/prj`, docker-compose system type dispatch, `${SEC_xxx}` secrets, `sys/sys_model.yml` `kind`, `resolved_vars.yml`, `values/value.yml` customer overrides, `prj reimport`, and value/localize flows — read `skills/gops-engineering/SKILL.md`.
- For `gx` — `gx run/adm/init/mod/doc/check/self`, GXL workflow authoring, built-in `gx.*` capabilities, and `_gal/` conventions — read `skills/gx-engineering/SKILL.md`.
- If a nested skill references files, resolve them relative to its own directory.
- Do not load every nested skill by default. Pick only the one matching the user's task.

## Workspace Assumptions

- `galaxy-ops` (gops) source: `/Users/zuowenjian/devspace/rust/galaxio/galaxy-ops`
- `galaxy-flow` (gx) source: `/Users/zuowenjian/devspace/rust/galaxio/galaxy-flow`
- Prefer source and tests over stale docs when they disagree.

## Validation

- gops: `cargo build` / `cargo test` in `galaxy-ops`.
- gx: `cargo build` / `cargo test` in `galaxy-flow`.
