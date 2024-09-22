# Flavors

Some applications may have different configurations for different environments. For example, you may have a development configuration, a staging configuration, and a production configuration. These configurations are called flavors in Revali.

## Creating Flavors

To create a flavor, you can pass the name of the flavor to the `App` annotation:

```dart
@App(flavor: 'development')
class DevApp extends AppConfig {
    ...
}
```

## Using Flavors

To use a flavor, you can pass the name of the flavor to the `revali` command:

```shell
revali dev --flavor=development
```

This will use the configuration for the `development` flavor.

:::caution
Flavors are case-sensitive.
:::