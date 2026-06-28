# 🔌 IDeIdentifier — De-identification Abstraction Layer (SDAAL)

## 🎯 Propósito

Redigir/anonimizar **PII** (dados pessoais) de um texto **antes** de enviá-lo ao Claude, e **reidentificar** a resposta no fim do fluxo (round-trip). É a primeira abstração SDAAL cujo provider é um **runtime de inferência** — o "segundo runtime" da tese SDAAL (`LLM=runtime, Markdown=bytecode`): além do Transformer (Claude) que orquestra, um provider pequeno e **local** executa a tarefa estreita de de-identificação.

**Por que existe:** transforma "rodar dado sensível fora da empresa" (bloqueio de compliance LGPD/GDPR/HIPAA) em **"o dado sensível nunca sai"** — unlock de adoção para clientes regulados. O dado é redigido localmente; só o texto sanitizado vai ao orquestrador.

> **Fronteira (invariante do ADR `onion-adr-slm-as-tool-de-identification`):** o SLM é uma **ferramenta atrás de adapter**, nunca o orquestrador. Claude segue o cérebro; o humano-maestro segue invariante. SLM-como-orquestrador é fora de escopo.

## 📁 Estrutura

```
de-identification/
├── README.md
├── interface.md
├── types.md
├── detector.md
├── factory.md
├── adapters/
│   ├── regex.md       # baseline determinístico (sem LLM) — implementado
│   ├── local-slm.md   # SLM local p/ PII contextual — spec'd, roda no alvo
│   └── none.md        # fail-safe (avisa risco; NÃO envia silenciosamente)
└── scripts/
    └── redact-deterministic.sh   # runtime do adapter `regex` (determinístico, dogfoodável)
```

## ⚡ Uso Rápido

### 1. Configurar Provider

```bash
DEID_PROVIDER=regex          # none | regex | local-slm
# local-slm (roda no alvo — requer runtime de modelo):
DEID_SLM_ENDPOINT=http://localhost:11434   # estilo Ollama/vLLM
DEID_SLM_MODEL=llama3.2:3b
```

### 2. Usar nos Comandos

```typescript
const deid = getDeIdentifier();
const { redactedText, restoreMap } = await deid.redact(rawText);
// ... envia redactedText ao Claude, recebe resposta ...
const finalText = await deid.restore(claudeResponse, restoreMap);
```

### 3. Baseline determinístico direto (CLI)

```bash
S=.claude/utils/de-identification/scripts/redact-deterministic.sh
echo "$texto" | bash "$S" --redact  --map /tmp/m.tsv   # → texto redigido
echo "$red"   | bash "$S" --restore --map /tmp/m.tsv    # → original
```

## 🔧 Providers Suportados

| Provider | Status | Runtime | Notas |
|----------|--------|---------|-------|
| `regex` | ✅ implementado | determinístico (script) | PII de **formato fixo**: e-mail, CPF, CNPJ, telefone BR, cartão, IPv4. Roda no core. |
| `local-slm` | 📝 spec'd (gated) | SLM local (Ollama/vLLM) | PII **contextual** (nomes, endereços) + jurisdição. Roda **no alvo** (modelo não vive no core). |
| `none` | ✅ fail-safe | — | Sem provider → **avisa risco de vazamento + exige override humano**. Nunca envia em silêncio. |

---

**Versão**: 0.1.0
**Criado em**: 2026-06-27
**ADR**: `docs/analysis/onion-adr-slm-as-tool-de-identification-2026-06.md`
