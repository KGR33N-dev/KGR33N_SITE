---
title: "Deep Dive into the Tech Stack"
description: "A closer look at the technologies powering this platform: from Kubernetes and Terraform to Astro and FastAPI."
pubDate: 2026-01-12
heroImage: "/images/blog/tech-stack-hero.png"
tags: ["Tech Stack", "Architecture", "DevOps", "Kubernetes", "Coding"]
---

# Under the Hood: The Technology Behind KGR33N 🛠️

![Admin Panel Dashboard](/images/blog/admin-panel.png)
*A sneak peek into the Admin Dashboard managing this platform.*

In this post, I want to take a deeper dive into the technical decisions and the stack that powers this website. It's built not just to be a portfolio, but a playground for modern DevOps practices and full-stack development.

## The Core Stack

### Frontend: Astro + TypeScript 🚀

I chose **Astro** for the frontend because of its "Inventory Architecture" (Islands Architecture). It delivers zero JavaScript to the client by default, hydrating only the interactive components when needed.

- **Performance**: Static HTML generation for blazingly fast load times.
- **Interactivity**: We use Vanilla JS and TypeScript for light interactions, and can easily drop in React or Svelte components if complexity grows.
- **Styling**: TailwindCSS (or custom CSS variables here) provides a scalable design system.

### Backend: FastAPI + Python 🐍

For the API, I went with **FastAPI**. It's modern, fast (as the name implies), and leverages Python 3.6+ type hints for automatic validation and documentation.

- **Async/Await**: Fully asynchronous for handling concurrent requests efficiently.
- **Auto Docs**: Automatic interactive API documentation (Swagger UI) at `/docs`.
- **Security**: Robust dependency injection system for authentication and authorization.

### Database: PostgreSQL + SQLAlchemy 🐘

Data persistence is handled by **PostgreSQL**, the world's most advanced open-source relational database.

- **ORM**: SQLAlchemy abstracts the SQL complexity, allowing us to work with Python objects.
- **Migrations**: Alembic ensures our database schema evolves safely alongside our code.

## Infrastructure & DevOps ☁️

This is where the real fun begins. The entire platform is deployed using Infrastructure as Code (IaC) principles.

### Kubernetes (K3s) ☸️

Instead of simple Docker containers, I run a lightweight Kubernetes cluster using **K3s**.

- **Scalability**: While running on a single node now, it's ready to scale horizontally.
- **Resiliency**: Kubernetes handles pod restarts, health checks, and rollouts automatically.
- **Ingress**: Nginx Ingress Controller manages external access to the services.

### Terraform 🏗️

The AWS infrastructure (EC2 instances, Security Groups, IAM roles) is provisioned using **Terraform**. This means I can tear down and recreate the entire environment with a single command (`terraform apply`), ensuring no "configuration drift" occurs.

### CI/CD: GitHub Actions 🔄

Every push to the repository triggers a pipeline that:
1.  **Tests**: Runs unit tests and linting.
2.  **Builds**: Creates optimized multi-stage Docker images.
3.  **Deploys**: Updates the Kubernetes cluster with zero downtime.

## Why This Complexity?

You might ask, "Why use Kubernetes for a personal blog?"

The answer is simple: **Learning and Demonstration**.

By building a production-grade environment on a small scale, I'm honing the skills required to manage enterprise-grade systems. It proves that these technologies are accessible and powerful tools for any developer.

Stay tuned for more technical deep dives!
