# 🐙 GitHub Forge Adapter

## 🎯 Propósito

Implementação completa do `IForge` para o GitHub. É uma instância concreta do padrão **SDAAL** (Specification-Driven AI Abstraction Layer) — consulte [`docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) para o contrato pai.

**Transporte**: a **`gh` CLI é o padrão e preferencial** (`FORGE_TRANSPORT=cli`, default) — embute auth (`gh auth`), paginação e tratamento de rate-limit. A **REST API** (`gh api` / `curl https://api.github.com`) é **fallback opcional** (`FORGE_TRANSPORT=api`), usada quando `gh` não está instalado/autenticado ou para operações não cobertas pela CLI.

> ✅ **Único adapter implementado nesta iteração.** A costura para `gitlab`/`bitbucket` existe em [factory.md](../factory.md) e [detector.md](../detector.md).

> 🧭 **Escopo**: somente operações de host remoto (PR, review, CI, Release). Git local (branch/merge/tag/push) **não** passa por aqui — ver [interface.md](../interface.md) §Fronteira local-vs-remoto.

---

## 📋 Configuração

### Variáveis de Ambiente

```bash
# Provider e transporte (opcionais — defaults: github / cli)
FORGE_PROVIDER=github          # github | gitlab | bitbucket | none
FORGE_TRANSPORT=cli            # cli (default, gh) | api (REST fallback)

# Auth (condicional ao transporte)
GH_TOKEN=ghp_xxx               # precedência sobre GITHUB_TOKEN; usado por gh e pela REST
GITHUB_TOKEN=ghp_xxx           # já presente no .env.example; fallback de auth
```

### Precedência de autenticação

1. **`transport=cli`**: usa a sessão de `gh auth login` se existir; senão usa `GH_TOKEN`/`GITHUB_TOKEN` (o `gh` lê `GH_TOKEN` do ambiente). Se nenhum, não configurado.
2. **`transport=api`**: exige `GH_TOKEN` ou `GITHUB_TOKEN` no header `Authorization: Bearer`.
3. **Fallback runtime**: se `transport=cli` mas `gh` não está instalado/autenticado, o adapter cai para `api` (se houver token). Espelha o fallback MCP→API do Task Manager.

### Obter token / autenticar

```bash
# Opção A (recomendada) — autenticar a CLI:
gh auth login

# Opção B — token clássico/fine-grained com escopos: repo, workflow, read:org
# https://github.com/settings/tokens  → defina GH_TOKEN no .env
```

---

## 🔧 Implementação

```typescript
/**
 * Adapter GitHub implementando IForge (padrão SDAAL).
 *
 * Transporte padrão: `gh` CLI (gh pr / gh release / gh api).
 * Transporte fallback: REST direta a https://api.github.com via fetch/curl.
 */
class GitHubForgeAdapter implements IForge {
  readonly provider: ForgeProvider = 'github';
  readonly transport: ForgeTransport;
  readonly isConfigured: boolean;

  private token?: string;
  private repo?: { owner: string; repo: string };

  constructor(config: GitHubForgeAdapterConfig) {
    this.transport = this.resolveEffectiveTransport(config.transport);
    this.token = config.token;
    this.isConfigured = this.transport === 'cli'
      ? (isGhAuthenticated() || !!this.token)
      : !!this.token;
  }

  /** Cai de 'cli' para 'api' se gh ausente/não-autenticado mas houver token. */
  private resolveEffectiveTransport(requested: ForgeTransport): ForgeTransport {
    if (requested === 'cli' && !isGhInstalled()) {
      return this.token ? 'api' : 'cli';   // sem token, mantém cli p/ reportar erro claro
    }
    return requested;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PULL REQUESTS
  // ═══════════════════════════════════════════════════════════════════════════

  async createPR(input: CreatePRInput): Promise<PROutput> {
    // ⚠️ Pré-condição: a branch `input.head` já foi empurrada (`git push`) pelo
    // comando chamador. Push é git local, NÃO é responsabilidade do adapter.
    if (this.transport === 'cli') {
      const args = [
        'pr', 'create',
        '--base', input.base,
        '--head', input.head,
        '--title', input.title,
        '--body', input.body || ''
      ];
      if (input.draft) args.push('--draft');
      if (input.reviewers?.length) args.push('--reviewer', input.reviewers.join(','));
      if (input.labels?.length) args.push('--label', input.labels.join(','));
      const url = gh(args).trim();                       // gh imprime a URL do PR
      return this.getPR({ branch: input.head });
    }
    // API: POST /repos/{owner}/{repo}/pulls
    const { owner, repo } = await this.resolveRepo();
    const created = await this.rest('POST', `/repos/${owner}/${repo}/pulls`, {
      title: input.title, head: input.head, base: input.base,
      body: input.body || '', draft: !!input.draft
    });
    if (input.reviewers?.length) await this.requestReviewers({ number: created.number }, input.reviewers);
    if (input.labels?.length) await this.applyLabels(created.number, input.labels);
    return this.normalizePR(created);
  }

  async updatePR(prRef: PRRef, updates: UpdatePRInput): Promise<PROutput> {
    const number = await this.resolveNumber(prRef);
    if (this.transport === 'cli') {
      const args = ['pr', 'edit', String(number)];
      if (updates.title) args.push('--title', updates.title);
      if (updates.body) args.push('--body', updates.body);
      if (updates.base) args.push('--base', updates.base);
      if (updates.labels) args.push('--add-label', updates.labels.join(','));
      gh(args);
      if (updates.state === 'closed') gh(['pr', 'close', String(number)]);
      if (updates.draft === false) gh(['pr', 'ready', String(number)]);
      return this.getPR({ number });
    }
    const { owner, repo } = await this.resolveRepo();
    const patched = await this.rest('PATCH', `/repos/${owner}/${repo}/pulls/${number}`, {
      title: updates.title, body: updates.body, base: updates.base,
      state: updates.state
    });
    return this.normalizePR(patched);
  }

  async getPR(prRef: PRRef): Promise<PROutput> {
    if (this.transport === 'cli') {
      const sel = 'number' in prRef ? String(prRef.number) : prRef.branch;
      const json = JSON.parse(gh([
        'pr', 'view', sel,
        '--json', 'number,title,state,isDraft,headRefName,baseRefName,url,mergeable,statusCheckRollup,author,labels,headRefOid'
      ]));
      return this.normalizePRFromCli(json);
    }
    const { owner, repo } = await this.resolveRepo();
    const number = await this.resolveNumber(prRef);
    const raw = await this.rest('GET', `/repos/${owner}/${repo}/pulls/${number}`);
    return this.normalizePR(raw);
  }

  async getPRStatus(prRef: PRRef): Promise<PRStatus> {
    const pr = await this.getPR(prRef);
    const reviewDecision = this.transport === 'cli'
      ? this.cliReviewDecision(prRef)
      : undefined;
    return {
      number: pr.number, state: pr.state,
      mergeable: pr.mergeable ?? null,
      ciStatus: pr.ciStatus || 'none',
      reviewDecision,
      url: pr.url
    };
  }

  async listPRs(query: PRQuery): Promise<PROutput[]> {
    if (this.transport === 'cli') {
      const args = ['pr', 'list', '--json',
        'number,title,state,headRefName,baseRefName,url,labels,author',
        '--limit', String(query.limit || 30)];
      if (query.state && query.state !== 'all') args.push('--state', query.state);
      if (query.base) args.push('--base', query.base);
      if (query.author) args.push('--author', query.author);
      if (query.labels?.length) args.push('--label', query.labels.join(','));
      return (JSON.parse(gh(args)) as any[]).map(p => this.normalizePRFromCli(p));
    }
    const { owner, repo } = await this.resolveRepo();
    const state = query.state === 'merged' ? 'closed' : (query.state || 'open');
    const raw = await this.rest('GET', `/repos/${owner}/${repo}/pulls?state=${state}&per_page=${query.limit || 30}`);
    return (raw as any[]).map(p => this.normalizePR(p));
  }

  async mergePR(prRef: PRRef, opts: { method?: MergeMethod; deleteBranch?: boolean }): Promise<PROutput> {
    const number = await this.resolveNumber(prRef);
    if (this.transport === 'cli') {
      const args = ['pr', 'merge', String(number), `--${opts.method || 'merge'}`];
      if (opts.deleteBranch) args.push('--delete-branch');
      gh(args);
      return this.getPR({ number });
    }
    const { owner, repo } = await this.resolveRepo();
    await this.rest('PUT', `/repos/${owner}/${repo}/pulls/${number}/merge`, {
      merge_method: opts.method || 'merge'
    });
    return this.getPR({ number });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  async addReviewComment(prRef: PRRef, comment: ReviewCommentInput): Promise<ReviewCommentOutput> {
    const number = await this.resolveNumber(prRef);
    if (this.transport === 'cli') {
      // Comentário geral. Para inline (path+line) usar `gh api` mesmo no modo cli.
      if (comment.path && comment.line) {
        const { owner, repo } = await this.resolveRepo();
        const sha = (await this.getPR({ number })).headSha;
        gh(['api', `/repos/${owner}/${repo}/pulls/${number}/comments`, '-f',
            `body=${comment.body}`, '-f', `path=${comment.path}`, '-F', `line=${comment.line}`,
            '-f', `commit_id=${sha}`]);
      } else {
        gh(['pr', 'comment', String(number), '--body', comment.body]);
      }
      return { id: 'cli', body: comment.body, author: 'self', createdAt: new Date().toISOString() };
    }
    const { owner, repo } = await this.resolveRepo();
    const created = await this.rest('POST', `/repos/${owner}/${repo}/issues/${number}/comments`, {
      body: comment.body
    });
    return this.normalizeComment(created);
  }

  async getReviewComments(prRef: PRRef): Promise<ReviewCommentOutput[]> {
    const number = await this.resolveNumber(prRef);
    const { owner, repo } = await this.resolveRepo();
    // issue comments (gerais) + review comments (inline) — combinados
    const general = await this.rest('GET', `/repos/${owner}/${repo}/issues/${number}/comments`);
    const inline = await this.rest('GET', `/repos/${owner}/${repo}/pulls/${number}/comments`);
    return [...(general as any[]), ...(inline as any[])].map(c => this.normalizeComment(c));
  }

  async requestReviewers(prRef: PRRef, reviewers: string[]): Promise<void> {
    const number = await this.resolveNumber(prRef);
    if (this.transport === 'cli') {
      gh(['pr', 'edit', String(number), '--add-reviewer', reviewers.join(',')]);
      return;
    }
    const { owner, repo } = await this.resolveRepo();
    await this.rest('POST', `/repos/${owner}/${repo}/pulls/${number}/requested_reviewers`, {
      reviewers
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CI / CHECKS
  // ═══════════════════════════════════════════════════════════════════════════

  async getCIStatus(ref: GitRef): Promise<CIStatusOutput> {
    const checks = await this.getCheckRuns(ref);
    return {
      status: this.rollup(checks),
      ref: this.refToString(ref),
      checks
    };
  }

  async getCheckRuns(ref: GitRef): Promise<CheckRun[]> {
    if (this.transport === 'cli' && 'pr' in ref) {
      // gh pr checks N --json name,state,bucket,link
      const json = JSON.parse(gh(['pr', 'checks', String(ref.pr), '--json',
        'name,state,bucket,link'])) as any[];
      return json.map(c => ({
        name: c.name,
        conclusion: this.mapCliConclusion(c.bucket || c.state),
        statusPhase: c.state === 'pending' ? 'in_progress' : 'completed',
        url: c.link
      }));
    }
    const { owner, repo } = await this.resolveRepo();
    const sha = await this.resolveSha(ref);
    const raw = await this.rest('GET', `/repos/${owner}/${repo}/commits/${sha}/check-runs`);
    return ((raw as any).check_runs || []).map((c: any) => ({
      name: c.name,
      conclusion: c.conclusion,
      statusPhase: c.status,
      url: c.html_url
    }));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RELEASES (objeto remoto; ≠ git tag local)
  // ═══════════════════════════════════════════════════════════════════════════

  async createRelease(input: CreateReleaseInput): Promise<ReleaseOutput> {
    if (this.transport === 'cli') {
      const args = ['release', 'create', input.tag];
      if (input.name) args.push('--title', input.name);
      if (input.notes) args.push('--notes', input.notes);
      if (input.generateNotes) args.push('--generate-notes');
      if (input.prerelease) args.push('--prerelease');
      if (input.target) args.push('--target', input.target);
      const url = gh(args).trim();
      return { tag: input.tag, name: input.name || input.tag, url, prerelease: !!input.prerelease };
    }
    const { owner, repo } = await this.resolveRepo();
    const created = await this.rest('POST', `/repos/${owner}/${repo}/releases`, {
      tag_name: input.tag, name: input.name || input.tag, body: input.notes || '',
      prerelease: !!input.prerelease, generate_release_notes: !!input.generateNotes,
      target_commitish: input.target
    });
    return { tag: created.tag_name, name: created.name, url: created.html_url, prerelease: created.prerelease };
  }

  async getRelease(tag: string): Promise<ReleaseOutput> {
    const { owner, repo } = await this.resolveRepo();
    const r = await this.rest('GET', `/repos/${owner}/${repo}/releases/tags/${tag}`);
    return { tag: r.tag_name, name: r.name, url: r.html_url, prerelease: r.prerelease };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════════════════════════════

  async validateRepo(): Promise<RepoIdentity> {
    if (this.transport === 'cli') {
      const json = JSON.parse(gh(['repo', 'view', '--json',
        'owner,name,defaultBranchRef,url']));
      return {
        owner: json.owner?.login, repo: json.name,
        defaultBranch: json.defaultBranchRef?.name || 'main',
        remoteUrl: json.url
      };
    }
    const { owner, repo } = await this.resolveRepo();
    const r = await this.rest('GET', `/repos/${owner}/${repo}`);
    return { owner: r.owner.login, repo: r.name, defaultBranch: r.default_branch, remoteUrl: r.html_url };
  }

  getProviderFromRemote(remoteUrl: string): ForgeProvider | null {
    return detectProviderFromRemoteUrl(remoteUrl);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /** Resolve owner/repo do remote `origin` (cacheado). */
  private async resolveRepo(): Promise<{ owner: string; repo: string }> {
    if (this.repo) return this.repo;
    const url = getOriginRemoteUrl() || '';
    const parsed = parseRepoIdentity(url);
    if (!parsed) throw new Error('❌ Não foi possível resolver owner/repo do remote origin.');
    return (this.repo = parsed);
  }

  /** Resolve número do PR a partir de PRRef (por número ou branch head). */
  private async resolveNumber(prRef: PRRef): Promise<number> {
    if ('number' in prRef) return prRef.number;
    const pr = await this.getPR({ branch: prRef.branch });
    return pr.number;
  }

  private refToString(ref: GitRef): string {
    return 'branch' in ref ? ref.branch : 'sha' in ref ? ref.sha : `pr#${ref.pr}`;
  }

  private async resolveSha(ref: GitRef): Promise<string> {
    if ('sha' in ref) return ref.sha;
    if ('branch' in ref) return runGit(`rev-parse ${ref.branch}`).trim();
    return (await this.getPR({ number: ref.pr })).headSha!;
  }

  private cliReviewDecision(prRef: PRRef): PRStatus['reviewDecision'] {
    const sel = 'number' in prRef ? String(prRef.number) : prRef.branch;
    const d = JSON.parse(gh(['pr', 'view', sel, '--json', 'reviewDecision'])).reviewDecision;
    return d ? (d.toLowerCase() as any) : null;
  }

  /**
   * Faz uma chamada REST autenticada à API do GitHub (transport='api').
   * Implementação concreta: `gh api` (reaproveita auth do gh) ou `curl` com Bearer.
   */
  private async rest(method: string, path: string, body?: any): Promise<any> {
    // Preferir `gh api` (herda auth); fallback curl com Authorization: Bearer ${token}.
    const base = 'https://api.github.com';
    const headers = {
      'Authorization': `Bearer ${this.token}`,
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28'
    };
    const response = await fetch(`${base}${path}`, {
      method, headers, body: body ? JSON.stringify(body) : undefined
    });
    if (!response.ok) {
      const text = await response.text();
      throw new Error(`GitHub API ${method} ${path} falhou: ${response.status} ${response.statusText}\n${text}`);
    }
    return response.status === 204 ? undefined : response.json();
  }

  private async applyLabels(number: number, labels: string[]): Promise<void> {
    const { owner, repo } = await this.resolveRepo();
    await this.rest('POST', `/repos/${owner}/${repo}/issues/${number}/labels`, { labels });
  }

  // ─── Normalização & Mapeamento ─────────────────────────────────────────────

  private normalizePR(raw: any): PROutput {
    return {
      number: raw.number, provider: 'github', title: raw.title,
      state: this.mapState(raw.state, raw.merged, raw.draft),
      head: raw.head?.ref, base: raw.base?.ref, url: raw.html_url,
      mergeable: raw.mergeable, author: raw.user?.login,
      labels: (raw.labels || []).map((l: any) => l.name),
      headSha: raw.head?.sha,
      createdAt: raw.created_at, updatedAt: raw.updated_at
    };
  }

  private normalizePRFromCli(json: any): PROutput {
    return {
      number: json.number, provider: 'github', title: json.title,
      state: this.mapState(json.state, json.state === 'MERGED', json.isDraft),
      head: json.headRefName, base: json.baseRefName, url: json.url,
      mergeable: json.mergeable === 'MERGEABLE' ? true : json.mergeable === 'CONFLICTING' ? false : null,
      ciStatus: this.rollupFromCli(json.statusCheckRollup),
      author: json.author?.login,
      labels: (json.labels || []).map((l: any) => l.name),
      headSha: json.headRefOid
    };
  }

  private normalizeComment(raw: any): ReviewCommentOutput {
    return {
      id: String(raw.id), body: raw.body, author: raw.user?.login,
      url: raw.html_url, path: raw.path, line: raw.line,
      createdAt: raw.created_at
    };
  }

  private mapState(state: string, merged?: boolean, draft?: boolean): PRState {
    const s = (state || '').toLowerCase();
    if (merged || s === 'merged') return 'merged';
    if (draft) return 'draft';
    if (s === 'closed') return 'closed';
    return 'open';
  }

  /** Rollup de check-runs → CIStatus. */
  private rollup(checks: CheckRun[]): CIStatus {
    if (!checks.length) return 'none';
    if (checks.some(c => c.conclusion === 'failure' || c.conclusion === 'timed_out')) return 'failure';
    if (checks.some(c => c.conclusion === null)) return 'pending';
    if (checks.every(c => c.conclusion === 'success' || c.conclusion === 'skipped' || c.conclusion === 'neutral')) return 'success';
    return 'neutral';
  }

  private rollupFromCli(rollup: any[]): CIStatus {
    if (!rollup?.length) return 'none';
    const states = rollup.map(r => (r.conclusion || r.state || '').toLowerCase());
    if (states.some(s => s === 'failure' || s === 'error' || s === 'timed_out')) return 'failure';
    if (states.some(s => s === 'pending' || s === '' || s === 'in_progress')) return 'pending';
    return 'success';
  }

  private mapCliConclusion(bucket: string): CheckConclusion {
    const b = (bucket || '').toLowerCase();
    if (b === 'pass' || b === 'success') return 'success';
    if (b === 'fail' || b === 'failure') return 'failure';
    if (b === 'skipping' || b === 'skipped') return 'skipped';
    if (b === 'pending') return null;
    return 'neutral';
  }
}

/** Helper: executa `gh` capturando stdout. Lança em exit != 0. */
function gh(args: string[]): string {
  // Bash: gh <args...>   (GH_TOKEN herdado do ambiente)
  return runShell('gh', args);
}

/** Helper: `gh` está instalado no PATH? */
function isGhInstalled(): boolean {
  return runShellOk('command -v gh');
}
```

---

## 📊 Mapeamento de Operações: CLI (default) vs API (fallback)

| IForge op | `transport='cli'` (default) | `transport='api'` (fallback) |
|---|---|---|
| `createPR` | `gh pr create --base --head --title --body` | `POST /repos/{o}/{r}/pulls` |
| `updatePR` | `gh pr edit N` / `gh pr close` / `gh pr ready` | `PATCH /repos/{o}/{r}/pulls/{n}` |
| `getPR` | `gh pr view N --json …` | `GET /repos/{o}/{r}/pulls/{n}` |
| `getPRStatus` | `gh pr view --json state,mergeable,statusCheckRollup,reviewDecision` | `GET pulls/{n}` + `GET commits/{sha}/check-runs` |
| `listPRs` | `gh pr list --json …` | `GET /repos/{o}/{r}/pulls?state=` |
| `mergePR` | `gh pr merge N --merge\|--squash\|--rebase` | `PUT /repos/{o}/{r}/pulls/{n}/merge` |
| `addReviewComment` | `gh pr comment N --body` (inline → `gh api`) | `POST /repos/{o}/{r}/issues/{n}/comments` |
| `getReviewComments` | `gh api .../comments` | `GET issues/{n}/comments` + `GET pulls/{n}/comments` |
| `requestReviewers` | `gh pr edit N --add-reviewer` | `POST .../requested_reviewers` |
| `getCIStatus` / `getCheckRuns` | `gh pr checks N --json` | `GET commits/{ref}/check-runs` |
| `createRelease` | `gh release create TAG --notes` | `POST /repos/{o}/{r}/releases` |
| `validateRepo` | `gh repo view --json` + `gh auth status` | `GET /repos/{o}/{r}` |

---

## 🔄 Status de PR — Mapping

| Interface (`PRState`) | GitHub | Notas |
|---|---|---|
| `open` | OPEN | PR aberto |
| `draft` | OPEN + isDraft | rascunho |
| `merged` | MERGED | merged via API/UI |
| `closed` | CLOSED | fechado sem merge |

## 🔄 CI Rollup — Mapping

| Interface (`CIStatus`) | GitHub rollup |
|---|---|
| `success` | todos os check-runs `success`/`skipped`/`neutral` |
| `failure` | algum `failure`/`timed_out` |
| `pending` | algum em execução (`conclusion=null`) |
| `none` | sem checks configurados |

---

## ⚠️ Limitações e Notas

1. **Push é local** — `createPR` pressupõe que o comando já fez `git push` da branch head. O adapter não dá push (ver [interface.md](../interface.md) §Fronteira).
2. **`gh` embute auth/paginação/rate-limit** — por isso é o transporte padrão. Em CI sem `gh`, defina `FORGE_TRANSPORT=api` + `GITHUB_TOKEN`.
3. **Rate limit (transport=api)** — REST retorna `403`/`429` com `Retry-After`; o helper `rest()` não faz retry automático. Para uso intensivo, envolva com backoff exponencial (integrations.md §7).
4. **Merge é opcional** — o fluxo Onion padrão deixa o merge para humano/UI; `mergePR` existe para automações específicas.
5. **`createRelease` ≠ `git tag`** — cria o objeto Release no host; a tag local é criada via `git tag` pelo comando (motor GitFlow).
6. **Comentário inline** requer `path` + `line` + `commit_id`; no modo `cli` o adapter usa `gh api` para isso.

---

## 🗓️ Compatibilidade (estado em junho/2026)

| Operação | Via CLI | Via API | Status |
|---|---|---|---|
| PR create/edit/view/merge | `gh pr *` | `/repos/.../pulls` | ✅ Atual |
| PR comments | `gh pr comment` / `gh api` | `/issues/{n}/comments` | ✅ Atual |
| Checks rollup | `gh pr checks` | `/commits/{ref}/check-runs` | ✅ Atual |
| Release | `gh release create` | `/repos/.../releases` | ✅ Atual |

- **REST versionada** via header `X-GitHub-Api-Version: 2022-11-28`.
- **`gh`** segue sendo a interface recomendada pelo guidance nativo do Claude Code para operações GitHub.

---

## 🚀 Setup Rápido

1. **Configurar `.env`** (ou só autenticar a CLI):
   ```bash
   FORGE_PROVIDER=github
   FORGE_TRANSPORT=cli        # cli (default) | api
   # GH_TOKEN=ghp_...         # opcional se `gh auth login` já feito
   ```
2. **Autenticar**: `gh auth login` (ou exportar `GH_TOKEN`).
3. **Testar**: `gh auth status` deve retornar autenticado.
4. **Usar nos comandos Onion**: `/git:flow feature publish`, `/engineer/pr` (rotam PR/CI pelo adapter).

---

## 📚 Referências

- [GitHub CLI (`gh`) manual](https://cli.github.com/manual/)
- [GitHub REST API](https://docs.github.com/en/rest)
- [Interface IForge](../interface.md)
- [Types](../types.md)
- [Factory](../factory.md)
- [Detector](../detector.md)
- [Padrão SDAAL](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.0.0
**Criado em**: 2026-06-13
**Status**: ✅ Implementação completa (único adapter desta iteração)
