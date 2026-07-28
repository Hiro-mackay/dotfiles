---
name: dockerfile
description: Dockerfile and container build conventions covering layer caching, image size, secret handling, non-root execution, and health checks. Apply when reading, writing, or reviewing Dockerfile, docker-compose, .dockerignore, or containerfile files.
user-invocable: false
paths:
  - "**/Dockerfile*"
  - "**/docker-compose*"
  - "**/.dockerignore"
  - "**/containerfile*"
---

# Dockerfile & Container Principles

The steps that get skipped when the build works. Docker syntax is deliberately absent.

## Build
- Multi-stage, always: a builder stage that compiles or installs, and a runtime stage that receives only the artifacts. No source, no build tools, no dev dependencies in the final image
- Runtime base is distroless, alpine, or a slim variant -- never a full OS image
- Pin the base image by digest or an exact tag. `latest` makes the build unreproducible the moment upstream moves
- Order layers least-changing to most-changing: system deps, then language deps, then application code. Copy the dependency manifest and install before copying source, or every code edit reinstalls everything
- `--mount=type=cache` for package manager caches

## Security
- `USER nonroot:nonroot` or a numeric UID. A container running as root is the default, not a choice you made
- Secrets arrive via `--mount=type=secret` at build time or environment at runtime. A secret in a layer stays in the layer even after a later `RUN` deletes it
- Read-only root filesystem where the workload allows, all capabilities dropped and only the needed ones added back
- Image scanning (Trivy, Grype) in CI

## .dockerignore
- One exists beside every Dockerfile. Without it the whole working tree becomes build context, including `.git` and `.env`
- Exclude `.git`, `node_modules`, `__pycache__`, `.env`, fixtures, docs, and IDE config

## Runtime
- A `HEALTHCHECK` that probes the serving endpoint, not one that re-runs application startup. 30s interval, 5s timeout, 3 retries
- Compose: `depends_on` with `condition: service_healthy` for ordering, named volumes for persistence and tmpfs for scratch, `mem_limit` and `cpus` set so one container cannot starve the host, and config from an `.env` file rather than literals in the compose file
