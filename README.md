# Gops Skills

Focused skills for the Galaxy project toolchain, currently centered on:

- `gops` (`galaxy-ops`) — organizing, configuring and delivering modules, systems and ops projects.
- `gx` (`galaxy-flow`) — defining and running GXL workflows.

The repo is organized as a top-level router skill plus nested tool-specific skills under `skills/`.

## Available Skills

- `gops-skills` — top-level router for Galaxy gops/gx tasks.
- `gops-engineering` — recommended `gops` usage: `mod`/`sys`/`prj`, module layout & `ModelSTD`, building a mod from a real upstream repo (host release artifacts), `gops mod localize` semantics & module runtime ops (`start`/`stop`), k8s modules with Helm (`helm_ops`), the ops-gxl op-flow contract, docker-compose system type dispatch, `${SEC_xxx}` secrets, `sys/sys_model.yml` `kind`, `merged_vars.yml`, `values/value.yml`, `prj reimport`, and upgrading `gops` (self-update + post-upgrade migration checklist).
- `gx-engineering` — recommended `gx` usage: `run`/`adm`/`init`/`mod`/`doc`/`check`/`self`, GXL authoring & pitfalls, built-in `gx.*` capabilities.

## Installation

### With `gops` (recommended)

If you have `gops` installed, use its native installer — no shell script, no `python3` / `ruby`:

```bash
gops self skill install                 # whole collection; auto-detects installed platforms
gops self skill list                    # list installable skills
```

`--source` accepts `owner/repo`, a git URL, or a local checkout; `--ref` selects a branch / tag; `--target codex|claude|zed|all` and `--dir <path>` choose destinations (both repeatable). Every `SKILL.md` frontmatter is validated before installing (built-in YAML parser, no external interpreter).

### With `install.sh`

Use this when you do not have `gops` yet (bootstrapping). Install the whole collection (router + nested skills):

```bash
./install.sh                          # install all available platforms
./install.sh --zed                    # only Zed (~/.agents/skills/)
./install.sh --dir ~/my/skills        # custom directory
```

Install a single skill by name (local checkout first, remote clone fallback):

```bash
./install.sh gops-engineering --codex
./install.sh gx-engineering --claude
```

Remote install (no local checkout):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/galaxio-labs/gops-skills/main/install.sh) gops-engineering
```

See `install.sh --help` for all options.

Before installing, `install.sh` validates the YAML frontmatter of every `SKILL.md` (prefers `python3` + PyYAML, falls back to `ruby` + psych). Invalid frontmatter aborts the install; if neither parser is available it warns and continues.

Environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `GOPS_SKILLS_REF` | Branch or tag to install | `main` |
| `GOPS_SKILLS_SOURCE` | Source GitHub repo | `galaxio-labs/gops-skills` |

## Layout

```text
gops-skills/
├── SKILL.md
├── README.md
├── CHANGELOG.md
├── install.sh
├── version.txt
├── agents/
│   └── openai.yaml
└── skills/
    ├── gops-engineering/
    │   └── SKILL.md
    └── gx-engineering/
        └── SKILL.md
```

## Notes

- Prefer installing the whole collection when you want routing from `gops-skills` to the nested skills.
- When the skill text conflicts with the target repo, `src/` and tests in `galaxy-ops` / `galaxy-flow` remain the source of truth.
