# Docker Compose Services

A collection of pre-configured [Docker Compose](https://docs.docker.com/compose/) stacks and deployment scripts for self-hosted developer tools and server utilities.

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
| **Mailpit** | `DockerFiles/mailpit/` | Email testing tool and mock SMTP server with a web UI. |
| **Watchtower** | `DockerFiles/watchtower/` | Automated container updates and lifecycle management. |

---

## 🚀 Usage

Navigate to any service directory and start the stack with Docker Compose:

```bash
cd DockerFiles/<service-name>
docker compose up -d
```

### Environment files

Services that require passwords, tokens, or other private settings include a tracked `.env.example` file. Before starting one of those services, copy the example to `.env` and replace every placeholder with a value appropriate for your deployment:

```bash
cd DockerFiles/<service-name>
cp .env.example .env
$EDITOR .env
docker compose up -d
```

The local `.env` file is ignored by Git. Never commit it or share its contents. The current secret-bearing services are `bugsink`, `docmost`, and `gitea`.
