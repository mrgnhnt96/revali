# Flavors

Some applications may have different configurations for different environments. For example, you may have a development configuration, a staging configuration, and a production configuration. These configurations are called flavors in Revali.

## Creating Flavors

To create a flavor, you can pass the name of the flavor to the `App` annotation:

:::caution
Flavors are case-sensitive.
:::

```dart title="routes/dev_app.dart"
// highlight-next-line
@App(flavor: 'development')
class DevApp extends AppConfig {
    ...
}
```

```dart title="routes/prod_app.dart"
// highlight-next-line
@App(flavor: 'production')
class ProdApp extends AppConfig {
    ...
}
```

## Using Flavors

To use a flavor, you can pass the name of the flavor to the `revali dev` command:

```bash
revali dev --flavor=development # Uses the DevApp configuration
```

```bash
revali dev --flavor=production # Uses the ProdApp configuration
```
