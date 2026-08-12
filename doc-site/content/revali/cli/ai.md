---
title: revali ai
description: Install a Revali reference file for your AI coding assistant
---

The `revali ai` command installs a Revali framework reference file for an AI coding assistant — project structure, `revali.yaml`, annotations, binding, lifecycle components, constructs, and the CLI — so the assistant has accurate context instead of guessing at Revali's API.

## Basic Usage

```bash
dart run revali ai <tool>
```

## Subcommands

| Subcommand | Installs |
| --- | --- |
| `claude` | `CLAUDE.md` |
| `cursor` | `.cursor/rules/revali-*.mdc` — one file per topic, each scoped with a glob so it only auto-attaches for relevant files |
| `copilot` | `.github/copilot-instructions.md` |
| `windsurf` | `.windsurfrules` |
| `cline` | `.clinerules` |
| `all` | Every file above, in one run |

```bash
dart run revali ai claude
dart run revali ai all
```

## Options

| Flag | Description |
| --- | --- |
| `--force`, `-f` | Overwrite a reference file that already exists. Without it, existing files are left untouched and reported as skipped. |

## Behavior

Each file is only written if it doesn't already exist — safe to run against a project that already has a `CLAUDE.md` or `.cursor/rules/` from something else, and safe to re-run without clobbering edits you've made to the installed file. Pass `--force` to regenerate it after a Revali upgrade.

```text
Created CLAUDE.md
Skipped .cursor/rules/revali-overview.mdc (use --force to overwrite)
```

## Next Steps

- **[The Doctor Command](/revali/cli/doctor)**: Diagnose SDK, construct, and generated-output issues
- **[revali.yaml](/revali/revali-configuration)**: Enable, disable and configure constructs
