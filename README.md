# PG Back Web on Railway

A Railway template for [PG Back Web](https://github.com/eduardolat/pgbackweb) (now being renamed UFO Backup by its author): scheduled PostgreSQL backups with a web interface, to a local volume or to S3-compatible storage.

It is meant as an add-on for a stack you already run on Railway: deploy it next to your app and point it at your existing Postgres over the private network.

## What it deploys

| Service | Source | Purpose |
|---|---|---|
| **PG Back Web** | this repo (`Dockerfile`, `FROM eduardolat/pgbackweb:0.5.2@sha256:cd902026…cac5c`) | Web UI, scheduler, `pg_dump` clients for PostgreSQL 13–18. Volume on `/backups` for local backups |
| **Postgres** | Railway's Postgres | PG Back Web's own settings, schedules and execution history (not the database you back up) |

- App version: **PG Back Web v0.5.2** (pinned by version and multi-arch digest).
- Health check: `/api/v1/health` (no login needed).
- The start script (`railway-start.sh`) listens on `PORT`, adds `sslmode=disable` to the internal metadata connection when no `sslmode` is set, retries migrations while Postgres starts, then runs the app as upstream does.
- No default password: the first visit to the public URL asks you to create the only admin account. Do that right after deploying.

## Variables

| Variable | Value | Notes |
|---|---|---|
| `PBW_ENCRYPTION_KEY` | `${{secret(32)}}` | Encrypts stored connection strings and S3 keys. Keep it: changing it makes saved credentials unreadable |
| `PBW_POSTGRES_CONN_STRING` | `${{Postgres.DATABASE_URL}}` | PG Back Web's own metadata database |
| `PORT` | `8085` | Port the web UI listens on |

Optional, not set by the template: `TZ` (default `UTC`; affects log times and backup file names), `PBW_PATH_PREFIX` (serve under a sub-path).

## Back up your existing Railway Postgres

1. Deploy the template **into the project that runs your database** (in that project: *Create → Template → PG Back Web*), so both share the private network.
2. Open PG Back Web, create the admin account, then *Databases → Create database*.
3. Use your Postgres service's private URL as the connection string, e.g. `postgresql://postgres:PASSWORD@postgres.railway.internal:5432/railway` (copy `DATABASE_URL` from your Postgres service's Variables tab), and pick the matching PostgreSQL major version.
4. Add a destination (S3, R2, B2, MinIO…) or use the local `/backups` volume, then create a backup with a cron schedule.

If PG Back Web runs in a different Railway project, use the database's `DATABASE_PUBLIC_URL` (TCP proxy) instead; private hostnames only resolve inside one project.

## Updates

This template builds from this repository. When a new PG Back Web version is pinned here and merged to `main`, Railway shows everyone who deployed it an "update available" notice, and they choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) before you apply an update.

## License

The wrapper files in this repo are provided as-is. PG Back Web itself is licensed under AGPL-3.0 by its authors.
