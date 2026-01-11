---
title: "Welcome to KGR33N - My DevOps Portfolio"
description: "Discover the architecture behind this portfolio website - a modern full-stack application built with cutting-edge technologies and deployed on a self-managed Kubernetes cluster."
pubDate: 2026-01-11
slug: "hello-world"
featured_image: "/assets/images/blog/devops-architecture.png"
tags: ["DevOps", "Kubernetes", "FastAPI", "Astro", "TypeScript"]
---

# Welcome to KGR33N! 🚀

Hi, I'm **Krzysztof Głuchowski** — a passionate **DevOps Engineer** and **Full-Stack Developer**. This website is more than just a portfolio; it's a living demonstration of modern DevOps practices and cloud-native architecture.

## 🏗️ Project Architecture

This portfolio showcases a complete production-grade deployment pipeline:

```
┌─────────────────────────────────────────────────────────────┐
│                     PRODUCTION STACK                        │
├─────────────────────────────────────────────────────────────┤
│  🌐 Cloudflare (DNS, CDN, DDoS Protection, SSL Termination) │
├─────────────────────────────────────────────────────────────┤
│  ☁️  AWS EC2 (t3.small) - Frankfurt Region                  │
│  ├── 🎲 K3s (Lightweight Kubernetes)                        │
│  │   ├── 📦 Backend Pod (FastAPI + Python)                  │
│  │   ├── 📦 Frontend Pod (Astro + Nginx)                    │
│  │   ├── 📦 PostgreSQL Pod (Stateful Database)              │
│  │   └── 🔀 Nginx Ingress Controller                        │
│  └── 💾 Persistent Volumes (EBS)                            │
├─────────────────────────────────────────────────────────────┤
│  🔄 GitHub Actions (CI/CD Pipeline)                         │
│  📦 GitHub Container Registry (GHCR)                        │
│  🏗️  Terraform (Infrastructure as Code)                     │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Technology Stack

### Backend
- **FastAPI** — Modern, fast Python web framework with automatic OpenAPI documentation
- **SQLAlchemy** — ORM for database operations with PostgreSQL
- **Alembic** — Database migration management
- **Pydantic** — Data validation using Python type annotations
- **JWT Authentication** — Secure HTTP-only cookie-based auth with refresh tokens
- **Resend** — Transactional email service for verification and notifications

### Frontend
- **Astro** — Static site generator with partial hydration for optimal performance
- **TypeScript** — Type-safe JavaScript for maintainable code
- **Nginx** — High-performance web server serving static assets
- **i18n** — Multi-language support (EN, PL) with dynamic content switching

### Infrastructure
- **Terraform** — Infrastructure as Code for AWS resource provisioning
- **K3s** — Lightweight Kubernetes distribution perfect for single-node deployments
- **Helm** — Kubernetes package manager for Nginx Ingress installation
- **Kustomize** — Kubernetes native configuration management

### DevOps & CI/CD
- **GitHub Actions** — Automated build, test, and deployment pipelines
- **GitHub Container Registry** — Private Docker image storage
- **Multi-stage Docker builds** — Optimized container images (~40MB frontend)
- **Rolling deployments** — Zero-downtime updates with health checks

### Security
- **Cloudflare Proxy** — DDoS protection and WAF
- **HTTP-only Cookies** — XSS-resistant authentication
- **CORS Configuration** — Controlled cross-origin requests
- **Rate Limiting** — Protection against brute-force attacks
- **AWS Security Groups** — Network-level access control

## 📊 Key Features

### 🔐 Authentication System
Complete user authentication with:
- Email verification flow
- Password reset functionality
- Role-based access control (User, Moderator, Admin)
- Rank system with progression

### 💬 Comments System
Interactive blog comments with:
- Nested replies
- Like functionality
- Moderation capabilities
- Real-time updates

### 📝 Content Management
Hybrid content architecture:
- Static Markdown files for SEO-optimized content
- Dynamic API for interactive features
- Multi-language translations

## 🎯 Why This Architecture?

This project demonstrates practical DevOps skills:

1. **Infrastructure as Code** — Everything is version-controlled and reproducible
2. **Container Orchestration** — Kubernetes for scalability and resilience
3. **CI/CD Automation** — Push to `main` = automatic production deployment
4. **Security-First Design** — Multiple layers of protection
5. **Cost Optimization** — Single EC2 instance running full stack (~$10/month)

## 🔗 Connect With Me

Feel free to explore the codebase, leave a comment, or reach out:

- **GitHub**: [@KGR33N-dev](https://github.com/KGR33N-dev)
- **LinkedIn**: [Krzysztof Głuchowski](https://linkedin.com/in/krzysztof-gluchowski)
- **Email**: kgr33n.dev@gmail.com

---

> *"The best way to learn is to build something real."*

Thank you for visiting! 🙏
