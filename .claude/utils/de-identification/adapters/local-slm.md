# 🟡 Local-SLM Adapter (PII contextual — spec'd, roda no alvo)

## 🎯 Propósito

Provider de **juízo** para PII **contextual** que o baseline regex não pega: nomes de pessoas, endereços livres, organizações, e sensibilidade de **jurisdição** (o que é PII em LGPD vs GDPR vs HIPAA). É o "segundo runtime" no sentido pleno da tese SDAAL — um **SLM pequeno e local** como ferramenta de NER, chamado pelo orquestrador (Claude), **nunca** o substituindo.

> **Status: spec'd / gated.** O contrato está definido; a execução ao vivo é **follow-up gated** (gatilho: 1º adotante regulado com runtime de modelo). Ver ADR `onion-adr-slm-as-tool-de-identification-2026-06`.

---

## 🏠 Roda NO ALVO, não no core (invariante de honestidade)

O modelo e o runtime de inferência **não vivem no repositório do Onion** — exatamente como tokens de API (ex.: a Fase 4 da adoção configura o `.env` do alvo). O core entrega a **spec do adapter**; o adotante provê o runtime (Ollama/vLLM) e o modelo. Isso mantém o core leve e a tese "transporte/credencial/runtime são conduzidos do lado do adotante".

---

## 📋 Configuração

```bash
DEID_PROVIDER=local-slm
DEID_SLM_ENDPOINT=http://localhost:11434   # estilo Ollama (/api/generate) ou vLLM (OpenAI-compat)
DEID_SLM_MODEL=llama3.2:3b                  # SLM pequeno (1–12B) — tese do panorama jun/2026
DEID_SLM_TIMEOUT_MS=30000                   # opcional
```

Modelos candidatos (1–12B, NER/extração): Llama 3.x pequeno, Phi, Qwen pequeno, Gliner/Presidio-style. A escolha é do adotante (custo/idioma/licença).

---

## 🔧 Implementação (contrato)

```typescript
class LocalSlmAdapter implements IDeIdentifier {
  readonly provider = 'local-slm';
  readonly isConfigured: boolean;

  constructor(config: ProviderConfig) {
    this.isConfigured = config.isConfigured;   // endpoint + model presentes
  }

  async detect(text: string): Promise<PiiEntity[]> {
    // POST ao endpoint local com prompt de extração de PII (schema fixo → JSON).
    // Normaliza a saída do modelo para PiiEntity[] (type/span/value/confidence).
    // NUNCA chama nuvem; tudo local — esse é o ponto de compliance.
  }

  async redact(text, opts) {
    // detect() → substitui spans por placeholders tipados → restoreMap (igual ao regex).
    // RECOMENDADO: compor com o baseline regex (formato fixo) + SLM (contextual)
    // numa pipeline — regex pega o determinístico, SLM o resto.
  }

  async restore(redactedText, restoreMap) { /* substituição por placeholder (igual regex) */ }
  validateConfiguration() { return this.isConfigured; }
}
```

---

## 🧭 Princípio de design

- **Composição, não substituição:** o caminho robusto é `regex (formato fixo)` ⨉ `local-slm (contextual)` numa pipeline — determinístico primeiro, juízo depois.
- **Schema fixo = caso ideal de SLM:** extração de PII com saída estruturada é exatamente onde um modelo pequeno ganha do gigante (10–30x mais barato), conforme `docs/analysis/panorama-ia-generativa-2026-06.md`.

---

## 📊 Mapeamento

| Interface | local-slm | Notas |
|-----------|-----------|-------|
| `detect()` | inferência NER local → JSON | `confidence < 1.0` |
| `redact()` | spans do detect → placeholders | compõe com regex |
| `restore()` | substituição por placeholder | idêntico ao regex |

---

**Versão**: 0.1.0 (spec'd / gated)
