---
title: revali ai
description: Install a Revali reference file for your AI coding assistant
---

`revali ai` writes a Revali reference file for an AI coding assistant. The file covers project layout, `revali.yaml`, annotations, binding, lifecycle components, constructs and the CLI, so the assistant has accurate context about Revali.

```bash
dart run revali ai claude
dart run revali ai all
```

| Subcommand | Writes |
| --- | --- |
| `claude` | `CLAUDE.md` |
| `cursor` | `.cursor/rules/revali-*.mdc`, one file per topic, each scoped to the files it applies to |
| `copilot` | `.github/copilot-instructions.md` |
| `windsurf` | `.windsurfrules` |
| `cline` | `.clinerules` |
| `all` | All of the above |

## Options

| Flag | Description |
| --- | --- |
| `--force`, `-f` | Overwrites files that already exist. |

Existing files are skipped unless you pass `--force`, so running the command again won't overwrite your edits. Run with `--force` after upgrading Revali to refresh the files:

```text
Created CLAUDE.md
Skipped .cursor/rules/revali-overview.mdc (use --force to overwrite)
```
