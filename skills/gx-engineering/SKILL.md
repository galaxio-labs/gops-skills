---
name: gx-engineering
description: "Use when working with gx (galaxy-flow): running GXL workflows with gx run / gx adm, initializing projects, authoring GXL with built-in gx.* capabilities, or troubleshooting gx execution."
---

# Gx Engineering

Use this skill for source-accurate work with `gx` (the `galaxy-flow` CLI).

## Commands

- `gx run [flow]` — run a workflow (default `./_gal/work.gxl`).
- `gx adm [flow]` — run an admin flow (default `./_gal/adm.gxl`).
- `gx init env` — initialize the runtime environment.
- `gx init project [--repo URL] [--path subdir] [--branch B] [--tag T]` — initialize a project.
- `gx mod update` — update project modules.
- `gx doc [topic]` — view GXL/CLI docs.
- `gx check` — check the running environment.
- `gx self check|update|rollback` — self-update.

## Flags

- `-e/--env <name>` — environment (default `default`)
- `-d/--debug <level>` — debug verbosity
- `-c/--conf <file>` — GXL config file
- `--log <module=level,...>` — log config
- `-q/--quiet`
- `--dryrun`
- `--ai`

## Directory conventions

- `./_gal/work.gxl` — workflow entry (`gx run`)
- `./_gal/adm.gxl` — admin flow entry (`gx adm`)
- `./_gal/mods/` — local project modules

## GXL built-ins (`gx.*`)

- `gx.assert`, `gx.cmd`, `gx.echo`
- `gx.read_file`, `gx.read_cmd`, `gx.read_stdin`
- `gx.vars`, `gx.tpl`, `gx.ver`, `gx.run`, `gx.shell`
- `gx.tar` / `gx.untar`
- `gx.download` / `gx.upload`
- `gx.patch_file`
- expression function: `defined(${VAR})`

## Relationship to gops

- `galaxy-flow` (`gx`) defines and executes workflows; `galaxy-ops` (`gops`) organizes and delivers modules, systems and projects.
- A `gxl`-type system in gops dispatches `sys start/stop/...` to `gflow`, which is the `gx`-driven executor.

## Pitfalls

- `gx run`/`gx adm` read `./_gal/*.gxl` relative to the current directory; run from the project root.
- AI ability is currently degraded (`ai_diagnose` is a no-op; `gx.ai_chat` is not a built-in block ability).
