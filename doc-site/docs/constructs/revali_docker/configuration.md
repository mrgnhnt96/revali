---
description: Configure the Revali Docker construct
---

# Configuration

The Revali Docker construct can be enabled/disabled and configured using the [revali.yaml][revali-yaml] file.

[revali-yaml]: ../../revali/revali-configuration/overview.md

## Revali YAML

The Revali Docker construct is enabled by default, but you can disable it by setting the `enabled` property to `false`.

```yaml title="revali.yaml"
constructs:
    - name: revali_docker
        package: revali_server
        enabled: false
```
