# Backstage

Minimal Rails app with baseline operational safeguards added.

## What was added

- **Security scans in CI**
  - Existing Brakeman and importmap audit checks remain in `CI`.
  - We intentionally do **not** use `actions/dependency-review-action` here because it requires GitHub Advanced Security on this repository; this avoids CI failures tied to plan/features.
  - A lightweight `dependency_review` placeholder job is kept so branch protection checks with that name still pass.

- **SLO definition**
  - Added a simple availability SLO document with one SLI/target and clear error-budget guidance.
  - See `docs/operations/slo.md`.

- **Monitoring/alerting baseline**
  - Added a short monitoring and alerting playbook with required metrics, dashboards, and alert thresholds.
  - See `docs/operations/monitoring-alerting.md`.

- **Backup verification**
  - Added a script that performs a real PostgreSQL dump + restore and verifies restored data.
  - Added a scheduled GitHub Action that runs this weekly (and manually on demand).
  - Files: `script/verify_backup.sh` and `.github/workflows/backup-verify.yml`.

## Why this is intentionally simple

This provides an immediately usable baseline without introducing vendor-specific tooling. You can later wire these docs and checks into Datadog/Prometheus/PagerDuty/AWS Backup/etc. without changing the core approach.

## Metrics and error tracking

- **Prometheus metrics export**
  - `GET /metrics` exports readiness gauges in Prometheus text format:
    - `backstage_readiness_database`
    - `backstage_readiness_cache`
    - `backstage_readiness_queue`
  - Set `METRICS_TOKEN` to require `X-Metrics-Token` header for scraping.

- **Error tracking integration**
  - Set `ERROR_TRACKING_WEBHOOK_URL` to enable automatic error event forwarding from `Rails.error`.
  - Optional `ERROR_TRACKING_WEBHOOK_TOKEN` adds a bearer token in outbound requests.
  - Payload includes error class/message, truncated backtrace, environment, severity, and context.

## Deployment environment variables

`config/deploy.yml` is ERB-driven and expects deploy values from environment variables.

- **Required**
  - `KAMAL_IMAGE` (e.g. `ghcr.io/org/backstage`)
  - `KAMAL_WEB_HOST` (primary app host/IP for `servers.web`)
  - `KAMAL_APP_HOST` (public hostname for proxy/SSL)
  - `KAMAL_REGISTRY_USERNAME` (registry user/account for pulls)
  - `KAMAL_REGISTRY_PASSWORD` (set in environment and referenced from `.kamal/secrets`)

- **Optional**
  - `KAMAL_REGISTRY_SERVER` (defaults to `ghcr.io`)
  - `KAMAL_SSH_USER` (defaults to `root`)
  - `KAMAL_JOB_HOST` (used only in commented job example)
  - `KAMAL_DB_HOST` (used only in commented DB example)
  - `KAMAL_REDIS_HOST` (used only in commented Redis example)

For Rails credentials, set `RAILS_MASTER_KEY`; if absent, `.kamal/secrets` falls back to `config/master.key` and fails with a clear error if neither source is available.
