---
name: kg-inbox
description: Processa a fila de propostas de escrita no grafo (docs/evolution/kg-inbox/) — a perna de SELAGEM do write-leg (F4b). Lista as propostas pendentes, roda o radar advisory em cada uma, e para cada decide SELAR (integrar no grafo vivo + git mv → _sealed/) ou REJEITAR (git mv → _rejected/ com motivo). É o mecanismo que impede a fila de acumular sem controle. Human-in-the-loop na TRIAGEM (o que mora NESTE repo é juízo — o comando roteia por papel: o core sela doutrina do framework, um adotante sela o domínio dele), mecânico no resto.
category: meta
tags: [kg, kg-inbox, write-leg, sealing, i3, self-evolution, sdaal]
version: "1.1.0"
updated: "2026-09-05"
allowed-tools: Read Write Edit Grep Glob Bash(ls docs/evolution/kg-inbox/*) Bash(git mv docs/evolution/kg-inbox/*) Bash(bash .claude/validation/kg-radar.sh*) Bash(bash .claude/validation/onion-version.sh) Bash(git -C * log*)
argument-hint: "[--list | <slug-da-proposta>]  (sem arg = processa TODA a fila; --list = só mostra sem decidir)"
---

# 🧅 /meta:kg-inbox — selar a fila de propostas de escrita no grafo

A perna que faltava do **write-leg (F4b)**: `propose_kg_write` (via MCP `onion-exec`, ou qualquer
produtor) grava uma **proposta** em `docs/evolution/kg-inbox/<slug>-<ts>.proposal.kg.yaml` — **nunca
no grafo vivo** (I3, um escritor por repo). Este comando é o **selo**: o único ato que integra uma
proposta ao grafo vivo, ou a recusa. Sem ele a fila acumula sem controle (o gatilho que o criou:
2 propostas paradas, medido 2026-08-21).

> **O que este comando NÃO é.** Não é `propose_kg_write` (o *produtor* da proposta). Não é
> `/meta:co-evolve` (fila de mensagens entre repos). É o **consumidor** da fila `kg-inbox`, o
> equivalente do "core sela" que o README da fila descreve.

## Passo 1 — Roteamento por papel (o dono do repo sela a fila DO PRÓPRIO repo)

Ler `role:` do stamp `.claude/.onion-version` (só se ausente, cair para
`bash .claude/validation/onion-version.sh`) e rotear — **nunca parar por ser adotante**:

| `role:` | fila que este comando sela | grafo-alvo permitido |
|---|---|---|
| `source` (core) | `docs/evolution/kg-inbox/` **deste** repo | grafos **deste** repo |
| `adopted` \| `hub` | `docs/evolution/kg-inbox/` **deste** repo (a fila local do adotante) | grafos **deste** repo |

A I3 (um escritor por repo) proíbe escrever **repo alheio** — não a própria fila. Até 2026-09-04 este
comando confundia as duas coisas e **parava** em `role: adopted`, deixando o adotante sem mecanismo de
selagem: um adotante com colaborador (dono + visitante que propõe nós) forjou um comando local
`/portal:selar` para suprir, e sinalizou upstream. A forma é a mesma nos dois papéis — muda só quem é o
dono.

**O que segue proibido em qualquer papel — e a invariante é sobre o ATO, não sobre um campo.** O que
se prova no Passo 4 é que **o grafo-alvo escolhido resolve DENTRO deste repo** (`git ls-files` o vê);
alvo absoluto, com `../`, ou fora do `git ls-files` → **pare e reporte**: quem sela é a sessão do
repo-alvo. Medido em 2026-09-05: **nenhum produtor emite `meta.target` hoje** — as duas propostas
reais do corpus (`_sealed/gap-web-search-capability-*`, `_rejected/grana-ai-mapeamento-*`) trazem
`meta:` sem ele, e o `ops/mcp-onion-exec/server.py` só valida `nodes:`. Uma invariante ancorada nesse
campo seria **prosa inexequível** (a 1ª redação desta seção era). Logo: `meta.target`, **quando
presente**, é lido e obedecido; a guarda que decide é o caminho do alvo, que existe sempre.

Se a fila não existir (`docs/evolution/kg-inbox/` ausente), crie-a com o README do starter antes de
seguir — em adoções feitas antes de 2026-09-05 ela pode não ter nascido.

## Passo 2 — Levantar a fila

Listar `docs/evolution/kg-inbox/*.proposal.kg.yaml` (a raiz da fila — **não** `_sealed/`/`_rejected/`).
Fila vazia → reportar "nada a selar" e parar. Com `--list`: só mostrar o inventário (Passo 3 sem decidir).

Para cada proposta, ler o **cabeçalho** (`# origem: … · recebida: …`) — a proveniência importa na triagem.

## Passo 3 — Radar advisory + triagem (o juízo)

Para cada proposta:
1. `bash .claude/validation/kg-radar.sh <proposta>` — advisory, **não** gate (a proposta é fragmento;
   órfãos/impact são esperados). Absorver integridade e o teor dos nós.
2. Ler os `nodes:`/`edges:` e **decidir** por estes critérios, nesta ordem:

   **(a) FRONTEIRA DE REPO (I3) — o filtro mais importante, e ele é DESTE REPO, não do core.** A
   pergunta é **"este conhecimento mora NESTE repo?"** — o Passo 1 já disse qual é o papel, e a
   pergunta se instancia por ele:

   | `role:` | mora aqui (candidato a SELAR) | não mora aqui (**REJEITAR** + registrar o gap) |
   |---|---|---|
   | `source` (core) | o **próprio framework**: capacidade, gap, doutrina, decisão de arquitetura | contexto de **negócio de adotante/tenant** (produto, mercado, cliente) — mora no repo dele |
   | `adopted` \| `hub` | o **domínio deste repo**: produto, negócio, cliente, decisão de arquitetura DAQUI | doutrina do **framework** (isso é sinal upstream: vai por `/meta:co-relay` ao core, não por selagem aqui) · conhecimento de um **terceiro** repo |

   Note a simetria, e que ela não é cosmética: o que o core rejeita por fronteira é exatamente o que
   um adotante SELA, e vice-versa. Até 2026-09-05 esta seção perguntava apenas pelo core — então
   um adotante que passasse o Passo 1 era recusado aqui, no filtro seguinte, pelo mesmo conteúdo que é
   a razão de existir da fila dele. Meia cura é o modo de falha desta perna; o Elenxo desta mudança a
   pegou. *(Caso-semente do lado do core: um chat no papel-de-negócio propôs mapeamento do site de um
   cliente — recusado do core, e o gap virou `Q_TENANT_WRITE_DESTINATION`.)*

   **REJEITAR por fronteira NUNCA é o fim** — é o Passo 4 §REJEITAR item 2: o gap vira nó `open` no
   grafo de estado deste repo. Foi assim que o buraco do tenant ficou registrado em vez de evaporar.

   **(b) SINAL vs RUÍDO.** Artefato de teste, duplicata de nó já vivo, trivialidade → **REJEITAR** com motivo.

   **(c) SINAL REAL DO CORE** → **SELAR**.

## Passo 4 — Executar a decisão

**SELAR** (a proposta é sinal real do core):
1. Escolher o **grafo vivo alvo** entre os deste repo — **descubra, não presuma a convenção**:
   `git ls-files '*.kg.yaml' | grep -v /fixtures/`. Prefira consolidar em grafo existente a proliferar
   grafos minúsculos. Se nenhum couber, crie um novo **na convenção DESTE repo** (o core usa
   `docs/onion/graph/<slug>.kg.yaml`; um adotante usa a raiz que ele já usa — medido em 2026-09-05:
   dos adotantes locais, um guarda grafo em `docs/technical-context/graph/`, outro na raiz, e
   **nenhum** tem `docs/onion/graph/`; alvo hard-coded na convenção do core nasce morto fora dele).
   **GUARDA DO ATO (a invariante do Passo 1):** o alvo escolhido tem de aparecer no `git ls-files`
   deste repo (ou ser criado dentro dele). Caminho absoluto, `../`, ou fora deste repo →
   **pare e reporte**, e não sele.
2. Integrar os `nodes:`/`edges:` no alvo — **renomear id na colisão**, e **conectar** cada nó novo ao
   grafo (nunca deixar órfão grau 0). Ajustar `impact` para 1-5 se vier fora.
3. `bash .claude/validation/kg-radar.sh <alvo>` → **DEVE exit 0**. Se reprovar, a selagem não fecha —
   corrigir a integração antes de mover.
4. `git mv docs/evolution/kg-inbox/<proposta> docs/evolution/kg-inbox/_sealed/` e **prepend** ao
   arquivo movido uma linha `# SELADO em <alvo> · <AAAA-MM-DD> · sessão do core` (Aufhebung: não some).

**REJEITAR** (fronteira/ruído):
1. `git mv docs/evolution/kg-inbox/<proposta> docs/evolution/kg-inbox/_rejected/` e **prepend**
   `# REJEITADO: <motivo em uma linha> · <AAAA-MM-DD>` (a genealogia fica; nada se apaga).
2. Se a rejeição revela um **gap real** (ex.: a escrita de um papel-de-negócio precisa de destino
   fora do core), **registrar esse gap** como nó `open` no grafo de estado apropriado — o motivo não
   evapora em prosa.

## Passo 5 — Fechar o backlog

Se este comando **construiu ou consumiu** o mecanismo de um nó `open` do grafo de estado **deste**
repo (no core, ex.: `Q_SEALING_NO_MECHANISM`; num adotante, o equivalente dele), carimbar esse nó para
`done` + rodar o radar (exit 0). O grafo é o backlog: nada fica parado sem o nó refletir. E vale para
o gap que uma REJEIÇÃO abriu: ele nasce `open` aqui e é aqui que se fecha.

Saída:
```
🧅 kg-inbox — N proposta(s) processada(s)
   ✅ SELADAS (M): <slug> → <grafo alvo>
   ⊘ REJEITADAS (K): <slug> (<motivo>)
   📭 fila agora: 0 pendentes
   ▶ grafo(s) tocado(s): radar exit 0
```

## ⚠️ Notas

- **Selar é o único ato que escreve o grafo vivo a partir da fila** — e é do DONO DO REPO (core na
  fonte, maestro do adotante no adotante). O produtor (`propose_kg_write`) nunca escreve o vivo; este
  comando é o portão. A fronteira que a I3 impõe é de REPO, não de papel: nenhuma sessão sela proposta
  cujo alvo vive noutro repo.
- **Radar exit 0 no alvo é gate de selagem** (não da proposta): integração que quebra o grafo não sela.
- **Human-in-the-loop na triagem**, mecânico no `git mv` — a fronteira de repo (I3) é juízo, não regra
  de lista.
- Verbo solto em `meta/`; não funde nem dispara workflows faseados.

## 🔗 Referências

- Produtor da fila: `ops/mcp-onion-exec/server.py` (`propose_kg_write`) · README: `docs/evolution/kg-inbox/README.md`
- Doutrina write-leg: `docs/evolution/research/librechat-kg-runtime-2026-08/` (`D_WRITE_LEG_AS_PROPOSAL`, `Q_SEALING_NO_MECHANISM`)
- Fronteira I3 / um escritor por repo: `docs/knowledge-base/concepts/knowledge-graph-sdaal.md`
