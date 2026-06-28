# ⚪ None Adapter (fail-safe — NÃO é no-op silencioso)

## 🎯 Propósito

Fallback quando `DEID_PROVIDER=none` (ou ausente). **Diferente** do Null Object típico das outras abstrações (task-manager/forge), que degrada em silêncio: aqui o "silêncio" seria justamente o risco que a abstração existe para evitar — enviar PII não redigida ao orquestrador.

Por isso o `none` é **fail-safe, não no-op**: ele **recusa** redigir-e-passar a menos que haja **override humano explícito**.

> Implementação concreta = `class NoDeIdentifierAdapter` em [factory.md](../factory.md) §NoDeIdentifierAdapter. Este documento descreve o **comportamento contratual**.

---

## 🔌 Comportamento por operação

| Operação `IDeIdentifier` | Comportamento em `none` |
|---|---|
| `detect` | retorna `[]` (não há runtime de detecção) |
| `redact` (sem `allowUnredacted`) | **lança erro** com aviso de risco de vazamento de PII + como configurar `regex`/`local-slm` |
| `redact` (`allowUnredacted: true`) | retorna o texto **inalterado** (override humano assumido) + `restoreMap` vazio |
| `restore` | retorna o texto como veio (nada a reidentificar) |
| `validateConfiguration` | `false` |

---

## 🧭 Princípio

Compliance falha **seguro**: na dúvida, **não vaze**. Um adotante que conscientemente aceita o risco (ex.: dados já anônimos, ou ambiente sem PII) passa `allowUnredacted: true` — uma decisão **explícita e auditável**, não um default silencioso.

Mensagem canônica do erro (pt-BR):

```
⚠️ DEID_PROVIDER=none: nenhuma de-identificação ativa. Enviar este texto ao modelo
PODE VAZAR PII. Configure DEID_PROVIDER=regex|local-slm, ou passe allowUnredacted:true
para assumir o risco explicitamente (override humano). Rode /meta:setup-integration.
```

---

## 📚 Referências

- [Factory](../factory.md) — implementação `NoDeIdentifierAdapter`
- [Interface IDeIdentifier](../interface.md) — fronteira fail-safe do `redact`
- [SDAAL — Null Object](../../../../docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md)

---

**Versão**: 0.1.0
