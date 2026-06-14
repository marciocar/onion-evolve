# 📐 Interface IForge

## 🎯 Propósito

Define o contrato que todos os adapters de **forge** (host de código remoto) devem implementar, garantindo consistência e permitindo trocar de host (GitHub, GitLab, Bitbucket) sem modificar os comandos do Sistema Onion.

---

## 🧭 Fronteira local-vs-remoto (a regra que sustenta esta camada)

**IForge cobre EXCLUSIVAMENTE operações no host remoto (forge).** Operações Git locais **NÃO** pertencem ao IForge — permanecem como chamadas `git` diretas nos comandos, orientadas pelo motor GitFlow ([gitflow-patterns.md](../../../docs/knowledge-base/frameworks/gitflow-patterns.md)). O adapter é a **fronteira de rede**; o Git local é determinístico e portátil, e não precisa de abstração de provider.

| Operação | Camada | Onde vive |
|---|---|---|
| criar/checkout branch, merge, rebase | **Git local** | `git` direto no comando, cita o motor GitFlow |
| tag local (`git tag -a`) | **Git local** | `git` direto |
| **push** de branch/tag (`git push`) | **Git local** | `git` direto — push é plain git (SSH/HTTPS), não API de host |
| abrir/atualizar/ver **Pull Request** | **Forge (IForge)** | adapter → `gh pr` / `gh api` |
| ler/postar **comentário de review** | **Forge (IForge)** | adapter |
| status de **CI/checks** | **Forge (IForge)** | adapter |
| criar **Release** no host (notas, assets) | **Forge (IForge)** | adapter — distinto de `git tag` local |
| ler regras de **branch protection** | **Forge (IForge)** | adapter (informativo) |

> **Por que `push` fica local**: `git push` funciona contra qualquer remote via SSH/HTTPS sem token de forge; só PR/review/CI/Release exigem a API do host. Manter push fora do IForge mantém o adapter enxuto e evita re-abstrair o que o git já abstrai.

---

## 📋 Interface Completa

```typescript
/**
 * Interface abstrata para hosts de código remoto (forge).
 * Todos os adapters (GitHub, GitLab, Bitbucket) devem implementar esta interface.
 * Cobre SOMENTE operações remotas — ver §Fronteira local-vs-remoto.
 */
interface IForge {
  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTIFICAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  /** Nome do provider: 'github' | 'gitlab' | 'bitbucket' | 'none' */
  readonly provider: ForgeProvider;

  /** Transporte efetivo resolvido pelo detector: 'cli' | 'api' */
  readonly transport: ForgeTransport;

  /** Indica se o forge está configurado (CLI autenticada OU token presente) */
  readonly isConfigured: boolean;

  // ═══════════════════════════════════════════════════════════════════════════
  // PULL REQUESTS
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Abre um Pull Request.
   * @param input - head, base, title, body, draft, reviewers, labels
   * @returns PR criado com número e URL
   */
  createPR(input: CreatePRInput): Promise<PROutput>;

  /**
   * Atualiza um PR existente (título, corpo, base, labels, estado).
   */
  updatePR(prRef: PRRef, updates: UpdatePRInput): Promise<PROutput>;

  /**
   * Obtém detalhes de um PR (por número ou branch head).
   */
  getPR(prRef: PRRef): Promise<PROutput>;

  /**
   * Estado consolidado de um PR (mergeable + rollup de CI + decisão de review).
   * Usado por gates pre-merge e polling de review.
   */
  getPRStatus(prRef: PRRef): Promise<PRStatus>;

  /**
   * Lista PRs por critérios.
   */
  listPRs(query: PRQuery): Promise<PROutput[]>;

  /**
   * Faz merge de um PR (opcional — default do fluxo Onion é merge manual humano).
   */
  mergePR(prRef: PRRef, opts: { method?: MergeMethod; deleteBranch?: boolean }): Promise<PROutput>;

  // ═══════════════════════════════════════════════════════════════════════════
  // REVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Posta um comentário no PR (geral ou inline em arquivo/linha).
   */
  addReviewComment(prRef: PRRef, comment: ReviewCommentInput): Promise<ReviewCommentOutput>;

  /**
   * Lista comentários de um PR (alvo do polling de feedback em /engineer/pr).
   */
  getReviewComments(prRef: PRRef): Promise<ReviewCommentOutput[]>;

  /**
   * Solicita reviewers para um PR.
   */
  requestReviewers(prRef: PRRef, reviewers: string[]): Promise<void>;

  // ═══════════════════════════════════════════════════════════════════════════
  // CI / CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Rollup de status de CI para uma ref (branch | sha | PR head).
   */
  getCIStatus(ref: GitRef): Promise<CIStatusOutput>;

  /**
   * Lista de check-runs individuais para uma ref.
   */
  getCheckRuns(ref: GitRef): Promise<CheckRun[]>;

  // ═══════════════════════════════════════════════════════════════════════════
  // RELEASES & TAGS REMOTAS (objeto de release no host, ≠ git tag local)
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Cria um Release no host (notas + flag de pré-release).
   * NÃO substitui `git tag` local — opera sobre o objeto de release remoto.
   */
  createRelease(input: CreateReleaseInput): Promise<ReleaseOutput>;

  /**
   * Obtém um Release por tag.
   */
  getRelease(tag: string): Promise<ReleaseOutput>;

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  /**
   * Resolve a identidade do repositório (owner/repo + branch padrão + proteção).
   */
  validateRepo(): Promise<RepoIdentity>;

  /**
   * Detecta o provider a partir da URL de um remote git.
   * @returns provider detectado ou null
   */
  getProviderFromRemote(remoteUrl: string): ForgeProvider | null;
}
```

---

## 📊 Métodos por Categoria

| Categoria | Métodos | Descrição |
|-----------|---------|-----------|
| **Identificação** | `provider`, `transport`, `isConfigured` | Informações do adapter |
| **Pull Requests** | `createPR`, `updatePR`, `getPR`, `getPRStatus`, `listPRs`, `mergePR` | Ciclo de vida do PR |
| **Review** | `addReviewComment`, `getReviewComments`, `requestReviewers` | Feedback e revisão |
| **CI/Checks** | `getCIStatus`, `getCheckRuns` | Estado de pipelines |
| **Releases** | `createRelease`, `getRelease` | Releases no host |
| **Validação** | `validateRepo`, `getProviderFromRemote` | Identidade e compatibilidade |

---

## 🔄 Mapeamento por Provider

### Operações de PR

| Interface | GitHub (`gh`) | GitLab (`glab`) | Bitbucket |
|-----------|---------------|------------------|-----------|
| `createPR` | `gh pr create` | `glab mr create` | `POST /pullrequests` |
| `getPRStatus` | `gh pr view --json` | `glab mr view` | `GET /pullrequests/{id}` |
| `addReviewComment` | `gh pr comment` | `glab mr note` | `POST .../comments` |
| `getCIStatus` | `gh pr checks` | `glab ci status` | `GET /commit/{sha}/statuses` |
| `createRelease` | `gh release create` | `glab release create` | `POST /downloads` (parcial) |

> Nomenclatura difere: GitHub/Bitbucket = "Pull Request"; GitLab = "Merge Request" (MR). A interface usa **PR** como termo neutro; cada adapter traduz.

---

## 🧪 Exemplo de Uso

```typescript
// Obter adapter (transporte resolvido automaticamente: cli default)
const forge = getForge();

if (!forge.isConfigured) {
  console.warn('⚠️ Forge não configurado. Faça push e abra o PR manualmente.');
  return;
}

// Abrir PR (após o comando já ter feito `git push` da branch — push é local)
const pr = await forge.createPR({
  head: 'feature/oauth2',
  base: 'develop',
  title: '🔐 Implementar OAuth2',
  body: '## Resumo\n- OAuth2 Google + GitHub\n\nTask: PROJ-123',
  reviewers: ['octocat']
});
console.log(`✅ PR aberto: ${pr.url}`);

// Aguardar CI verde antes de sinalizar pronto-para-review
const status = await forge.getPRStatus({ number: pr.number });
if (status.ciStatus !== 'success') {
  console.warn(`⏳ CI: ${status.ciStatus}`);
}

// Postar comentário de progresso
await forge.addReviewComment({ number: pr.number }, { body: '🔍 Pronto para review' });
```

---

## 📚 Referências

- [Tipos Compartilhados](./types.md)
- [Detector](./detector.md) — resolve provider + transporte efetivo
- [Factory](./factory.md)
- [Adapters](./adapters/)
- [Motor GitFlow (git local)](../../../docs/knowledge-base/frameworks/gitflow-patterns.md)
- [SDAAL — padrão-pai](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.0.0
**Criado em**: 2026-06-13
