---
title: Fly.io Deployment
description: Deploy your Revali application to Fly.io with global edge deployment
---

# Deploy to Fly.io

[Fly.io](https://fly.io/) is a platform for running full-stack applications globally. It deploys your app close to users by running instances in multiple regions worldwide, providing low latency and high availability.

## Why Fly.io?

**Perfect for Revali applications:**

- **Global Edge Deployment** - Deploy to 30+ regions worldwide
- **Automatic HTTPS** - Free SSL certificates with automatic renewal
- **Zero-Downtime Deploys** - Rolling deployments with health checks
- **Built-in Services** - PostgreSQL, Redis, and more
- **Generous Free Tier** - 3 shared VMs with 256MB RAM each
- **Simple Scaling** - Add regions or increase resources with one command

:::tip
Check out [Fly.io's official Dockerfile documentation](https://fly.io/docs/languages-and-frameworks/dockerfile/) for more details.
:::

---

## Prerequisites

Before deploying to Fly.io, ensure you have:

1. ✅ A Revali application with generated Dockerfile (`dart run revali build`)
2. ✅ Git repository (recommended for version control)
3. ✅ Fly.io account (free to create)
4. ✅ Fly CLI installed

---

## Installation

### 1. Create a Fly.io Account

Sign up for a free account at [fly.io/app/sign-up](https://fly.io/app/sign-up).

You'll need to:

- Verify your email
- Add a credit card (required for identity verification, free tier available)

### 2. Install flyctl CLI

The Fly CLI (`flyctl`) is required for deployment.

**macOS:**

```bash
# Using Homebrew (recommended)
brew install flyctl

# Using install script
curl -L https://fly.io/install.sh | sh
```

**Linux:**

```bash
curl -L https://fly.io/install.sh | sh
```

**Windows:**

```powershell
# Using PowerShell
iwr https://fly.io/install.ps1 -useb | iex
```

**Verify installation:**

```bash
flyctl version
```

### 3. Authenticate

Log in to your Fly.io account:

```bash
flyctl auth login
```

This opens your browser for authentication.

---

## Initial Setup

### 1. Generate Dockerfile

If you haven't already, generate your Dockerfile:

```bash
dart run revali build --release
```

This creates `.revali/build/docker/Dockerfile`.

### 2. Move Dockerfile to Project Root

Fly.io expects the Dockerfile in your project root:

```bash
cp .revali/build/docker/Dockerfile ./Dockerfile
```

:::note
You can keep the Dockerfile in `.revali/build/docker/` by specifying the path in `fly.toml`, but moving it to the root simplifies deployment.
:::

### 3. Initialize Fly App

Run the launch command to create your Fly app:

```bash
flyctl launch
```

This interactive command will:

- Detect your Dockerfile
- Suggest an app name
- Select a region
- Offer to set up PostgreSQL (optional)
- Generate a `fly.toml` configuration file

**Example interaction:**

```
? Choose an app name (leave blank to generate one): my-revali-app
? Choose a region for deployment: Los Angeles, California (US) (lax)
? Would you like to set up a Postgresql database now? No
? Would you like to set up an Upstash Redis database now? No
? Would you like to deploy now? No
```

:::tip
Say **No** to "Would you like to deploy now?" - you'll want to review and customize `fly.toml` first.
:::

---

## Configuration

### Understanding fly.toml

The `fly.toml` file configures your Fly.io application. Here's an optimized configuration for Revali:

```toml title="fly.toml"
# App name (must be unique across Fly.io)
app = 'my-revali-app'

# Primary region (closest to most users)
primary_region = 'lax'

# Build configuration
[build]
  # Dockerfile path (default: ./Dockerfile)
  # Uncomment if you keep it in .revali/build/docker/
  # dockerfile = ".revali/build/docker/Dockerfile"

# HTTP service configuration
[http_service]
  # Port your app listens on
  internal_port = 8080

  # Force HTTPS
  force_https = true

  # Auto stop/start machines to save costs
  auto_stop_machines = 'stop'
  auto_start_machines = true

  # Minimum running machines (0 = scale to zero when idle)
  min_machines_running = 0

  # Health check configuration
  [http_service.concurrency]
    type = "requests"
    hard_limit = 250
    soft_limit = 200

# VM configuration
[[vm]]
  memory = '512mb'      # Start small, scale up as needed
  cpu_kind = 'shared'   # Use 'performance' for dedicated CPUs
  cpus = 1
```

### Configuration Options Explained

#### App Settings

```toml
app = 'my-revali-app'           # Unique app name
primary_region = 'lax'          # Primary deployment region
```

**Available regions:**

- `lax` - Los Angeles
- `sjc` - San Jose
- `ord` - Chicago
- `iad` - Ashburn, VA
- `lhr` - London
- `fra` - Frankfurt
- `syd` - Sydney
- [See all regions](https://fly.io/docs/reference/regions/)

#### HTTP Service

```toml
[http_service]
  internal_port = 8080          # Match your app's PORT
  force_https = true            # Redirect HTTP to HTTPS
  auto_stop_machines = 'stop'   # Stop when idle
  auto_start_machines = true    # Start on request
  min_machines_running = 0      # Scale to zero
```

#### VM Resources

```toml
[[vm]]
  memory = '512mb'    # Options: 256mb, 512mb, 1gb, 2gb, 4gb, 8gb
  cpu_kind = 'shared' # Options: shared, performance
  cpus = 1            # Number of CPUs
```

**Resource recommendations:**

| Traffic Level  | Memory | CPUs | Cost/Month |
| -------------- | ------ | ---- | ---------- |
| Development    | 256mb  | 1    | Free       |
| Low Traffic    | 512mb  | 1    | ~$5        |
| Medium Traffic | 1gb    | 1-2  | ~$10-15    |
| High Traffic   | 2gb+   | 2-4  | ~$30+      |

---

## Deployment

### First Deployment

Deploy your application:

```bash
flyctl deploy
```

This will:

1. Build your Docker image
2. Push to Fly's registry
3. Create machines in your selected region
4. Run health checks
5. Route traffic to your app

**Expected output:**

```
==> Building image
...
--> Building image done
==> Pushing image to fly
...
--> Pushing image done
==> Creating release
--> Release created
==> Deploying
--> Deploying done
```

### View Your App

Open your deployed application:

```bash
flyctl apps open
```

Or visit: `https://my-revali-app.fly.dev`

---

## Environment Variables and Secrets

### Setting Secrets

Store sensitive data as secrets:

```bash
# Set individual secrets
flyctl secrets set API_KEY=your_api_key_here
flyctl secrets set DATABASE_URL=postgresql://...

# Set multiple secrets at once
flyctl secrets set \
  API_KEY=your_key \
  JWT_SECRET=your_secret \
  STRIPE_KEY=sk_live_...
```

### Setting Environment Variables

For non-sensitive configuration:

```toml title="fly.toml"
[env]
  PORT = "8080"
  LOG_LEVEL = "info"
  ENVIRONMENT = "production"
```

### Accessing in Your App

```dart
import 'dart:io';

void main() {
  final apiKey = Platform.environment['API_KEY']!;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final logLevel = Platform.environment['LOG_LEVEL'] ?? 'info';
}
```

---

## Database Setup

### PostgreSQL

Create a Fly PostgreSQL database:

```bash
flyctl postgres create
```

Follow the prompts:

```
? Choose an app name: my-app-db
? Select region: Los Angeles, California (US) (lax)
? Select configuration: Development - Single node, 1x shared CPU, 256MB RAM, 1GB disk
```

**Connect to your app:**

```bash
flyctl postgres attach my-app-db
```

This sets a `DATABASE_URL` secret automatically.

**Use in your app:**

```dart
import 'package:postgres/postgres.dart';

final databaseUrl = Platform.environment['DATABASE_URL']!;
final connection = await Connection.open(
  Endpoint.fromUri(Uri.parse(databaseUrl)),
);
```

### Redis

Create a Redis instance with Upstash:

```bash
flyctl redis create
```

Connect to your app:

```bash
flyctl redis attach
```

This sets `REDIS_URL` automatically.

---

## Scaling

### Horizontal Scaling

Add more machines:

```bash
# Scale to 3 machines
flyctl scale count 3

# Scale to specific count per region
flyctl scale count 2 --region lax
flyctl scale count 1 --region lhr
```

### Vertical Scaling

Increase VM resources:

```bash
# Increase memory
flyctl scale memory 1024

# Increase CPUs
flyctl scale vm shared-cpu-2x
```

### Multi-Region Deployment

Deploy to multiple regions for global coverage:

```bash
# Add a region
flyctl regions add lhr    # London
flyctl regions add fra    # Frankfurt
flyctl regions add syd    # Sydney

# List current regions
flyctl regions list

# Set machine count per region
flyctl scale count 2 --region lax
flyctl scale count 2 --region lhr
flyctl scale count 1 --region fra
```

---

## Monitoring and Logs

### View Logs

```bash
# Stream live logs
flyctl logs

# View recent logs
flyctl logs --recent

# Follow logs
flyctl logs -f
```

### Application Status

```bash
# Check app status
flyctl status

# View machine details
flyctl machines list

# Check app metrics
flyctl dashboard
```

### Health Checks

Configure health checks in `fly.toml`:

```toml
[http_service]
  # ... other config ...

  [[http_service.checks]]
    grace_period = "10s"
    interval = "30s"
    method = "GET"
    timeout = "5s"
    path = "/health"
```

**Implement in your app:**

```dart
@Get('/health')
Map<String, dynamic> healthCheck() {
  return {
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'version': '1.0.0',
  };
}
```

---

## Custom Domains

### Add a Domain

```bash
flyctl certs create example.com
flyctl certs create www.example.com
```

### Configure DNS

Add these DNS records:

```
A     @       66.241.124.100
AAAA  @       2a09:8280:1::
A     www     66.241.124.100
AAAA  www     2a09:8280:1::
```

Or use a CNAME:

```
CNAME www   my-revali-app.fly.dev
```

### Verify Certificate

```bash
flyctl certs show example.com
```

---

## CI/CD Integration

### GitHub Actions

Automate deployments with GitHub Actions:

```yaml title=".github/workflows/deploy.yml"
name: Deploy to Fly.io

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Generate Dockerfile
        run: dart run revali build --release

      - name: Copy Dockerfile
        run: cp .revali/build/docker/Dockerfile ./Dockerfile

      - name: Setup Fly CLI
        uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Deploy to Fly.io
        run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

**Setup:**

1. Get your Fly.io API token:

   ```bash
   flyctl auth token
   ```

2. Add to GitHub Secrets:
   - Go to repository Settings → Secrets → Actions
   - Add `FLY_API_TOKEN` with your token

---

## Advanced Features

### Build Arguments

Pass build arguments during deployment:

```bash
flyctl deploy --build-arg API_VERSION=v2
```

**In Dockerfile:**

```dockerfile
ARG API_VERSION
RUN dart compile exe server.dart -DAPI_VERSION=$API_VERSION
```

### Volume Mounts

Create persistent storage:

```bash
# Create a volume
flyctl volumes create data --size 1 --region lax

# Configure in fly.toml
```

```toml
[[mounts]]
  source = "data"
  destination = "/app/data"
```

### Private Networking

Connect services within Fly's private network:

```toml
[env]
  # Use .internal for private network DNS
  REDIS_URL = "redis://my-redis.internal:6379"
```

---

## Cost Optimization

### Free Tier

Fly.io's free tier includes:

- 3 shared-cpu-1x VMs with 256MB RAM
- 160GB bandwidth per month
- Automatic HTTPS

**Optimize for free tier:**

```toml
[[vm]]
  memory = '256mb'
  cpu_kind = 'shared'
  cpus = 1

[http_service]
  min_machines_running = 0  # Scale to zero when idle
```

### Cost-Saving Tips

1. **Scale to zero**: Set `min_machines_running = 0` for development
2. **Right-size VMs**: Start small, scale up as needed
3. **Use auto-stop**: Enable `auto_stop_machines` for low-traffic apps
4. **Consolidate regions**: Start with one region, expand as needed

---

## What's Next?

- **[Deployment Overview](/constructs/revali_docker/deploy/overview)** - Explore other platforms
- **[Docker Configuration](/constructs/revali_docker/configuration)** - Customize your Dockerfile
- **[Revali Build Command](/revali/cli/build)** - Learn about build options

---

## Additional Resources

- [Fly.io Documentation](https://fly.io/docs/)
- [Fly.io Dockerfile Guide](https://fly.io/docs/languages-and-frameworks/dockerfile/)
- [Fly.io Pricing](https://fly.io/docs/about/pricing/)
- [Fly.io Status](https://status.flyio.net/)
