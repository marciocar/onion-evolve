# 🔍 Detector de Forge

## 🎯 Propósito

Detecta e valida o **forge** (host de código remoto) configurado e o transporte a usar (`cli` ou `api`), com detecção automática a partir da URL do remote git quando `FORGE_PROVIDER` não é declarado.

---

## 📋 Funções Principais

### detectTransport()

```typescript
/**
 * Detecta o transporte configurado via variável de ambiente.
 *
 * FORGE_TRANSPORT controla como o adapter fala com o forge:
 *   'cli'  (default) — CLI oficial (gh / glab); embute auth e rate-limit.
 *   'api'            — REST/GraphQL direta (gh api / curl); fallback.
 *
 * @returns 'cli' | 'api'
 */
function detectTransport(): ForgeTransport {
  const raw = (process.env.FORGE_TRANSPORT || 'cli').toLowerCase();
  return raw === 'api' ? 'api' : 'cli';
}
```

---

### detectForgeProvider()

```typescript
/**
 * Detecta o provider configurado e resolve o transporte ativo.
 *
 * Ordem de resolução do provider:
 *   1. FORGE_PROVIDER explícito no .env (github | gitlab | bitbucket | none)
 *   2. Se ausente → heurística pela URL do remote `origin` (getProviderFromRemote)
 *   3. Fallback final → 'github' (host mais comum); 'none' se não houver remote.
 *
 * isConfigured (por transporte):
 *   - transport='cli' → CLI instalada E autenticada (`gh auth status` ok) OU token presente
 *   - transport='api' → token presente (GH_TOKEN | GITHUB_TOKEN para github)
 *
 * @returns Configuração do forge ativo (inclui campo `transport`)
 */
function detectForgeProvider(): ForgeConfig {
  const requestedTransport = detectTransport();
  const explicit = (process.env.FORGE_PROVIDER || '').toLowerCase();

  const provider: ForgeProvider = explicit
    ? (explicit as ForgeProvider)
    : (detectProviderFromRemoteUrl(getOriginRemoteUrl()) || 'github');

  const configs: Record<ForgeProvider, ForgeConfig> = {
    github: (() => {
      // CLI: gh instalado + autenticado | API: token presente
      const hasToken = !!(process.env.GH_TOKEN || process.env.GITHUB_TOKEN);
      const ghAuthed = isGhAuthenticated();   // `gh auth status` em runtime
      const isConfigured = requestedTransport === 'cli'
        ? (ghAuthed || hasToken)
        : hasToken;

      const missing: string[] = [];
      if (requestedTransport === 'api' && !hasToken) missing.push('GH_TOKEN ou GITHUB_TOKEN');
      if (requestedTransport === 'cli' && !ghAuthed && !hasToken) {
        missing.push('`gh auth login` (ou GH_TOKEN)');
      }

      return {
        provider: 'github',
        transport: requestedTransport,
        isConfigured,
        requiredEnvVars: [],   // CLI autenticada dispensa env; API exige token
        optionalEnvVars: ['GH_TOKEN', 'GITHUB_TOKEN', 'FORGE_TRANSPORT'],
        errorMessage: !isConfigured
          ? `❌ GitHub não configurado. Faltando: ${missing.join(', ')}. Execute /meta:setup-integration`
          : undefined
      };
    })(),

    // Costura para futuros adapters — não implementados nesta iteração.
    gitlab: {
      provider: 'gitlab',
      transport: requestedTransport,
      isConfigured: false,
      requiredEnvVars: ['GITLAB_TOKEN'],
      optionalEnvVars: ['FORGE_TRANSPORT'],
      errorMessage: 'ℹ️ Adapter GitLab não implementado nesta iteração (costura pronta em factory.md).'
    },

    bitbucket: {
      provider: 'bitbucket',
      transport: requestedTransport,
      isConfigured: false,
      requiredEnvVars: ['BITBUCKET_TOKEN'],
      optionalEnvVars: ['FORGE_TRANSPORT'],
      errorMessage: 'ℹ️ Adapter Bitbucket não implementado nesta iteração (costura pronta em factory.md).'
    },

    none: {
      provider: 'none',
      transport: 'cli',          // irrelevante; modo local
      isConfigured: true,        // sempre "configurado" — é o fallback local
      requiredEnvVars: [],
      optionalEnvVars: [],
      errorMessage: undefined
    }
  };

  return configs[provider] || configs.none;
}
```

---

### detectProviderFromRemoteUrl()

```typescript
/**
 * Detecta o forge a partir da URL do remote git.
 * Suporta formatos SSH (git@host:owner/repo.git) e HTTPS (https://host/owner/repo).
 *
 * @param remoteUrl - URL do remote (ex: de `git remote get-url origin`)
 * @returns provider detectado ou null
 */
function detectProviderFromRemoteUrl(remoteUrl?: string): ForgeProvider | null {
  if (!remoteUrl) return null;
  const url = remoteUrl.toLowerCase();

  if (url.includes('github.com')) return 'github';
  if (url.includes('gitlab.com') || url.includes('gitlab.')) return 'gitlab';
  if (url.includes('bitbucket.org') || url.includes('bitbucket.')) return 'bitbucket';

  return null;
}

/**
 * Lê a URL do remote `origin` via git (helper).
 * Implementação concreta: `git remote get-url origin` (vazio se ausente).
 */
function getOriginRemoteUrl(): string | undefined {
  // Bash: git remote get-url origin 2>/dev/null
  // Retorna undefined se não houver remote configurado.
  return runGit('remote get-url origin') || undefined;
}

/**
 * Verifica se a CLI do GitHub está autenticada.
 * Implementação concreta: `gh auth status` (exit 0 = autenticado).
 */
function isGhAuthenticated(): boolean {
  // Bash: gh auth status >/dev/null 2>&1 && echo true
  return runShellOk('gh auth status');
}
```

---

### parseRepoIdentity()

```typescript
/**
 * Extrai owner/repo da URL do remote.
 * @returns { owner, repo } ou null se não parseável
 */
function parseRepoIdentity(remoteUrl: string): { owner: string; repo: string } | null {
  // git@github.com:owner/repo.git  |  https://github.com/owner/repo(.git)
  const m = remoteUrl.match(/[:/]([^/:]+)\/([^/]+?)(?:\.git)?$/);
  if (!m) return null;
  return { owner: m[1], repo: m[2] };
}
```

---

## 📊 Tabela de Detecção por Remote

| URL do remote | Provider detectado |
|---|---|
| `git@github.com:owner/repo.git` | `github` |
| `https://github.com/owner/repo` | `github` |
| `git@gitlab.com:owner/repo.git` | `gitlab` |
| `https://gitlab.empresa.com/...` | `gitlab` |
| `https://bitbucket.org/owner/repo` | `bitbucket` |
| sem remote / desconhecido | `null` → fallback `github` (ou `none`) |

---

## 🔀 Lógica de Transporte

| `FORGE_TRANSPORT` | `isConfigured` (github) | Transporte efetivo | Motivo |
|---|---|---|---|
| `cli` (ou ausente) | `gh auth status` ok **ou** token | `cli` | default; `gh` embute auth |
| `cli` | `gh` ausente mas token presente | `cli` → cai p/ `api` em runtime | fallback automático |
| `api` | token presente | `api` | REST direta via `gh api`/curl |
| `api` | sem token | não configurado | reporta variável faltando |

> O adapter consulta `config.transport`; se `transport='cli'` mas `gh` não responde em runtime, cai para `api` (espelha o fallback MCP→API do Task Manager).

---

## 🧪 Exemplos de Uso

```typescript
// Detectar forge e transporte
const config = detectForgeProvider();
console.log(`Provider:   ${config.provider}`);   // 'github'
console.log(`Transporte: ${config.transport}`);  // 'cli' | 'api'
console.log(`Configurado: ${config.isConfigured}`);

// Detectar provider de uma URL de remote
const p = detectProviderFromRemoteUrl('git@github.com:acme/app.git'); // 'github'
```

---

## 📚 Referências

- [Types](./types.md) — `ForgeConfig`, `ForgeTransport`, `ForgeProvider`
- [Factory](./factory.md) — consome `config.transport`
- [SDAAL](../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 1.0.0
**Criado em**: 2026-06-13
