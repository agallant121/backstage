# Backstage

Backstage is a social media app for keeping up with the people in your life without the pressure to reply one-by-one.

Instead of repeating the same life update across a dozen text threads, you can share one post with a specific group or with all of your groups at once. It is built for moments like:

- You had a kid and do not want to have the same conversation with everyone in your life.
- Your family moved, got engaged, started a new job, or has a health update to share.
- You want close friends, relatives, or other circles to stay connected without turning every update into a full conversation.

Backstage gives each group its own private wall, so people can stay in touch, see photos and notes, keep track of important life details in one place, use the directory as a shared family record, and get an AI recap of recent group activity when summaries are enabled.

## What the app does

- Create private groups for different circles in your life.
- Post updates to one group or broadcast the same update to all of your groups at once.
- Share text, photos, and videos.
- Invite people into groups with email-based invite links.
- Keep a shared contact directory with family details like partners, children's names, birthdays, and home addresses.
- Use the directory like a built-in Christmas card list so you can keep track of households, kids, milestones, and the details people always forget.
- Browse recent updates from all of your groups in one dashboard.
- Generate cached AI summaries of recent group posts when an `OPENAI_API_KEY` is configured.

## Stack

- Ruby 3.4.2
- Rails 8.0.5
- PostgreSQL
- Hotwire (`turbo-rails` and `stimulus-rails`)
- Propshaft
- Devise for authentication
- Pundit for authorization
- Kaminari for pagination
- Active Storage for media uploads
- Solid Queue and Solid Cable
- Sidekiq and Redis are available for background processing/infrastructure integrations

## Local setup

1. Install Ruby 3.4.2 and PostgreSQL.
2. Install gems:

```sh
bundle install
```

3. Create and prepare the database:

```sh
bin/rails db:prepare
```

4. Start the app:

```sh
bin/dev
```

The default local app URL is `http://localhost:3000`.

You can also run the repo's setup script, which installs gems, prepares the database, clears old logs/temp files, and starts the server:

```sh
bin/setup
```

5. Sign in as the admin: `user@example.com`. Password: `asdfasdf123!`

## Local development notes

- Development uses PostgreSQL databases named `backstage_development` and `backstage_test`.
- In development, uploaded files are stored locally with Active Storage.
- Email is configured for MailHog on `127.0.0.1:1025`, which makes local invitation flows easier to test.
- The app includes a `Procfile` with `web` and `worker` process definitions.

## Optional environment variables

- `OPENAI_API_KEY`: enables AI-generated group summaries.
- `SENTRY_DSN`: enables Sentry error tracking.
- `METRICS_TOKEN`: protects the `/metrics` endpoint with an `X-Metrics-Token` header.
- `DATABASE_URL`: used for production database configuration.

## Test

Run the same test command used in CI:

```sh
bin/rails db:prepare test test:system
```
