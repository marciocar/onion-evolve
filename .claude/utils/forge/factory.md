# 🏭 Factory - Forge

> Instância concreta do padrão **SDAAL** (Specification-Driven AI Abstraction Layer).
> Referência canônica: `docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`

## 🎯 Propósito

Instanciar o adapter de **forge** correto para o provider e transporte configurados, abstraindo a criação e permitindo uso uniforme nos comandos. O comando não sabe (nem precisa saber) se a operação foi via `gh` CLI ou REST.

---

## ⚖️ Divergência de transporte (vs Task Manager) — declarada deliberadamente

A Task Manager Abstraction usa `transport='api'` como default. A Forge usa **`transport='cli'`** como default. **Não é inconsistência** — é a aplicação correta do mesmo princípio SDAAL ("padronizar a via preferencial") a um domínio diferente:

- No Task Manager, a REST API é o que está **sempre disponível** e padroniza auth/paginação → `api` é o caminho padronizado.
- No Forge, a CLI oficial (`gh`/`glab`) é o que **embute auth, paginação e rate-limit** e é o caminho idiomático no Claude Code (o guidance nativo recomenda `gh` para operações GitHub) → `cli` é o caminho padronizado; **REST cru é a saída de emergência**.

A regra invariante permanece: a *spec* (interface) define **o quê**; o *adapter* define **o como** (cli ou api). `FORGE_TRANSPORT` controla a via.

---

## 📋 Função Principal

### getForge()

```typescript
/**
 * Retorna uma instância do Forge configurado.
 *
 * Fluxo:
 *   1. detectForgeProvider() → resolve provider + transporte efetivo
 *   2. Se não configurado → fallback NoForgeAdapter ou erro (conforme options)
 *   3. Instancia o adapter passando { transport } no config
 *      - transport='cli' → adapter usa `gh`/`glab` CLI
 *      - transport='api' → adapter usa REST/GraphQL direta (`gh api`/curl)
 *
 * @param options - Opções de configuração (opcional)
 * @returns Instância do adapter apropriado
 *
 * @example
 * const forge = getForge();
 * const pr = await forge.createPR({ head, base, title });
 */
function getForge(options?: ForgeFactoryOptions): IForge {
  const config = detectForgeProvider();
  // config.transport já é o transporte EFETIVO (cli | api), após heurística do detector

  if (options?.debug) {
    console.log(`[Forge] Provider:   ${config.provider}`);
    console.log(`[Forge] Transport:  ${config.transport}`);
    console.log(`[Forge] Configured: ${config.isConfigured}`);
  }

  // Provider selecionado mas não configurado — decidir comportamento
  if (!config.isConfigured) {
    if (options?.throwOnMisconfigured) {
      throw new Error(config.errorMessage || 'Forge not configured');
    }
    console.warn(`⚠️ ${config.errorMessage}`);
    console.warn(`💡 Continuando em modo local — push funciona; PR/CI/Release degradam.`);
    return new NoForgeAdapter();
  }

  switch (config.provider) {

    case 'github':
      // transport='cli' → gh pr/gh api  |  transport='api' → REST api.github.com
      return new GitHubForgeAdapter({
        transport: config.transport,                                   // <- ciente do transporte
        token: process.env.GH_TOKEN || process.env.GITHUB_TOKEN        // GH_TOKEN tem precedência
      });

    // Costura para futuros providers (não implementados nesta iteração):
    case 'gitlab':
    case 'bitbucket':
      console.warn(`⚠️ ${config.errorMessage}`);
      return new NoForgeAdapter();

    case 'none':
    default:
      return new NoForgeAdapter();
  }
}
```

---

## ⚙️ Tipos da Factory

```typescript
/**
 * Opções para a factory.
 */
interface ForgeFactoryOptions {
  /** Habilita logs de debug (provider + transporte resolvido) */
  debug?: boolean;

  /** Lança erro se forge não configurado (ao invés de fallback silencioso) */
  throwOnMisconfigured?: boolean;

  /** Força um provider específico (ignora .env/remote) — uso em testes */
  forceProvider?: ForgeProvider;
}

/**
 * Configuração base compartilhada por todos os adapters de forge.
 * O campo `transport` determina a via de comunicação efetiva.
 */
interface BaseForgeAdapterConfig {
  /** Transporte efetivo resolvido pelo detector. */
  transport: ForgeTransport;  // 'cli' | 'api'
}

/**
 * Configuração para GitHub Forge Adapter.
 * Suporta transport='cli' (gh) e transport='api' (REST).
 */
interface GitHubForgeAdapterConfig extends BaseForgeAdapterConfig {
  /** Token (GH_TOKEN > GITHUB_TOKEN). Opcional se `gh auth login` já feito (transport='cli'). */
  token?: string;
}
```

---

## 🔄 Funções Auxiliares

### getForgeOrFail()

```typescript
/**
 * Versão que lança erro se o forge não estiver configurado.
 * Útil para comandos que REQUEREM forge ativo (ex: criar PR).
 *
 * @throws Error se forge não configurado
 */
function getForgeOrFail(): IForge {
  return getForge({ throwOnMisconfigured: true });
}
```

### getForgeWithWarning()

```typescript
/**
 * Versão que expõe aviso formatado quando em modo local (sem forge).
 * Útil para comandos que funcionam degradados (push local sempre funciona).
 *
 * @returns Adapter + flag de modo local + transporte ativo
 */
function getForgeWithWarning(): {
  forge: IForge;
  transport: ForgeTransport;
  isLocalOnly: boolean;
  warning?: string;
} {
  const config = detectForgeProvider();
  const forge = getForge();

  if (config.provider === 'none' || !config.isConfigured) {
    return {
      forge,
      transport: config.transport,
      isLocalOnly: true,
      warning: `⚠️ MODO LOCAL (sem forge)
━━━━━━━━━━━━━━━━━━━━━━━━
Operações disponíveis:
  ✅ git local (branch, merge, tag, push)
  ❌ Abrir/atualizar Pull Request
  ❌ Postar comentário de review
  ❌ Ler status de CI / criar Release

💡 Para habilitar: autentique a CLI (\`gh auth login\`) ou
   defina GH_TOKEN no .env e execute /meta:setup-integration`
    };
  }

  return { forge, transport: config.transport, isLocalOnly: false };
}
```

---

## 📊 Classe Base NoForgeAdapter (Null Object)

```typescript
/**
 * Adapter de fallback quando nenhum forge está configurado.
 * Git local (push) segue funcionando; operações remotas degradam graciosamente.
 */
class NoForgeAdapter implements IForge {
  readonly provider: ForgeProvider = 'none';
  readonly transport: ForgeTransport = 'cli';
  readonly isConfigured: boolean = false;

  async createPR(input: CreatePRInput): Promise<PROutput> {
    console.warn('⚠️ PR não criado — sem forge configurado.');
    console.warn(`💡 Faça push de "${input.head}" e abra o PR manualmente para "${input.base}".`);
    return {
      number: 0, provider: 'none', title: input.title, state: 'local',
      head: input.head, base: input.base, url: '', labels: input.labels || []
    };
  }

  async updatePR(): Promise<PROutput> { return this.localStub(); }
  async getPR(): Promise<PROutput> { return this.localStub(); }

  async getPRStatus(): Promise<PRStatus> {
    return { number: 0, state: 'local', mergeable: null, ciStatus: 'none', url: '' };
  }

  async listPRs(): Promise<PROutput[]> { return []; }
  async mergePR(): Promise<PROutput> {
    console.warn('⚠️ mergePR indisponível em modo local. Faça merge manualmente.');
    return this.localStub();
  }

  async addReviewComment(): Promise<ReviewCommentOutput> {
    console.warn('⚠️ addReviewComment indisponível — sem forge.');
    return { id: 'local', body: '', author: 'local', createdAt: new Date().toISOString() };
  }
  async getReviewComments(): Promise<ReviewCommentOutput[]> { return []; }
  async requestReviewers(): Promise<void> { /* no-op */ }

  async getCIStatus(ref: GitRef): Promise<CIStatusOutput> {
    return { status: 'none', ref: JSON.stringify(ref), checks: [] };
  }
  async getCheckRuns(): Promise<CheckRun[]> { return []; }

  async createRelease(input: CreateReleaseInput): Promise<ReleaseOutput> {
    console.warn(`⚠️ Release "${input.tag}" não criado no host — sem forge. Tag local não é afetada.`);
    return { tag: input.tag, name: input.name || input.tag, url: '', prerelease: !!input.prerelease };
  }
  async getRelease(tag: string): Promise<ReleaseOutput> {
    return { tag, name: tag, url: '', prerelease: false };
  }

  async validateRepo(): Promise<RepoIdentity> {
    return { owner: '', repo: '', defaultBranch: 'main' };
  }
  getProviderFromRemote(remoteUrl: string): ForgeProvider | null {
    return detectProviderFromRemoteUrl(remoteUrl);
  }

  private localStub(): PROutput {
    return {
      number: 0, provider: 'none', title: '', state: 'local',
      head: '', base: '', url: '', labels: []
    };
  }
}
```

---

## 📊 Mapa de Suporte a Transporte por Provider

| Provider | `transport='cli'` | `transport='api'` | Observação |
|----------|:-----------------:|:-----------------:|-----------|
| GitHub   | ✅ default (`gh`)  | ✅ fallback (REST) | `gh` embute auth/rate-limit; cai p/ `api` se `gh` ausente |
| GitLab   | 🔜 costura (`glab`)| 🔜 costura (REST) | Não implementado nesta iteração |
| Bitbucket| 🔜 costura         | 🔜 costura (REST) | Não implementado nesta iteração |
| none     | — (local)         | — (local)         | NoForgeAdapter; sem chamadas remotas |

---

## 📚 Referências

- [Interface IForge](./interface.md)
- [Detector](./detector.md) — resolve provider + transporte efetivo
- [Adapters](./adapters/) — documentam vias CLI (default) e API (fallback)
- [SDAAL — padrão-pai](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.0.0
**Criado em**: 2026-06-13
