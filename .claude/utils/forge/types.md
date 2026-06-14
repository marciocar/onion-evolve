# 📦 Tipos Compartilhados - Forge

## 🎯 Propósito

Define os tipos TypeScript compartilhados entre todos os adapters de **forge** (host de código remoto: GitHub, GitLab, Bitbucket), garantindo consistência nas operações de entrada e saída.

> **Forge** = host de código remoto. O adapter cobre **apenas operações de host remoto** (Pull Request, review, CI/checks, Release). Operações Git locais (branch, merge, tag, push) **não** pertencem a esta camada — ver [interface.md](./interface.md) §Fronteira local-vs-remoto.

---

## 🔧 Enums e Constantes

```typescript
/**
 * Hosts de código remoto suportados.
 */
type ForgeProvider = 'github' | 'gitlab' | 'bitbucket' | 'none';

/**
 * Transporte usado pelo adapter para falar com o forge.
 *
 * 'cli' (default) — CLI oficial do host (gh / glab); embute auth, paginação
 *                   e rate-limit. É o caminho padronizado e preferencial.
 * 'api'           — REST/GraphQL direta (gh api / curl); usada como fallback
 *                   quando a CLI não está instalada/autenticada, ou para
 *                   operações que a CLI não cobre.
 *
 * Controlado por: FORGE_TRANSPORT (valores: 'cli' | 'api'; default 'cli').
 *
 * NOTA: a Task Manager Abstraction usa default 'api'; a Forge usa default 'cli'
 * deliberadamente — ver factory.md §Divergência de transporte.
 */
type ForgeTransport = 'cli' | 'api';

/**
 * Estado normalizado de um Pull Request.
 */
type PRState = 'open' | 'merged' | 'closed' | 'draft' | 'local';

/**
 * Conclusão normalizada do CI agregado (rollup de checks).
 */
type CIStatus =
  | 'success'
  | 'failure'
  | 'pending'
  | 'error'
  | 'neutral'
  | 'none';      // sem checks configurados / sem forge

/**
 * Conclusão de um check individual.
 */
type CheckConclusion =
  | 'success'
  | 'failure'
  | 'cancelled'
  | 'skipped'
  | 'timed_out'
  | 'action_required'
  | 'neutral'
  | null;        // ainda em execução

/**
 * Método de merge de PR.
 */
type MergeMethod = 'merge' | 'squash' | 'rebase';
```

---

## 📥 Tipos de Entrada (Input)

### CreatePRInput

```typescript
/**
 * Dados para abertura de um Pull Request.
 */
interface CreatePRInput {
  /** Branch de origem (head) — obrigatório */
  head: string;

  /** Branch de destino (base) — obrigatório (ex: 'develop', 'main') */
  base: string;

  /** Título do PR — obrigatório */
  title: string;

  /** Corpo do PR em Markdown */
  body?: string;

  /** Abrir como rascunho (draft) */
  draft?: boolean;

  /** Reviewers (logins/usernames) a solicitar */
  reviewers?: string[];

  /** Labels a aplicar */
  labels?: string[];

  /** ID/key da task vinculada (apenas para corpo/cross-link; sync é do Task Manager) */
  linkedTaskId?: string;
}
```

### UpdatePRInput

```typescript
/**
 * Dados para atualização de PR (todos opcionais).
 */
interface UpdatePRInput {
  title?: string;
  body?: string;
  base?: string;
  /** Marcar/desmarcar rascunho */
  draft?: boolean;
  /** Substitui labels */
  labels?: string[];
  /** Fechar o PR sem merge */
  state?: 'open' | 'closed';
}
```

### ReviewCommentInput

```typescript
/**
 * Comentário a postar num PR.
 */
interface ReviewCommentInput {
  /** Texto em Markdown — obrigatório */
  body: string;

  /** Caminho do arquivo (comentário inline; opcional) */
  path?: string;

  /** Linha do arquivo (comentário inline; requer path) */
  line?: number;
}
```

### CreateReleaseInput

```typescript
/**
 * Dados para criação de um Release no host (objeto de release remoto;
 * distinto de `git tag` local).
 */
interface CreateReleaseInput {
  /** Tag associada — obrigatório (ex: 'v1.2.0') */
  tag: string;

  /** Nome do release (default: a própria tag) */
  name?: string;

  /** Notas em Markdown */
  notes?: string;

  /** Marcar como pré-release */
  prerelease?: boolean;

  /** Gerar notas automaticamente a partir de commits/PRs */
  generateNotes?: boolean;

  /** Branch/commit alvo (default: branch padrão) */
  target?: string;
}
```

### PRQuery

```typescript
/**
 * Critérios de busca de PRs.
 */
interface PRQuery {
  /** Filtra por estado */
  state?: 'open' | 'closed' | 'merged' | 'all';
  /** Filtra por branch base */
  base?: string;
  /** Filtra por autor (login) */
  author?: string;
  /** Filtra por label */
  labels?: string[];
  /** Limite de resultados */
  limit?: number;
}

/**
 * Referência a um PR: por número OU por branch head.
 * Comandos que dão push e abrem PR sem número conhecido usam `{ branch }`.
 */
type PRRef = { number: number } | { branch: string };

/**
 * Referência a um ponto do histórico para consulta de CI.
 */
type GitRef = { branch: string } | { sha: string } | { pr: number };
```

---

## 📤 Tipos de Saída (Output)

### PROutput

```typescript
/**
 * Pull Request normalizado.
 */
interface PROutput {
  /** Número do PR no host */
  number: number;

  /** Provider de origem */
  provider: ForgeProvider;

  /** Título */
  title: string;

  /** Estado normalizado */
  state: PRState;

  /** Branch head */
  head: string;

  /** Branch base */
  base: string;

  /** URL para abrir no host */
  url: string;

  /** Se é mergeable (null = desconhecido/calculando) */
  mergeable?: boolean | null;

  /** Rollup do CI agregado */
  ciStatus?: CIStatus;

  /** Autor (login) */
  author?: string;

  /** Labels */
  labels: string[];

  /** SHA do head atual */
  headSha?: string;

  createdAt?: string;
  updatedAt?: string;
}
```

### PRStatus

```typescript
/**
 * Estado consolidado de um PR (para gates de pre-merge / polling de review).
 */
interface PRStatus {
  number: number;
  state: PRState;
  mergeable: boolean | null;
  /** Rollup de checks */
  ciStatus: CIStatus;
  /** Aprovações registradas */
  reviewDecision?: 'approved' | 'changes_requested' | 'review_required' | null;
  url: string;
}
```

### ReviewCommentOutput

```typescript
interface ReviewCommentOutput {
  id: string;
  body: string;
  author: string;
  url?: string;
  path?: string;
  line?: number;
  createdAt: string;
}
```

### CIStatusOutput / CheckRun

```typescript
interface CIStatusOutput {
  /** Rollup normalizado */
  status: CIStatus;
  /** Ref consultada */
  ref: string;
  /** Checks individuais */
  checks: CheckRun[];
  /** URL da página de checks/runs */
  url?: string;
}

interface CheckRun {
  name: string;
  conclusion: CheckConclusion;
  /** 'queued' | 'in_progress' | 'completed' */
  statusPhase: string;
  url?: string;
}
```

### ReleaseOutput / RepoIdentity

```typescript
interface ReleaseOutput {
  tag: string;
  name: string;
  url: string;
  prerelease: boolean;
  createdAt?: string;
}

/**
 * Identidade do repositório resolvida pelo adapter.
 */
interface RepoIdentity {
  owner: string;
  repo: string;
  defaultBranch: string;
  /** Branches com proteção configurada no host (informativo) */
  protectedBranches?: string[];
  /** URL do remote */
  remoteUrl?: string;
}
```

---

## ⚙️ Tipos de Configuração

### ForgeConfig

```typescript
/**
 * Configuração de um forge resolvida pelo detector.
 */
interface ForgeConfig {
  /** Provider ativo */
  provider: ForgeProvider;

  /**
   * Transporte efetivo escolhido pelo detector.
   * Reflete FORGE_TRANSPORT; o adapter cai para 'api' em runtime quando a CLI
   * (`gh`/`glab`) não está instalada/autenticada. Adapters devem consultar
   * este campo — nunca ler a env var diretamente.
   */
  transport: ForgeTransport;

  /** Se está configurado corretamente (CLI autenticada OU token presente) */
  isConfigured: boolean;

  /** Variáveis de ambiente obrigatórias (condicionais ao transporte) */
  requiredEnvVars: string[];

  /** Variáveis de ambiente opcionais */
  optionalEnvVars: string[];

  /** Mensagem de erro se não configurado */
  errorMessage?: string;
}
```

---

## 🔄 Mapeamento de Estado de PR por Provider

```typescript
/**
 * Mapeamento de PR state normalizado → vocabulário do provider.
 */
const PR_STATE_MAPPING: Record<ForgeProvider, Partial<Record<PRState, string>>> = {
  github: {
    open: 'OPEN',
    merged: 'MERGED',
    closed: 'CLOSED',
    draft: 'OPEN (isDraft=true)'
  },
  gitlab: {
    open: 'opened',
    merged: 'merged',
    closed: 'closed',
    draft: 'opened (Draft:)'
  },
  bitbucket: {
    open: 'OPEN',
    merged: 'MERGED',
    closed: 'DECLINED',
    draft: 'OPEN'
  },
  none: {
    local: 'local'
  }
};
```

---

## 📚 Referências

- [Interface IForge](./interface.md)
- [Detector de Forge](./detector.md)
- [Factory](./factory.md)
- [SDAAL — padrão-pai](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.0.0
**Criado em**: 2026-06-13
