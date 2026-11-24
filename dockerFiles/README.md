# Docker Compose Services

A collection of pre-configured [Docker Compose](https://docs.docker.com/compose/) stacks and deployment scripts for self-hosted developer tools and server utilities.

---

## 📑 Index

- [Required Packages](#-required-packages)
- [Available Services](#-available-services)
- [Usage](#-usage)
  - [Environment files](#-environment-files)

---

## 📦 Required Packages

To run these Docker stacks on Debian-based systems:

```bash
sudo apt update
sudo apt install docker.io docker-compose
# Or ensure the official Docker CE & Compose plugin are installed
```

---

## 📂 Available Services

| Service | Directory | Description |
| :--- | :--- | :--- |
| **Bugsink** | `DockerFiles/bugsink/` | Error tracking and exception monitoring platform. |
| **Docmost** | `DockerFiles/docmost/` | Open-source collaborative wiki and documentation tool. |
| **Gitea** | `DockerFiles/gitea/` | Lightweight, self-hosted Git service and configuration. |
| **Hoppscotch** | `DockerFiles/hoppscotch/` | Self-hosted API client for sharing Postman-compatible collections with a team. |
| **Mailpit** | `DockerFiles/mailpit/` | Email testing tool and mock SMTP server with a web UI. |
| **Watchtower** | `DockerFiles/watchtower/` | Automated container updates and lifecycle management. |

---

## 🚀 Usage

Navigate to any service directory and start the stack with Docker Compose:

```bash
cd DockerFiles/<service-name>
docker compose up -d
```

### 🔐 Environment files

Services that require passwords, tokens, or other private settings include a tracked `.env.example` file. Before starting one of those services, copy the example to `.env` and replace every placeholder with a value appropriate for your deployment:

```bash
cd DockerFiles/<service-name>
cp .env.example .env
$EDITOR .env
docker compose up -d
```

The local `.env` file is ignored by Git. Never commit it or share its contents. The current secret-bearing services are `bugsink`, `docmost`, `gitea`, and `hoppscotch`.

The `hoppscotch` stack applies its database migrations automatically: a one-shot `migrate` service runs before the app and is a no-op once the schema is current, so `docker compose up -d` is the only command needed after creating `.env`. The first account created at `http://<host>:50021` becomes the instance administrator.

The stack also bind-mounts `DockerFiles/hoppscotch/Caddyfile` over the image's own SPA config. The 2026.11.0 image falls back to `/` for unknown paths, which makes Caddy answer every deep link with a bare 404 — including magic-link logins (`/enter?token=…`). The mounted file uses `/index.html` instead. Keep the two files together and re-check the override when bumping the image tag.

The `gitea` stack also reads `GITEA_DATA_ROOT` from its `.env` to choose the host directory holding the bind-mounted `gitea` and `gitea-runner` data (`/home/admin` by default). Use an absolute path — `~` is not expanded by Docker Compose.
