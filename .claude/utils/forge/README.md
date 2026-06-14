# Forge Abstraction Layer

> **Esta camada é uma instância concreta do padrão SDAAL (Specification-Driven AI Abstraction Layer).**
> Consulte o padrão-pai em [`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md). Adapter-irmão de referência: [`../task-manager/`](../task-manager/).

## Propósito

Camada de abstração que permite trocar o **forge** (host de código remoto: GitHub, GitLab, Bitbucket) sem modificar os comandos do Sistema Onion. Cobre operações de **PR, review, CI/checks e Release**.

## 🧭 Escopo: só o host remoto

Esta camada cobre **apenas operações de host remoto**. Git local (branch, merge, tag, **push**) permanece como chamadas `git` diretas nos comandos, orientadas pelo motor GitFlow ([gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md)). Ver [interface.md](./interface.md) §Fronteira local-vs-remoto.

| Camada | Cobre | Não cobre |
|---|---|---|
| **Forge (esta)** | PR, review, CI status, Release no host | branch, merge, tag, push (git local) |
| **Motor GitFlow (KB)** | lifecycle de branches, dual-merge, semver | operações remotas |

## Transporte: CLI-first, API opcional

A **CLI oficial do host é o transporte padrão e preferencial**; a REST/GraphQL é fallback opcional:

```bash
FORGE_TRANSPORT=cli   # padrão — gh / glab (embute auth, paginação, rate-limit)
FORGE_TRANSPORT=api   # opcional — REST direta (gh api / curl); fallback automático
                      # quando a CLI não está instalada/autenticada
```

> ⚖️ **Divergência deliberada vs Task Manager** (que usa `api` default): no domínio forge a CLI (`gh`) é o caminho padronizado — ver [factory.md](./factory.md) §Divergência de transporte.

---

## Estrutura

```
forge/
├── README.md          # Este arquivo
├── interface.md       # Interface IForge + fronteira local-vs-remoto
├── types.md           # Tipos compartilhados (PR/Review/CI/Release DTOs + enums)
├── detector.md        # Detecção de provider (FORGE_PROVIDER | URL do remote) + transporte
├── factory.md         # Factory getForge() + NoForgeAdapter
└── adapters/
    ├── github.md      # Adapter GitHub (gh-first; REST fallback) — único implementado
    └── none.md        # NoForgeAdapter (Null Object) — local-only / offline
```

## Uso Rápido

### 1. Configurar provider e transporte

No `.env` (ou só `gh auth login`):
```bash
FORGE_PROVIDER=github     # github | gitlab | bitbucket | none (default: detecta pelo remote)
FORGE_TRANSPORT=cli       # cli (default) | api
# GH_TOKEN=ghp_...        # opcional se a CLI já está autenticada
```

### 2. Usar nos comandos

```typescript
import { getForge } from '.claude/utils/forge/factory';

// Após `git push` da branch (push é git local), abrir o PR via adapter:
const forge = getForge();
const pr = await forge.createPR({
  head: 'feature/x', base: 'develop',
  title: 'feat: X', body: '...'
});
```

## Providers Suportados

| Provider | Status | Transporte padrão | Fallback |
|----------|--------|--------------------|----------|
| GitHub | ✅ Completo | `gh` CLI | REST (`gh api`/curl) |
| GitLab | 🔜 Costura pronta | `glab` CLI | REST |
| Bitbucket | 🔜 Costura pronta | — | REST |
| None | ✅ Funcional | — (local) | — |

## Fluxo de Execução

```
Comando Onion (após git push local)
     │
     ▼
┌─────────────┐
│   Factory   │ → FORGE_PROVIDER (ou URL do remote) + FORGE_TRANSPORT
└─────────────┘
     │
     ▼
┌─────────────┐
│  Adapter    │ → GitHub | (GitLab/Bitbucket: costura) | None
└─────────────┘
     │
     ▼
┌──────────────────────────────────┐
│  Transporte                      │
│  • cli  (default) → gh / glab    │
│  • api  (fallback) → REST/GraphQL│
└──────────────────────────────────┘
     │
     ▼
  PR / Review / CI / Release
```

## Referências internas

- [Interface IForge](./interface.md)
- [Tipos Compartilhados](./types.md)
- [Detector](./detector.md)
- [Factory](./factory.md)
- [Adapter GitHub](./adapters/github.md)
- [Adapter None (Null Object)](./adapters/none.md)

## Documentação relacionada

- [`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) — padrão SDAAL (padrão-pai)
- [`docs/knowledge-base/frameworks/gitflow-patterns.md`](../../../docs/knowledge-base/frameworks/gitflow-patterns.md) — motor GitFlow (git local)
- [`../task-manager/`](../task-manager/) — adapter-irmão de referência
- `.env.example` — variáveis `FORGE_*` disponíveis

---

**Criado em**: 2026-06-13
