# KGR33N Portfolio

Modern portfolio website with blog, auth, and admin panel.

**Stack:** Astro 5 • FastAPI • PostgreSQL • K3s • Terraform

---

## Quick Start

```bash
# Clone & setup
git clone git@github.com:KGR33N-dev/KGR33N_SITE.git
cd KGR33N_SITE
cp backend/.env.example backend/.env

# Run with Docker
./scripts/dev.sh
```

| Service | URL |
|---------|-----|
| Frontend | http://localhost:4321 |
| API | http://localhost:8080/api |
| Docs | http://localhost:8080/api/docs |

---

## Production Deployment

1. **Configure Terraform** (`infra/terraform/terraform.tfvars`)
2. **Deploy infrastructure:** `terraform apply`
3. **Create K8s secrets:** `kubectl apply -f infra/k8s/secrets.yaml`
4. **Deploy app:** `kubectl apply -k infra/k8s/`
5. **Run migrations:** `kubectl exec -it deployment/backend -n kgr33n -- alembic upgrade head`

See `infra/k8s/secrets.yaml.template` for secret configuration.

---

## Project Structure

```
├── frontend/       # Astro + Tailwind
├── backend/        # FastAPI + SQLAlchemy
├── infra/
│   ├── terraform/  # AWS + Cloudflare IaC
│   └── k8s/        # Kubernetes manifests
└── scripts/        # Dev helpers
```

---

## License

MIT
