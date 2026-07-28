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

The things that get skipped under delivery pressure, plus the house numbers. Well-known attack names and algorithm trivia are deliberately absent.

## Authorization
- Authorize at the resource, not just the route. A handler that checks "is logged in" and then loads by an ID from the request is an IDOR -- confirm this user owns this object
- Default deny. Grant explicitly; never build a system where you have to remember to revoke
- Check permissions, not role names, in code. Never trust a role or permission that arrived from the client
- Service accounts and API keys get the narrowest scope that works, plus an expiry

## Authentication
- Verify signature, issuer, audience, and expiry on every request. No grace period on expiry
- Access tokens ~15 minutes, refresh tokens 7-30 days. Refresh tokens are one-time use, stored hashed, and rotated on every use
- Regenerate the session ID after login and after any privilege change. Session IDs are >= 128 bits from a cryptographic source
- Passwords: argon2id, or bcrypt at cost >= 12
- Authorization Code + PKCE for anything public (SPA, mobile, CLI); Client Credentials for service-to-service
- TOTP or WebAuthn for MFA, SMS only as fallback. Lock out after ~5 failed logins with exponential backoff

## Input
- Validate at the system boundary only. Inner functions receive data that is already trusted
- Define what is valid, not what is forbidden -- allowlists survive encodings that denylists don't
- Parameterized queries, always. Sanitize HTML with a real library (DOMPurify, bluemonday), never a regex
- Paths: resolve to canonical form, then confirm the result is still under the allowed prefix
- Uploads: decide the type from magic bytes, not the extension or the declared MIME. Cap the size
- Never deserialize or evaluate untrusted input: no `pickle.loads`, no `yaml.load` without `SafeLoader`, no `eval` / `exec` / `Function()` on anything that crossed a boundary. These are remote code execution, not input validation bugs, and no default linter configuration flags them

## Secrets and crypto
- Never log a secret, token, password, or PII. Redact at the logging boundary rather than trusting call sites
- `.env` and credential files in `.gitignore`, with a pre-commit scan behind it
- AES-256-GCM or ChaCha20-Poly1305 at rest, TLS 1.2+ (prefer 1.3) in transit, PBKDF2 at >= 600k iterations or scrypt/argon2 for derivation
- Cryptographic RNG only -- a language's default random function is never acceptable for anything security-bearing
- Use audited libraries. Do not assemble primitives yourself

## Response headers
- `Content-Security-Policy` with no `unsafe-inline` unless it carries a nonce; `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` (or CSP `frame-ancestors 'none'`), `Referrer-Policy: strict-origin-when-cross-origin`
- CORS: an explicit origin allowlist. `*` with credentials is never valid
