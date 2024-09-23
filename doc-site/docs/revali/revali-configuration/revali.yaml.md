# revali.yaml

## Enable Constructs

By default, all constructs are enabled. To explicitly enable a construct, you can add it to the `constructs` list.

```yaml title="revali.yaml"
constructs:
  - name: revali_docker
    enabled: true
```

### Construct Name Conflicts

Typically, constructs are unique and will not conflict with each other. However, if you find that you have constructs with conflicting names, you can use the `package` field to specify the package that the construct belongs to.

```yaml title="revali.yaml"
constructs:
  - name: revali_docker
    # highlight-next-line
    package: revali_server
    enabled: true
```

:::note
The `package` value is the same as the package name you added in the `pubspec.yaml` file.
:::

## Disable Constructs

To disable a construct, set the `enabled` field to `false`.

```yaml title="revali.yaml"
constructs:
  - name: revali_docker
    # highlight-next-line
    enabled: false
```

## Configure Constructs

Some constructs may offer additional configuration options. To configure a construct, add the `options` field to the construct.

```yaml title="revali.yaml"
constructs:
  - name: revali_docker
    enabled: true
    # highlight-start
    options:
      some-key: "some-value"
      # highlight-end
```

:::note
Typically, the construct's documentation will provide information on the available configuration options.
:::
