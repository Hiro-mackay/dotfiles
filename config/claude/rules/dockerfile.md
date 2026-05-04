---
name: dockerfile
description: Dockerfile and container build conventions covering layer caching, image size, secret handling, non-root execution, and health checks. Apply when reading, writing, or reviewing Dockerfile, docker-compose, .dockerignore, or containerfile files.
paths:
  - "**/Dockerfile*"
  - "**/docker-compose*"
  - "**/.dockerignore"
  - "**/containerfile*"
---

# Dockerfile & Container Principles

## Multi-Stage Builds
- ALWAYS use multi-stage: builder stage for compile/install, minimal runtime image for deploy
- Runtime image: distroless, alpine, or slim variant. NEVER use full OS images in production
- Copy only artifacts needed at runtime -- no source code, build tools, or dev dependencies

## Layer Cache Optimization
- Order: system deps -> language deps -> application code (least → most frequently changed)
- Copy dependency manifests first (`go.mod`, `package.json`, `requirements.txt`), install, THEN copy source
- Pin base image versions with digest or specific tag -- never `latest`
- Combine related `RUN` commands with `&&` to reduce layers
- Use `--mount=type=cache` for package manager caches (BuildKit)

## Security
- Run as non-root: `USER nonroot:nonroot` or numeric UID (e.g., `USER 65534`)
- No secrets in image: use build-time secrets (`--mount=type=secret`) or runtime env vars
- Read-only filesystem where possible: `--read-only` flag in docker-compose / k8s
- Scan images for vulnerabilities (Trivy, Grype) in CI
- Drop all capabilities, add back only what's needed

## .dockerignore
- MUST exist alongside every Dockerfile
- Exclude: `.git`, `node_modules`, `__pycache__`, `.env`, test fixtures, documentation, IDE config
- Include only what the build actually needs

## Health Checks
- `HEALTHCHECK` instruction in Dockerfile or health check in orchestrator config
- Use `curl` or dedicated health binary -- not full application startup
- Interval: 30s, timeout: 5s, retries: 3

## Compose
- Explicit `depends_on` with `condition: service_healthy` for startup ordering
- Named volumes for persistent data, tmpfs for ephemeral
- Resource limits: `mem_limit`, `cpus` to prevent runaway containers
- `.env` file for environment-specific config, never hardcoded in compose file
