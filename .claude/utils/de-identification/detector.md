# 🔍 Detector de Provider — De-identification

## 📋 detectDeIdProvider()

Lê `DEID_PROVIDER` do `.env` (default `none`) e resolve a config. **Invariante §9:** nunca assumir provider sem ler o `.env`; nunca exigir credencial fora do `.env`.

```typescript
function detectDeIdProvider(): ProviderConfig {
  const provider = (process.env.DEID_PROVIDER || 'none') as DeIdentifierProvider;

  const configs: Record<DeIdentifierProvider, ProviderConfig> = {
    'regex': {
      provider: 'regex',
      isConfigured: true,                    // determinístico, sem credencial
      requiredEnvVars: [],
      optionalEnvVars: [],
    },
    'local-slm': {
      provider: 'local-slm',
      isConfigured: !!process.env.DEID_SLM_ENDPOINT && !!process.env.DEID_SLM_MODEL,
      requiredEnvVars: ['DEID_SLM_ENDPOINT', 'DEID_SLM_MODEL'],
      optionalEnvVars: ['DEID_SLM_TIMEOUT_MS'],
      errorMessage: 'local-slm requer DEID_SLM_ENDPOINT + DEID_SLM_MODEL no .env (roda no alvo). Rode /meta:setup-integration.',
    },
    'none': {
      provider: 'none',
      isConfigured: true,                    // fail-safe sempre "configurado"
      requiredEnvVars: [],
      optionalEnvVars: [],
    },
  };

  return configs[provider] || configs.none;
}
```

---

## 📊 Variáveis de Ambiente

| Provider | Obrigatórias | Opcionais |
|----------|--------------|-----------|
| `regex` | — | — |
| `local-slm` | `DEID_SLM_ENDPOINT`, `DEID_SLM_MODEL` | `DEID_SLM_TIMEOUT_MS` |
| `none` | — | — |

> Fallback gracioso: provider `local-slm` mal configurado → avisar em pt-BR qual variável falta + sugerir `/meta:setup-integration`; **não** cair em `regex` nem em `none` silenciosamente (a escolha de provider é do maestro).

---

**Versão**: 0.1.0
