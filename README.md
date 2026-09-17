# Gops Skills

Focused skills for the Galaxy project toolchain, currently centered on:

- `gops` (`galaxy-ops`) — organizing, configuring and delivering modules, systems and ops projects.
- `gx` (`galaxy-flow`) — defining and running GXL workflows.

The repo is organized as a top-level router skill plus nested tool-specific skills under `skills/`.

## Available Skills

- `gops-skills` — top-level router for Galaxy gops/gx tasks.
- `gops-engineering` — recommended `gops` usage: `mod`/`sys`/`prj`, docker-compose system type dispatch, `${SEC_xxx}` secrets, `sys/sys_model.yml` `kind`, `resolved_vars.yml`, `values/value.yml`, `prj reimport`.
- `gx-engineering` — recommended `gx` usage: `run`/`adm`/`init`/`mod`/`doc`/`check`/`self`, GXL authoring, built-in `gx.*` capabilities.

## Installation

Install the whole collection (router + nested skills):

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
