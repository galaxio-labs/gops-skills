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

## Authoring GXL (`gx.shell` / `gx.cmd`)

- Both execute the string via `/bin/sh`, and **echo the whole command** before running it. Hide the echo with
  `silence: "true"` (keeps stdout); `quiet: "true"` does **not** hide it. `stream: "true"` forwards
  stdout/stderr live (use it for long-running commands).
- **No `+` string concatenation** — `"a" + "b"` (even split across lines) is a parse error (`need '}'`). Use one literal.
- **Interpolation:** only `${NAME}` / `${NAME:default}` are GXL-substituted; bare shell constructs
  (`$!`, `$$`, `$(...)`, `$((...))`, `$var`) pass through untouched, so both can mix in one string:
  `gx.shell ( "pid=$(cat ${pid_file}); kill $pid", silence: "true" );`.
- **Backgrounding a daemon:** `nohup <cmd> > <log> 2>&1 < /dev/null & echo $! > <pid>`. Beware `a && b &`:
  `&` binds the whole list, so `mkdir x && cmd &` backgrounds `mkdir` too — split with `mkdir x; …` first.
- `gx.read_file(file:, name:)` loads yaml/json/ini into a variable; `gx.download(url:, local_file:)` fetches a file.
- Envs: `mod envs { env <name> { VAR = "..."; } }`, selected with `gx run -e <name>`. From a **module root**
  the names are those in the root `_gal/work.gxl` (e.g. `arm_mac`, `x86_ubt`, `x86_ubt_k8s`); from a **model dir**
  the model's own `_gal/work.gxl` defines only `local`/`spec`/`default`, so a module-root env name there fails
  with `Environment '<name>' not found`.
- `mod_ops` dispatches an op with `gx.run( local: "./mod/${ENV_MODEL}", env: "${ENV_MODULE_ENV}", flow: "<op>" )`;
  module flows subclass `empty_operators` and tag overrides with `#[task(name="gops@<op>")]`.

## Relationship to gops

- `galaxy-flow` (`gx`) defines and executes workflows; `galaxy-ops` (`gops`) organizes and delivers modules, systems and projects.
- A `gxl`-type system in gops dispatches `sys start/stop/...` to `gx` (specifically `gx run -e <env> -d <debug> [--cmd-arg <mod>] <cmd>`), and `gops` requires `gx >= 0.13.0` at `$HOME/bin/gx`.

## Pitfalls

- `gx run`/`gx adm` read `./_gal/*.gxl` relative to the current directory; run from the project root.
- AI ability is currently degraded (`ai_diagnose` is a no-op; `gx.ai_chat` is not a built-in block ability).
