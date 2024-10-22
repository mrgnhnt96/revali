# Public Files

The `public` directory is a special directory used to store static files that are directly served by the server. Any file placed in this directory is accessible by anyone, making it ideal for assets like images, icons, and other public resources.

## Usage

The `public` directory is automatically mapped to the server's root, even if you have defined an [application prefix](/revali/app-configuration/overview)

### Example

```plaintext
public/
    favicon.ico
    robots.txt
    images/
        logo.png
```

If you're running Revali locally, the `favicon.ico` and other files in the `public` directory are accessible via URLs like:

```http
http://localhost:3000/favicon.ico
http://localhost:3000/images/logo.png
```

:::note
The `public` directory does not use the server's prefix. All files are served from the root path, regardless of any server routing configuration.
:::

:::danger
Avoid placing sensitive or private information in the `public` directory, as it is fully accessible to anyone who knows the URL.
:::
