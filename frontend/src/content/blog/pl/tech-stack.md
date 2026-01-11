---
title: "Głębokie zanurzenie w Stack Technologiczny"
description: "Bliższe spojrzenie na technologie napędzające tę platformę: od Kubernetesa i Terraform po Astro i FastAPI."
pubDate: 2026-01-12
heroImage: "/images/blog/tech-stack-hero.png"
tags: ["Technologia", "Architektura", "DevOps", "Kubernetes", "Programowanie"]
---

# Pod maską: Technologia stojąca za KGR33N 🛠️

![Panel Administratora](/images/blog/admin-panel.png)
*Rzut oka na Panel Administratora zarządzający tą platformą.*

W tym wpisie chciałbym głębiej przyjrzeć się decyzjom technicznym i stosowi technologicznemu, który napędza tę stronę. Została ona zbudowana nie tylko jako portfolio, ale także jako poligon doświadczalny dla nowoczesnych praktyk DevOps i rozwoju full-stack.

## Główny Stack

### Frontend: Astro + TypeScript 🚀

Wybrałem **Astro** na frontend ze względu na jego "Architekturę Wyspową" (Islands Architecture). Domyślnie nie wysyła on żadnego JavaScriptu do klienta, "nawadniając" (hydrating) interaktywne komponenty tylko wtedy, gdy są potrzebne.

- **Wydajność**: Generowanie statycznego HTML dla błyskawicznych czasów ładowania.
- **Interaktywność**: Używamy Vanilla JS i TypeScript dla lekkich interakcji.
- **Styl**: TailwindCSS (lub nasze własne zmienne CSS) zapewnia skalowalny system designu.

### Backend: FastAPI + Python 🐍

Dla API wybrałem **FastAPI**. Jest nowoczesny, szybki (jak sugeruje nazwa) i wykorzystuje typowanie Pythona 3.6+ do automatycznej walidacji i dokumentacji.

- **Async/Await**: W pełni asynchroniczny, co pozwala na wydajną obsługę wielu zapytań jednocześnie.
- **Auto Docs**: Automatyczna, interaktywna dokumentacja API (Swagger UI).
- **Bezpieczeństwo**: Solidny system wstrzykiwania zależności (Dependency Injection) do autoryzacji.

### Baza Danych: PostgreSQL + SQLAlchemy 🐘

Trwałość danych (persistence) jest obsługiwana przez **PostgreSQL**, najbardziej zaawansowaną relacyjną bazę danych open-source.

- **ORM**: SQLAlchemy abstrahuje złożoność SQL, pozwalając nam pracować z obiektami Pythona.
- **Migracje**: Alembic zapewnia bezpieczną ewolucję schematu bazy danych wraz z naszym kodem.

## Infrastruktura i DevOps ☁️

Tutaj zaczyna się prawdziwa zabawa. Cała platforma jest wdrażana z wykorzystaniem zasad Infrastructure as Code (IaC).

### Kubernetes (K3s) ☸️

Zamiast prostych kontenerów Docker, uruchamiam lekki klaster Kubernetes używając **K3s**.

- **Skalowalność**: Choć teraz działa na jednym węźle przydzielonym z AWS, jest gotowy do skalowania horyzontalnego.
- **Odporność**: Kubernetes automatycznie zarządza restartami podów, sprawdzaniem stanu zdrowia (health checks) i wdrożeniami (rollouts).
- **Ingress**: Nginx Ingress Controller zarządza dostępem zewnętrznym do usług.

### Terraform 🏗️

Infrastruktura AWS (instancje EC2, Security Groups, IAM) jest powoływana za pomocą **Terraform**. Oznacza to, że mogę zniszczyć i odtworzyć całe środowisko jednym poleceniem, co gwarantuje brak "rozjazdu konfiguracji" (configuration drift).

### CI/CD: GitHub Actions 🔄

Każde wypchnięcie kodu (push) do repozytorium uruchamia potok (pipeline), który:
1.  **Testuje**: Uruchamia testy jednostkowe i lintery.
2.  **Buduje**: Tworzy zoptymalizowane obrazy Docker (multi-stage builds).
3.  **Wdraża**: Aktualizuje klaster Kubernetes bez przestojów (zero downtime).

## Dlaczego taki poziom skomplikowania?

Możesz zapytać: "Po co używać Kubernetesa dla osobistego bloga?".

Odpowiedź jest prosta: **Nauka i Demonstracja**.

Budując środowisko klasy produkcyjnej w małej skali, szlifuję umiejętności wymagane do zarządzania systemami klasy enterprise. To dowód, że te technologie są dostępnymi i potężnymi narzędziami dla każdego programisty.

Czekajcie na więcej technicznych wpisów!
