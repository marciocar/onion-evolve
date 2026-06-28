# 📐 Interface IDeIdentifier

## 🎯 Propósito

Contrato agnóstico de provider para de-identificação de PII. O consumidor (comando/agente) chama **sempre** esta interface — nunca o provider direto (invariante §9 de `integrations.md`). O adapter resolve qual runtime executa (regex determinístico, SLM local, ou fail-safe `none`).

---

## 📋 Interface Completa

```typescript
interface IDeIdentifier {
  // ═══════════════════════════════════════════════════
  // IDENTIFICAÇÃO
  // ═══════════════════════════════════════════════════

  readonly provider: DeIdentifierProvider;   // 'regex' | 'local-slm' | 'none'
  readonly isConfigured: boolean;

  // ═══════════════════════════════════════════════════
  // OPERAÇÕES PRINCIPAIS
  // ═══════════════════════════════════════════════════

  /** Detecta entidades de PII sem alterar o texto. */
  detect(text: string): Promise<PiiEntity[]>;

  /**
   * Redige PII e devolve o texto sanitizado + o mapa de restauração.
   * Placeholders são tipados e numerados por ordem de aparição; valor
   * repetido → mesmo placeholder (reidentificação consistente).
   */
  redact(text: string, opts?: RedactOptions): Promise<RedactionOutput>;

  /** Reconstrói o texto original a partir do redigido + restoreMap (round-trip). */
  restore(redactedText: string, restoreMap: RestoreMap): Promise<string>;

  // ═══════════════════════════════════════════════════
  // VALIDAÇÃO
  // ═══════════════════════════════════════════════════

  validateConfiguration(): boolean;
}
```

---

## 🔒 Fronteira contratual

- **`redact` é fail-safe:** se `provider === 'none'`, a implementação **não retorna o texto silenciosamente** — emite aviso de risco de vazamento de PII e exige override humano explícito (`opts.allowUnredacted === true`). Ver `adapters/none.md`.
- **Reversibilidade:** `restore(redact(t).redactedText, redact(t).restoreMap) === t`. O baseline `regex` garante isso deterministicamente (coberto no selftest).
- **Não-vazamento de tipos:** `PiiEntity`/`RedactionOutput` são tipos da interface, não do provider — o adapter normaliza a saída do seu runtime para eles.

---

## 📊 Métodos por Categoria

| Categoria | Métodos | Descrição |
|-----------|---------|-----------|
| Identificação | `provider`, `isConfigured` | Info do adapter ativo |
| Principais | `detect`, `redact`, `restore` | Detecção, redação e round-trip |
| Validação | `validateConfiguration` | Verifica `.env` do provider |

---

**Versão**: 0.1.0
