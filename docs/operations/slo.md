# Service Level Objective (SLO)

This app now tracks one simple, actionable availability SLO.

## SLI (what is measured)
- **Availability SLI**: successful HTTP requests / total HTTP requests.
- A request is successful when status code is `< 500`.
- We measure over a rolling 30-day window.

## SLO target
- **99.5% availability over 30 days**.

## Error budget
- 0.5% monthly error budget.
- If error budget burn exceeds threshold, pause non-critical releases and focus on reliability fixes.

## Alert policy
- Page immediately if 5xx error ratio is above 5% for 10 minutes.
- Create a ticket if 5xx error ratio is above 1% for 1 hour.

## Why this is intentionally simple
- This repo did not previously define an SLO, so we start with a single metric that is easy to instrument in any host platform.
- You can tighten this later (for example, latency SLOs by endpoint).
