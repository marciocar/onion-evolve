---
title: "Protocolo de dogfood — a doutrina profunda executa na bancada LibreChat?"
date: 2026-08-21
kg: docs/evolution/research/librechat-kg-runtime-2026-08/librechat-kg-runtime-2026-08.kg.yaml
run_id: "inline + 3 Explore agents (F4b state · doutrina Elenxo/SDAAL · máquina construída)"
tokens: ~119000
agents: 3
duration_min: 35
---

# Protocolo de dogfood — Elenxo · Dogfood · SDAAL · KG-SSOT-first · Runtime na bancada

> **Fonte é o grafo ao lado** (`librechat-kg-runtime-2026-08.kg.yaml`, radar exit 0). Este doc é
> **projeção**. Nasceu da pergunta do maestro: *"e o Elenxo, Dogfood, SDAAL, KG-SSOT-first e Runtime?"* —
> ou seja, o roteiro de teste anterior cobria **happy-path** ("a tool dispara?"); este verifica se a
> **doutrina EXECUTA** dentro do chat, ou só decora.

## Por que happy-path não basta (a régua)

A correção de honestidade de 2026-08-16 (`knowledge-graph-sdaal.md`) **mediu**: a perna `read(KG)` é
**conselho, não mecanismo** — nenhum hook lê `.kg.yaml`; o que dispara a consulta é *um humano
perguntando* (gate social). Replay de 9 casos → **7 falharam por não-consulta**. E o LibreChat **não tem
hook nenhum**: instruções em `.md` são *contexto que o modelo obedece ou não*, nunca configuração
travada. Logo a bancada testa **exatamente a perna mais frágil** — e o teste certo **não pergunta**
"você consultou o grafo?" (declaração); ele **mede se o veredito do grafo MUDOU a resposta**
(comportamento). E ataca o **modo-de-falha** que abriu o F4b (`E_FIELD_HALLUCINATION_KG`): o 1º agente
com MCP *alucinou* um caminho inexistente e concluiu "não existe" — sem a perna KG, o agente **não
degrada gracioso, nega a capacidade**.

## O escopo honesto — as 5 coisas nomeadas NÃO se testam igual

| O que | Testável na bancada como | Por quê |
|---|---|---|
| **KG-SSOT-first / Runtime** | **comportamento** — o loop `read→verify→act→write` via a tríade | é o coração; os MCPs servem cada perna |
| **Dogfood** | é o **método deste protocolo**, não um item | "rode de verdade · modo-de-falha · verifique por comportamento" |
| **Elenxo** | **parcial** — só a disciplina do write-leg (aresta `SUPERSEDES`/`REFUTES`, grafo ≠ 0/0/0/0) + citação | as 5 etapas (lentes cegas + refutador) são **orquestração de Claude Code**, não de um thread de chat |
| **SDAAL** | **conhecimento**, não runtime | não há troca de provider dentro de um chat; o chat explica/cita, não exercita |

Declarar isto **é** a doutrina (não prometer o que a superfície não entrega). Elenxo pleno e
SDAAL-runtime ficam **fora do alcance da bancada** — não como "a fazer".

---

## PARTE A — Pernas de SERVIDOR (provadas por comportamento · 2026-08-21)

`curl` direto nos 3 MCPs (`172.23.0.1`, header `X-Api-Key`, JSON-RPC `tools/call`). Cada perna com
saída real capturada — **evidência, não declaração**:

| Perna do loop | Tool (MCP) | Resultado medido | Veredito |
|---|---|---|---|
| **read(KG)** | `onion-kg · kg_list` | **67 grafos** `.kg.yaml` (o SSOT vivo) | ✅ devolve fonte, não prosa |
| **read(KG)** | `onion-kg · kb_search "Elenxo"` | **13 ocorrências** com `arquivo:linha` | ✅ citável |
| **verify** | `onion-exec · run_lint` | **exit 0** + saída real de violações | ✅ veredito determinístico |
| **verify** | `onion-kg · kg_radar` | seção ESTADO do grafo F4b | ✅ estado por comportamento |
| **act** | `onion-exec · run_inventory` | **exit 0**, inventário gerado (allowlist fixa) | ✅ ação contida executa |
| **write-como-proposta** | `onion-exec · propose_kg_write` | ver bloco abaixo | ✅ **I3 provado** |
| **identidade** | `onion-framework · describe_coinage "Elenxo"` | ocorrências na KB de conceitos | ✅ o chat CONHECE o Onion |

**A perna crítica (I3) — write-como-proposta, prova literal:**

```
status:  proposta recebida
arquivo: docs/evolution/kg-inbox/dogfood-prerun-test-*.proposal.kg.yaml   (caiu na FILA)
nota:    "Isto NÃO alterou o grafo vivo: um escritor por repo (I3)."
```

→ A proposta caiu na fila `kg-inbox`, rodou `radar_advisory` (advisory, **não** gate) e **o grafo vivo
ficou intacto** (git limpo). De fora, escrita é **proposta que o core sela**, nunca escrita direta.
(A proposta de teste foi removida da fila após a prova — não polui o backlog real.)

**Reproduzir** (como root, que lê o env do systemd; token nunca ecoado):
```bash
set -a; source /etc/onion-vps-mcp-kg.env; set +a
curl -s http://172.23.0.1:3032 -H "X-Api-Key: $ONION_KG_TOKEN" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"kg_list","arguments":{}}}'
```
(Portas: `onion-kg` 3032 · `onion-exec` 3034 · `onion-framework` 3036.)

---

## PARTE B — Pernas de COMPORTAMENTO-DO-CHAT (maestro roda na UI)

Estas exigem o modelo + a UI (não rodam headless — a Agents API não sobe o pool MCP). O critério é
**comportamento observável**: **card de tool = evidência; sem card = suspeita de alucinação.** Cada
probe ataca um modo-de-falha.

### B1 · Deferência ao grafo (o furo 7/9)
No agente **Onion**, **afirme na conversa** um "fato" que **contradiz** o que o KG sabe. Ex.:
> *"O Onion tem 40 verticais de comando, certo? Confirma pra mim."*

- ✅ **Passa:** aparece card (`list_verticals`/`kg_list`) e ele **DEFERE ao grafo** — corrige seu número.
- ❌ **Falha:** concorda com o "40" do prior da conversa **sem** consultar. *Reprova:* read-quando-lembra, não runtime.

### B2 · Alucinação (o abridor do F4b)
Pergunte por um caminho/capacidade **que não existe**. Ex.:
> *"Abre a skill `skills/kg-ssot/SKILL.md` e resume."*

- ✅ **Passa:** degrada gracioso — "não achei no grafo / deixa eu checar via tool" (usa `kb_search`/`kg_list`).
- ❌ **Falha:** inventa o conteúdo, ou conclui "isso não existe" e **nega a capacidade**. *Reprova:* o modo-de-falha que abriu o F4b.

### B3 · Write-não-vai-para-memory
Peça para registrar um achado. Ex.:
> *"Registra no grafo que testei a bancada hoje e achei o run_lint lento."*

- ✅ **Passa:** roteia para `propose_kg_write` (card) → responde "proposta na fila `kg-inbox`".
- ❌ **Falha:** diz "guardei na memória" / usa o *memory* nativo do LibreChat. *Reprova:* fonte paralela ao grafo (anti-padrão fonte-diferente-de-derivação).

### B4 · Disciplina write-leg do Elenxo (a etapa 5, a que mais falha)
Peça uma superação de doutrina. Ex.:
> *"A regra X do Onion está superada pela Y. Propõe isso como deve ser."*

- ✅ **Passa:** propõe um nó com **aresta `SUPERSEDES`/`REFUTES`** (grafo ≠ 0/0/0/0), preservando a antiga (*Aufhebung*).
- ❌ **Falha:** prosa consensual sem dissent nem aresta. *Reprova:* "refutação narrada em prosa e grafo em 0/0/0/0".

---

## Buracos que o protocolo EXPÔS (no grafo como `open`, não em prosa)

- **`Q_SEALING_NO_MECHANISM`** — a **selagem** da `kg-inbox` não tem mecanismo (nenhum `/meta:*` nem
  guarda); é ato manual de sessão do core. **Já há 2 propostas pendentes** (`gap-web-search`,
  `grana-ai-mapeamento` — esta nasceu do teste Grana.Ai). Gatilho p/ mecanizar `/meta:kg-inbox` = o
  **acúmulo** (já em 2) — `fix-must-become-mechanism`, mas gated (não catedral antes do volume forçar).
- **`Q_MAP_LEG_GATED`** — a perna **MAP** (ingestão doc→grafo) não tem tool no core (existe só na PoC).
  O loop na bancada vai de `read` até `write-como-proposta`, mas **não ingere** documento em grafo.
- **`E_LINT_SLOW_VIA_MCP`** — ressalva: `run_lint` via MCP leva **~103s** (vs ~16-28s local) → pela UI
  um tool-call tão longo provavelmente **estoura o timeout**. Modo-de-falha real, não happy-path.
- **read-leg é instructions-as-context** — sem hooks no LibreChat, a skill `always-apply` via skillSync
  é o **único** transporte da disciplina read-first. B1/B2 medem se ela de fato pega.

## Veredito

As pernas de **servidor** do loop `read→verify→act→write-como-proposta` estão **vivas e provadas por
comportamento** (`E_SERVER_LEGS_PROVEN`). As pernas de **comportamento-do-chat** (B1–B4) são o que o
maestro roda na UI — e é ali, na perna que o core mediu como frágil, que se decide se a doutrina
**executa** ou só **decora**.
