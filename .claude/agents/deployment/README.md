# 🚢 Agentes `deployment/` — containerização e entrega

Agentes especializados nas operações de **empacotamento e deploy** do Sistema Onion: containerização de aplicações, orquestração de containers e integração com serviços de infraestrutura.

## Agentes

| Agente | Especialidade | Quando usar |
|--------|---------------|-------------|
| [`@docker-specialist`](docker-specialist.md) | Docker, containerização de apps Node.js/Next.js, Docker Compose, multi-stage builds e integração com PostgreSQL | Ao containerizar apps Node.js/Next.js, escrever/ajustar `Dockerfile` ou `docker-compose.yml`, otimizar builds em camadas ou integrar containers com PostgreSQL |

## 🔗 Relacionados

- `@postgres-specialist`, `@devops-engineer` — agentes correlatos citados em `related_agents`
- [`@nodejs-specialist`](../development/nodejs-specialist.md) — backend Node.js que costuma ser containerizado
- Comandos de entrega em [`engineer/`](../../commands/engineer/) — fluxos `/engineer/*` (plan → pr) que precedem o deploy
