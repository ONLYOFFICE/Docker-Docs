## Project Overview

ONLYOFFICE Docker-Docs — containerized ONLYOFFICE Docs with decoupled services (proxy, docservice, converter, example, utils, balancer) for Kubernetes and Docker Compose deployments.

## Tech Stack

Docker, Docker Compose, Docker BuildX, Bash, Python 3.11, Lua (OpenResty), Nginx, PostgreSQL/MySQL/MariaDB, Redis, RabbitMQ/ActiveMQ

## Project Structure

```
Dockerfile                     — Main multi-stage image (targets: ds-base, ds-service, docs, proxy, docservice, converter, adminpanel, example, builder, utils, metrics, db, mysqldb, db-mariadb)
Dockerfile.balancer            — OpenResty-based load balancer
Dockerfile.noplugins           — Lightweight build without plugins
legacy/                        — Legacy Dockerfiles (Dockerfile, Dockerfile.noplugins)
docker-compose.yml             — Service orchestration
build.yml                      — Docker Compose build config (builds all service images)
docker-bake.hcl                — BuildX multi-arch configuration
Makefile                       — Build system
build.sh                       — Build wrapper script
docker-entrypoint.sh           — Main service entrypoint
proxy-docker-entrypoint.sh     — Proxy service entrypoint
example-docker-entrypoint.sh   — Example app entrypoint
init-docker-entrypoint.sh      — Initialization entrypoint
balancer-docker-entrypoint.py  — Balancer entrypoint (Python)
config/nginx/                  — Nginx configuration
config/balancer/               — Balancer Lua scripts and configs (lua/, conf.d/, nginx.conf)
config/supervisor/             — Process manager config
scripts/                       — Kubernetes observer scripts (Python): ds-pod-observer.py, ds-ep-observer.py, balancer-cm-observer.py, balancer-shutdown.py
tests/                         — Integration tests (postgres, mysql, mariadb, rabbitmq, activemq)
hooks/                         — Docker Hub automated build hooks
dictionaries/                  — Custom spellcheck dictionaries
fonts/                         — Custom fonts directory
```

## Build & Run

```bash
# Build all services
./build.sh

# Run
docker-compose up -d

# Scale services
docker compose up -d --scale docservice=3 --scale converter=5

# Health check
curl http://localhost/healthcheck  # Should return "true"

# Run tests
./tests/test.sh
```

## Key Patterns

- Multi-stage Dockerfile with build targets for services, base/intermediate stages, and databases
- Three editions: Community, Enterprise (-ee), Developer (-de)
- Horizontal scaling of docservice and converter
- Non-root container execution (user `ds`, UID 101)
- All config via environment variables and `.env` file
- Multi-arch support: amd64, arm64

## Review Focus

**Security**: JWT enabled by default, non-root execution, secret handling
**Docker**: Multi-stage builds, image size, layer optimization
**Shell**: Quoting, error handling, entrypoint scripts
**Python**: Kubernetes observer scripts correctness
**Lua**: Balancer routing logic in config/balancer/lua/
**Config**: Nginx configs, supervisor configs, exposed ports

## Git Workflow

- **Main branch**: `master`
- **Integration branch**: `develop`
- **Branch naming**: `feature/*`, `bugfix/*`, `hotfix/*`, `release/*`
