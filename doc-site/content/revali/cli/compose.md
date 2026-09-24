---
title: revali compose
description: Generate a docker-compose.yaml for every service in a repository
---

`revali compose` writes a `docker-compose.yaml` that includes every Revali service in the repository. Use it to run all of your services in containers. [`revali_docker`](/constructs/revali_docker) builds each service's image, and this file runs them together.

```bash
dart run revali build        # in each service, so it has .revali/build/Dockerfile
dart run revali compose
docker compose up
```

```text
✓ Wrote 3 service(s) to /repo/docker-compose.yaml
```

## Output

<CodeFile name="docker-compose.yaml">

```yaml
services:
  orders:
    build:
      context: services/orders
      dockerfile: .revali/build/Dockerfile
    environment:
      PORT: '8080'
    ports:
      - '8080:8080'
    restart: unless-stopped

  billing:
    build:
      context: services/billing
      dockerfile: .revali/build/Dockerfile
    environment:
      PORT: '8081'
    ports:
      - '8081:8081'
    restart: unless-stopped
```

</CodeFile>

- Services come from [`revali services`](/revali/cli/services). Ports are assigned in the same order, starting at `--base-port`, so each service gets the same port here as in `revali up`.
- The port is passed as `PORT`. A service reads it only when its app uses [`AppConfig.fromEnv`](/revali/app-configuration/env-vars#appconfigfromenv). A service that sets `port` directly listens on a port the mapping doesn't point to.
- A service without a Dockerfile is still included, with a comment, and the command prints a warning that names it.
- Package names aren't unique across a repository. When two services have the same name, the compose key is built from each service's path instead (for example `examples-hello`), so neither overwrites the other.

## Keeping Your Own Additions

Every run overwrites the file. Put your own services and settings in `compose.override.yaml`, which Docker Compose merges in automatically:

<CodeFile name="compose.override.yaml">

```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'

  orders:
    environment:
      REDIS_HOST: redis
```

</CodeFile>

## Options

| Flag | Default | Description |
| --- | --- | --- |
| `--root <path>` | working directory | Where to start looking for services. |
| `--output`, `-o <path>` | `docker-compose.yaml` in the root | Where to write the file. |
| `--base-port <port>` | `8080` | The first host port to assign. Each following service gets the next port. |
| `--stdout` | off | Prints the file instead of writing it. |
