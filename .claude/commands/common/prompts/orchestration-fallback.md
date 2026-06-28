# Fallback Serial da Orquestração

Fragmento canônico de degradação da camada de orquestração. Referenciado por
`/meta:orchestrate`, skill `onion-orchestration` e `/engineer:pre-pr` — **não duplique**
esta lógica em cada consumidor; inclua apenas um backlink para este arquivo.

---

## 🔍 Passo 0 — Health-check do substrato

Antes de qualquer fan-out, confirme que a ferramenta nativa **Workflow** está
disponível no ambiente atual. Essa verificação é **determinística** — não
dependa de inferência nem de o modelo "perceber" que o substrato falhou.

```markdown
SE Workflow disponível:
  → Prosseguir com fan-out nativo (parallel / pipeline)
SE Workflow indisponível:
  → Acionar fallback serial imediatamente (Passos 1-4 abaixo)
  → NÃO tentar invocar Workflow mesmo assim
```

---

## ⚠️ Passo 1 — Aviso obrigatório ao usuário

Ao detectar substrato indisponível, **antes de processar qualquer item**,
informe o usuário em pt-BR:

```
⚠️ **Substrato de orquestração indisponível**

A ferramenta nativa Workflow não está acessível neste ambiente.
O trabalho seguirá de forma **serial** (um item por vez) — o resultado
será idêntico ao do modo paralelo, porém mais lento.

∟ Itens a processar: <N>
∟ Modo: serial via Agent (sem paralelismo real)
```

Nunca omitir esse aviso nem fingir que o processamento é paralelo.

---

## 🔄 Passo 2 — Iteração serial com Agent

Itere os itens **um a um**, invocando a ferramenta `Agent` a cada ciclo.
Mantenha o **mesmo `schema` por item** usado no modo paralelo — a estrutura
de saída nunca muda conforme o substrato.

```markdown
PARA CADA item em [lista de itens]:
  1. Invocar Agent com o mesmo prompt e schema do worker paralelo
  2. Aguardar resultado antes de avançar ao próximo
  3. SE resultado válido → acumular em resultados[]
  4. SE resultado nulo / falhou schema → registrar como SKIP (ver Passo 3)
```

**Não inventar concorrência** (threads falsas, chamadas sobrepostas não
suportadas pelo ambiente, simulação de `Promise.all`). Serial é serial.

---

## 🚫 Passo 3 — Tratamento de falha parcial

Este tratamento é **igual para os dois modos** (paralelo e serial). Um worker
com falha nunca deve silenciar nem corromper o relatório final.

### Regra de filtragem

```javascript
// Após coletar todos os resultados (paralelo ou serial):
const valid = results.filter(Boolean);
const skipped = results.length - valid.length;
```

### Causas de SKIP reportáveis

| Causa | Rótulo no relatório |
|-------|---------------------|
| Worker retornou `null` / `undefined` | `SKIP — resultado nulo` |
| Output falhou na validação do `schema` | `SKIP — schema inválido` |
| Timeout de worker (I/O externo) | `SKIP — timeout` |
| Budget de tokens esgotado no worker | `SKIP — budget esgotado` |

### Formato de reporte de descarte

```
∟ ⚠️ Descartados: <skipped>/<total> itens
  ∟ SKIP — <item>: <causa>
  ∟ SKIP — <item>: <causa>
```

Se todos os itens forem descartados, **abortar** com erro claro e não
apresentar relatório vazio como sucesso.

---

## 📥 Passo 4 — Consolidação (fan-in)

O fan-in é **idêntico** nos dois modos — o contexto principal agrega,
deduplica e ranqueia os resultados válidos. Nenhuma lógica de consolidação
deve depender do substrato usado.

```markdown
1. Aplicar .filter(Boolean) nos resultados acumulados
2. Reportar descartados (se houver) conforme Passo 3
3. Agregar, deduplicar e ranquear no contexto principal (custo 0 tokens)
4. Se havia verificação adversarial no plano original → mantê-la sobre os
   resultados válidos (mesmo que reduzidos pela filtragem)
5. Emitir o relatório consolidado único — nunca N saídas soltas
```

---

## 📤 Saída esperada (modo serial)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 ORQUESTRAÇÃO SERIAL (fallback)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

▶ Tarefa: <descrição>
◆ Modo: serial via Agent (Workflow indisponível)
◆ Itens processados: <válidos>/<total>

∟ Resultado consolidado:
  ✅ [achado/decisão 1]
  ⚠️ [achado/decisão 2]
  ❌ [violação bloqueante, se houver]

∟ Descartados: <N> — ver lista de SKIPs acima
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 📋 Invariantes (valem para ambos os modos)

| Invariante | Paralelo | Serial |
|------------|----------|--------|
| Mesmo `schema` por worker | ✅ | ✅ |
| `.filter(Boolean)` antes do fan-in | ✅ | ✅ |
| Descartados reportados | ✅ | ✅ |
| Fan-in produz resultado único | ✅ | ✅ |
| Verificação adversarial (se planejada) | ✅ | ✅ |
| Nunca fingir paralelismo inexistente | — | ✅ obrigatório |

---

## 🔗 Consumidores deste fragmento

- `/meta:orchestrate` — Passo 0 e seção "Fallback serial" (`commands/meta/orchestrate.md`)
- `onion-orchestration` — seção "Resiliência" (`.claude/skills/onion-orchestration/SKILL.md`)
- `/engineer:pre-pr` — nota "Fallback sequencial" na seção de fan-out
  (`commands/engineer/pre-pr.md`)
