---
title: 'Sinal de campo — arandek: falso-verde por escopo de detecção, hook que instrui pnpm, /meta:kg fora do cenário de origem'
date: 2026-07-25
from: arandek (consumidor)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core / sinal)
source_commit: 5e3ea5ee46ac
contexto: >-
  Segunda sessão pós-adoção. /warm-up → /catch-up → /meta:kg (auditoria de doc de
  arquitetura do produto contra o código) → materialização do achado em catraca de CI.
  1 defeito, 1 lição de doutrina, 1 validação, 1 padrão candidato.
---

# Sinal de campo — arandek, sessão 2

O trabalho da sessão: auditar o `docs/architecture/master-plan-v1.md` do Arandek (571 linhas,
destilação de 27 councils, "ratificado" em 2026-05-12) contra o código de 2026-07-24, modelar como
`.kg.yaml` e **converter o achado principal em mecanismo** (hard gate no CI). Resultado: 15 claims
confrontadas, 9 refutadas. O que segue é o que isso ensinou sobre **o Onion**, não sobre o Arandek.

---

## L1 — Falso-verde por ESCOPO DE DETECÇÃO (lição de doutrina, o item mais valioso)

**O core já tem doutrina anti-falso-verde** — a guarda de legibilidade do `kg-radar.sh` ("o radar tem
que saber que NÃO SABE"), o bug do `jq` de 2026-07-01, o sinal do CI regulado de 2026-07-17. Todos
são **falso-verde por bug ou por vacuidade**. Este é um modo terceiro, e não vi casa para ele:
**falso-verde por escopo de detecção — o gate está correto, roda, e mede a coisa errada.**

**O caso, concreto.** A auditoria achou que o invariante do "Contrato 2" do projeto era falso: o
código declarava "bypass mecanicamente impossível" e havia 17 call-sites cruzando a fronteira sem
executor nenhum. Escrevi a catraca banindo o import das primitivas do AI SDK (`streamText`,
`generateText`, …) de `'ai'`. Rodou: **0 violações não declaradas, verde, allowlist completa.**

Estava errado. **A pior violação do repo não aparecia** — uma rota de usuário em produção que não
importa de `'ai'`, importa um wrapper interno (`streamAgent`) de um propagador do próprio projeto. E
havia mais: um `export { runAgent } from '../ai/agent'` num arquivo de 2.400 linhas **lavando a
origem**, de modo que um terceiro arquivo cruza a fronteira sem que o nome do propagador apareça
nele. **7 das 8 travessias eram invisíveis ao gate**, que reportava verde.

Não foi bug. O gate fazia exatamente o que eu escrevi. O escopo de detecção é que era estreito, e
**verde num gate estreito lê-se como "coberto"**.

**A lição, generalizável:** ao converter achado de auditoria em mecanismo, o teste de aceite do gate
não é "roda e passa" — é **"ele pega o caso que motivou a existência dele?"**. Se o gate nasceu de um
achado concreto, o achado é o fixture obrigatório. Verde na primeira execução, sem esse teste, é
sinal de alarme e não de sucesso.

**Corolário sobre orquestração** (interessa à `onion-orchestration`): o inventário dos 17 call-sites
veio de subagentes com varredura paralela — trabalho bom, e **insuficiente para virar mecanismo**. Ao
re-derivar a lista à mão para montar a allowlist, achei (a) as 7 travessias por propagador, que
nenhum worker viu porque perguntei por `'ai'`, e (b) um arquivo inteiro omitido
(`blueprint-deriver.ts`). **Varredura de subagente não substitui re-derivação quando o resultado vai
virar catraca** — o custo do erro muda de "achado incompleto num relatório" para "gate verde sobre
buraco".

**Sugestão:** casa em `docs/knowledge-base/agentic-patterns/` (família do `verify-read-path-first` /
`declarado ≠ verificado`), e uma linha no `/meta:kg` §"Agir dirigido pelo veredito": quando uma claim
`confirmed` virar atuador, o fixture do atuador é a evidência que a confirmou.

---

## D1 — Hook de pre-commit instrui `pnpm install` num repo que proíbe pnpm

**Onde:** `.claude/hooks/` (mensagem do pre-commit nativo Onion).

Em todo commit desta sessão o hook imprimiu:

```
⏭️  lint-staged configurado, mas node_modules ausente (worktree?) — pulando.
    Rode 'pnpm install' p/ ativar.
```

O `package.json` do Arandek diz o oposto, mecanicamente:

```json
"packageManager": "bun@1.3.9",
"engines": { "bun": ">=1.3.0", "npm": ">=999.0.0", "pnpm": ">=999.0.0" }
```

Os `>=999.0.0` são um bloqueio deliberado — o projeto **faz o npm e o pnpm falharem de propósito**. E
o `CLAUDE.md` crava "Package manager: bun (nunca use npm, npx, yarn, pnpm)". O hook instrui o
adotante a rodar exatamente o comando que o projeto dele proíbe.

**É a mesma classe do D3 do sinal anterior** (o relatório de adoção instruindo `cp .env.example .env`
num repo cujo `CLAUDE.md` diz "NUNCA criar `.env` solto"). Padrão: **o Onion dá instrução de
ferramenta sem consultar o que o alvo declara**. Vale checar se há mais ocorrências do que estas duas.

**Sugestão:** ler `packageManager` do `package.json` quando existir; senão, mensagem agnóstica
("instale as dependências do projeto"). Custo baixo, e remove a fricção de o hook pedir algo que
falha por design.

---

## V1 — `/meta:kg` validado FORA do cenário de origem

O `/meta:kg` nasceu de auto-auditoria do framework (`/meta:evolve`) e de mapeamento de domínio. Aqui
foi usado num terceiro caso: **auditar um documento de arquitetura de produto contra o código**, num
adotante, por uma sessão que não conhecia o projeto na véspera. Funcionou sem adaptação — 60 nós, 73
arestas, camada `audit` pura.

**O radar pegou dois defeitos no meu próprio modelo**, e é isso que vale reportar:

1. Modelei `Q_ENVELOPE_LINT` (o lint) e `Q_PLAN_V2_OR_ARCHIVE` (o plano) como perguntas
   independentes. Ao pensar na ordem de execução, a dependência apareceu: a allowlist do lint **é** a
   definição do invariante, logo o plano tem que decidir primeiro. Aresta faltante, que só existiu
   porque o grafo me obrigou a nomear a relação.
2. Ao registrar que um achado superou outro, o gate de integridade recusou: alvo de `SUPERSEDES`
   ainda `confirmed`. A reconciliação de status é chata **e é exatamente o que impede a história de
   virar log cronológico**.

"O radar é o revisor" se sustentou em campo, num cenário que o comando não previa. Sem pedido
pendente — é evidência a favor da promoção do KG SDAAL de 🟡 candidata a ✅ ativa.

---

## S1 — Padrão candidato: catraca com allowlist justificada (oferta, não pedido)

O gate que escrevi tem três propriedades que talvez interessem ao core, porque atacam a fraqueza que
**o próprio lint do Onion se acusa** de ter. Em cada commit desta sessão apareceu:

```
VIOLATION: kg-coverage-baseline.txt: [CATRACA-FRACA] catraca comparando contra 'HEAD' (ref LOCAL):
           crescimento já commitado aqui NÃO é detectado
```

(idem `doctrine-freshness-baseline.txt` e `kb-vendored-link-baseline.txt` — 3 dos 5 SOFT são isso.)

O padrão que usei não tem baseline; tem **allowlist com justificativa obrigatória por entrada**:

- **A allowlist É o invariante.** Cada entrada carrega, em prosa, *por que* é permitida ou *qual*
  invariante viola. Entrada sem justificativa é omissão disfarçada de decisão — e isso é visível na
  code review, não escondido num `.txt` de hashes.
- **Dois tiers**: `LEGIT` (permitido por decisão) e `DEBT` (bypass real, declarado). Default passa e
  avisa; `--strict` falha enquanto houver `DEBT`. Isso deixa o gate entrar no CI **hoje**, como hard
  gate, sem esperar o conserto — e dá a régua do dia em que o contrato fica verdadeiro.
- **Entrada obsoleta falha o gate.** Se um arquivo saiu da allowlist ou parou de violar, o gate
  reclama. É o que impede a allowlist de apodrecer — o modo de falha que, neste projeto, fez um mapa
  de componentes virar código morto que a spec ainda mandava editar.

A terceira propriedade é a que a baseline-contra-HEAD não tem: **a catraca se limpa**. Se for útil,
o arquivo é `scripts/lint-provider-boundary.ts` no Arandek (~470 linhas, builtins só, com smoke test
`bun:test` de 13 casos). Não estou pedindo nada — sinalizando que existe.

---

## Nota — o falso-positivo do lint persiste no pin 5e3ee

O SOFT `docs/specs/capability-registry.md: '100+ agentes' (esperado 51+)` apareceu nos 5 commits
desta sessão. O sinal anterior registrou que a branch `fix/adopt-dogfood-gaps-arandek` (working tree
do core) já tratava isso. Só confirmando que **no pin adotado ainda ocorre** — é doc de produto do
Arandek falando dos agentes do próprio sistema, não do framework. Nenhuma ação minha; nada editado.

---

## Estado da adoção

| Item | Estado |
|---|---|
| Lint | 0 HARD, 5 SOFT (1 falso-positivo + 3 CATRACA-FRACA + 1 lexical) |
| `.kg.yaml` | primeiro do repo — `docs/onion/graph/master-plan-v1-vs-real.kg.yaml`, 60 nós / 73 arestas / 0 contradições |
| Hook "you have mail" | funcionando (📬/📥 zerados no boot desta sessão) |
| `bun` | não existia na máquina; instalado nesta sessão (1.3.14). Nenhum checkout tem `node_modules` |
| Branches | `onion/adopt` (9 commits) e `arch/master-plan-v2` (5) — **nenhuma no remoto ainda** |
