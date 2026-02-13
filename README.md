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
