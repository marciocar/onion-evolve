# ⚪ None Forge Adapter (Null Object)

## 🎯 Propósito

Adapter de fallback (**Null Object Pattern**) usado quando nenhum forge está configurado (`FORGE_PROVIDER=none`, ausência de remote reconhecível, ou CLI/token indisponíveis). Garante **degradação graciosa**: o Git local continua 100% funcional; apenas operações de host remoto (PR, review, CI, Release) viram no-ops com aviso claro.

> A implementação concreta (`class NoForgeAdapter implements IForge`) vive em [factory.md](../factory.md) §Classe Base NoForgeAdapter — mesma convenção do `NoProviderAdapter` da Task Manager Abstraction. Este documento descreve o **comportamento contratual**.

---

## 🔌 Comportamento por operação

| Operação IForge | Comportamento em modo local |
|---|---|
| `createPR` | Não cria PR; avisa em pt-BR ("faça push e abra o PR manualmente"); retorna `PROutput` com `state: 'local'`, `url: ''` |
| `updatePR` / `getPR` / `listPRs` | Retornam stub local / lista vazia |
| `getPRStatus` | `{ state: 'local', mergeable: null, ciStatus: 'none' }` |
| `mergePR` | No-op com aviso ("faça merge manualmente") |
| `addReviewComment` / `requestReviewers` | No-op com aviso |
| `getReviewComments` | `[]` |
| `getCIStatus` / `getCheckRuns` | `status: 'none'` / `[]` |
| `createRelease` | Não cria release no host; **não afeta a tag local** |
| `validateRepo` | Identidade vazia com `defaultBranch: 'main'` |
| `getProviderFromRemote` | Delega à heurística `detectProviderFromRemoteUrl` |

---

## 🧭 Princípio

O Git local é a fronteira que **nunca** depende de forge. Logo, em modo local:

- ✅ `git branch/checkout/merge/tag/commit/push` funcionam normalmente (orientados pelo motor GitFlow)
- ❌ Apenas o que exige API do host (PR/review/CI/Release) degrada

Isso evita espalhar `if (forge == null)` pelos comandos — eles chamam o adapter uniformemente e o Null Object cuida do caso "sem forge".

---

## 📚 Referências

- [Factory](../factory.md) — implementação `NoForgeAdapter`
- [Interface IForge](../interface.md) — contrato + fronteira local-vs-remoto
- [SDAAL — Null Object](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.0.0
**Criado em**: 2026-06-13
