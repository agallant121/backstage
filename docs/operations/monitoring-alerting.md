# Monitoring and alerting baseline

This is a minimal baseline that can be implemented on any platform.

## Required metrics
- `http_requests_total`
- `http_requests_5xx_total`
- `http_request_duration_seconds`

## Suggested dashboards
- Request rate by endpoint
- Error rate (5xx %)
- p95 request latency
- Database connection pool usage

## Alerts
- **Critical**: 5xx ratio > 5% for 10m
- **Warning**: 5xx ratio > 1% for 1h
- **Warning**: p95 latency > 1.5s for 30m

## On-call runbook (short form)
1. Confirm if issue is global or endpoint-specific.
2. Check recent deploys and rollback if needed.
3. Check database saturation and queue backlog.
4. Communicate incident status and ETA.
5. File post-incident follow-up tasks.

## Error tracking
- Configure `ERROR_TRACKING_WEBHOOK_URL` in production so unhandled exceptions from `Rails.error` are forwarded to your incident platform.
- Route high-severity error events to on-call notifications and link to runbook steps below.
