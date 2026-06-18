---
name: security-principles
description: "Security implementation patterns for authentication, authorization, input validation, secrets management, and cryptography. Applies when writing auth flows, handling user input, managing secrets, or implementing encryption. Zero-trust: loaded for all commonly touched engineering files, since vulnerabilities are not confined to auth directories."
paths:
  - "**/*.go"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.py"
  - "**/*.sql"
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
  - "**/*.yaml"
  - "**/*.yml"
  - "**/*.toml"
  - "**/Dockerfile*"
  - "**/docker-compose*"
  - "**/.env*"
---

# Security Implementation Principles

## Auth Architecture
- **Session-based** when: server-rendered apps, simple auth, single domain. Store session server-side, send cookie
- **Token-based (JWT)** when: API-first, mobile clients, cross-domain, microservices. Stateless but harder to revoke
- **OAuth 2.0 + OIDC** when: third-party login, SSO, delegated authorization
  - Authorization Code + PKCE for public clients (SPA, mobile, CLI)
  - Client Credentials for service-to-service (no user involved)
  - NEVER use Implicit flow -- deprecated, tokens exposed in URL
- Token architecture: access token (short-lived, 15min) + refresh token (long-lived, 7-30 days) + ID token (user identity, OIDC only)
- Revocation: maintain a deny list or use short-lived tokens with refresh rotation

## Authentication
- Passwords: argon2id (preferred) or bcrypt with cost >= 12. NEVER MD5, SHA-1, or plain SHA-256
- JWT: verify signature, issuer, audience, and expiration on EVERY request. Reject expired tokens -- no grace period
- Refresh tokens: one-time use, store hashed server-side, rotate on each use
- Session IDs: cryptographically random (>= 128 bits), regenerate after login and privilege change
- Multi-factor: TOTP or WebAuthn. SMS is a fallback, not primary
- Rate limit login attempts: 5 failures -> temporary lockout with exponential backoff

## Authorization
- Default deny -- explicitly grant, never explicitly revoke
- Check authorization at the resource level, not just the route/endpoint
- IDOR prevention: validate that the authenticated user owns the requested resource
- RBAC: roles map to permissions, check permissions not role names in code
- Never trust client-side role/permission data -- always verify server-side
- Principle of least privilege for service accounts and API keys

## Input Validation
- Validate at system boundary ONLY -- inner functions receive trusted data
- Allowlist over denylist: define what IS valid, not what isn't
- Validate type, length, range, and format. Reject early with clear errors
- SQL: parameterized queries ONLY. Never string interpolation
- HTML: sanitize with a proven library (DOMPurify, bluemonday). Never regex
- Path traversal: resolve to canonical path, verify it starts with allowed prefix
- File uploads: validate MIME type by content (magic bytes), not extension. Limit size

## Secrets Management
- NEVER hardcode secrets -- environment variables or secret manager (Vault, AWS SSM, GCP Secret Manager)
- Rotate secrets on schedule and immediately on suspected compromise
- API keys: scope to minimum required permissions, set expiration
- Logging: NEVER log secrets, tokens, passwords, or PII. Mask or redact
- Git: `.gitignore` for `.env`, credentials files. Pre-commit hook to scan for secrets

## Cryptography
- Encryption at rest: AES-256-GCM or ChaCha20-Poly1305
- Encryption in transit: TLS 1.2+ minimum, prefer 1.3
- Key derivation: PBKDF2 (>= 600k iterations), scrypt, or argon2
- Random values: use cryptographic RNG only. NEVER use math random functions for security
- Don't invent crypto -- use well-audited libraries

## HTTP Security Headers
- `Content-Security-Policy`: restrict script sources, no `unsafe-inline` without nonce
- `Strict-Transport-Security`: `max-age=31536000; includeSubDomains`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY` (or CSP `frame-ancestors 'none'`)
- `Referrer-Policy: strict-origin-when-cross-origin`
- CORS: explicit origin allowlist, never `*` with credentials
