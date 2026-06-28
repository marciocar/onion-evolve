# 🏭 Factory — De-identification

## 📋 getDeIdentifier()

```typescript
function getDeIdentifier(options?: FactoryOptions): IDeIdentifier {
  const config = options?.forceProvider
    ? { ...detectDeIdProvider(), provider: options.forceProvider }
    : detectDeIdProvider();

  if (!config.isConfigured && options?.throwOnMisconfigured) {
    throw new Error(config.errorMessage);
  }

  switch (config.provider) {
    case 'regex':
      return new RegexAdapter();            // delega ao scripts/redact-deterministic.sh
    case 'local-slm':
      return new LocalSlmAdapter(config);   // roda no alvo (Ollama/vLLM); ver adapters/local-slm.md
    default:
      return new NoDeIdentifierAdapter();   // fail-safe
  }
}
```

---

## ⚙️ FactoryOptions

```typescript
interface FactoryOptions {
  debug?: boolean;
  throwOnMisconfigured?: boolean;
  forceProvider?: DeIdentifierProvider;
}
```

---

## 📊 NoDeIdentifierAdapter (fail-safe — NÃO é no-op)

Diferente do Null Object típico (que degrada em silêncio), o `none` da de-identification é **fail-safe**: redigir nada e enviar PII ao orquestrador é justamente o risco que esta abstração existe para evitar.

```typescript
class NoDeIdentifierAdapter implements IDeIdentifier {
  readonly provider = 'none';
  readonly isConfigured = false;

  async detect() { return []; }

  async redact(text: string, opts?: RedactOptions): Promise<RedactionOutput> {
    if (!opts?.allowUnredacted) {
      throw new Error(
        '⚠️ DEID_PROVIDER=none: nenhuma de-identificação ativa. Enviar este texto ' +
        'ao modelo PODE VAZAR PII. Configure DEID_PROVIDER=regex|local-slm, ou passe ' +
        'allowUnredacted:true para assumir o risco explicitamente (override humano).'
      );
    }
    return { redactedText: text, entities: [], restoreMap: {}, provider: 'none' };
  }

  async restore(redactedText: string) { return redactedText; }
  validateConfiguration() { return false; }
}
```

---

**Versão**: 0.1.0
