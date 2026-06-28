# 🟢 Regex Adapter (baseline determinístico)

## 🎯 Propósito

Provider **determinístico, sem LLM e sem rede** para PII de **formato fixo**. É o "segundo runtime" determinístico da abstração — o equivalente P1 da régua P0-P3 (determinístico → script). Roda no core e é **dogfoodável** (coberto por `lint-selftest.sh :: run_de_identification_selftests`).

> Implementação concreta = `../scripts/redact-deterministic.sh`. Este documento descreve o **comportamento contratual**.

---

## 📋 Configuração

```bash
DEID_PROVIDER=regex
# sem credencial — determinístico
```

---

## 🔧 Cobertura (PII de formato fixo)

| `PiiType` | Padrão (regex) | Exemplo |
|-----------|----------------|---------|
| `EMAIL` | `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}` | `a@b.com.br` |
| `CNPJ` | `\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}` | `12.345.678/0001-99` |
| `CPF` | `\d{3}\.\d{3}\.\d{3}-\d{2}` | `123.456.789-09` |
| `CARD` | `\d{4}[ -]\d{4}[ -]\d{4}[ -]\d{4}` | `4111 1111 1111 1111` |
| `IPV4` | `\b(?:\d{1,3}\.){3}\d{1,3}\b` | `10.0.0.1` |
| `PHONE` | `\(?\d{2}\)?[ -]?9?\d{4}-\d{4}` | `(11) 98765-4321` |

**Ordem de resolução:** alternativas mais específicas primeiro (e-mail; CNPJ antes de CPF; cartão antes de telefone) — `re` escolhe a 1ª que casa na posição.

---

## 🧭 Garantias

- **Determinístico:** mesma entrada → mesma saída. Placeholders `[[TYPE_N]]` numerados por ordem de aparição; valor repetido → **mesmo** placeholder (round-trip consistente).
- **Reversível:** `--map` grava `placeholder<TAB>original`; `--restore` reconstrói o texto byte-a-byte.
- **No-op idempotente:** texto sem PII de formato fixo sai inalterado.

## ⚠️ Limites (deliberados → vão para `local-slm`)

- **Não** cobre PII **contextual**: nomes de pessoas, endereços livres, organizações.
- **Não** valida dígito verificador (Luhn/CPF) — casa por **forma**, não por validade. (Refinamento gated.)
- Dependência: `python3` (regex + escaping seguros); ausente → exit 3 (pulado gracioso no selftest).

---

## 📊 Mapeamento

| Interface | Baseline regex | Notas |
|-----------|----------------|-------|
| `redact()` | `redact-deterministic.sh --redact --map` | placeholders + restoreMap |
| `restore()` | `redact-deterministic.sh --restore --map` | round-trip |
| `detect()` | varredura regex sem substituição | `confidence: 1.0` (formato fixo) |

---

**Versão**: 0.1.0
