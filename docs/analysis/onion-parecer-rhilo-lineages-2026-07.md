# Parecer — duas linhagens no rhilo: reconciliar ou oficializar? (lente Onion)

> **Data**: 2026-07-03 · **Para**: decisão do maestro · **Provocado por**: sinal upstream
> `2026-07-03-branch-lineage-divergence` (rhilo-metagamify) + pedido explícito do maestro de
> aprofundamento com a lente do Onion. **Verificação em primeira mão** (não herdada do sinal):
> merge-base `c5036dfa` · `develop` +73 · `rhilo/main` +12 · `.claude/` por linhagem inspecionado.

## 0. TL;DR

A pergunta do rhilo ("reconciliar develop↔rhilo/main ou oficializar duas linhagens?") esconde a
pergunta real, que é do Onion: **a instância rhilo está PARTIDA em duas meias-instâncias** — a
linhagem que tem o framework não é a que trabalha, e a que trabalha não tem o framework.
Recomendo **não escolher entre as duas opções do sinal**, e sim um plano em 3 movimentos:
**(1) reunificar a IDENTIDADE Onion primeiro** (framework presente nas duas linhagens — é um
`--update` mirando a linhagem de produção, mecanismo que já existe); **(2) oficializar o modelo
de duas linhagens como estado DECLARADO E VERIFICADO** (tabela de linhagens + pins por linhagem
no members.yaml); **(3) reconciliar o CONTEÚDO via Knowledge Graph SDAAL, não via git merge** —
o conflito real (pesquisa da dose × motor shipado) é conflito de *verdades*, e a ferramenta certa
para isso é a que o próprio rhilo inventou.

## 1. O fato que muda o problema (verificado em primeira mão)

| Linhagem | Tem o quê | Não tem o quê |
|---|---|---|
| `develop` (+73) | **framework Onion completo** (pin verificado `083403c`), co-evolução, pesquisa WRR | o motor de produção (Modo Equilíbrio etc.) |
| `rhilo/main` (+12) e filhas (`audit/*`) | **o motor deployado** (= imagem ECS confirmada) | **framework Onion — só o stamp** (`.claude/.onion-version`, e forjado até ontem) |

Consequência que ninguém tinha nomeado: **as sessões de trabalho do rhilo operam SEM o framework**.
A auditoria WRR — que produziu o KG SDAAL, a governança DEV↔PROD e os sinais de hoje — rodou numa
branch filha de `rhilo/main`, onde `.claude/` não existe. O "Onion" que ela usou foi só o skeleton
do CLAUDE.md (restaurado em 30/jun) + a convenção dos canais `docs/evolution/`. Todos os enablers
entregues nesta semana (farol 🕯️, lint `--only`, guardas, `/meta:diary` v1.2.0, co-evolve W6)
**não alcançam quem trabalha** — foram vendorizados na linhagem errada para esse fim.

Dois corolários honestos:

- **O incidente do pin forjado era sintoma, não causa.** O restore de 30/jun carimbou `rhilo/main`
  porque era ali que a sessão vivia — e ali não havia framework para o carimbo apontar. A cura
  (pin-integrity) trata a mentira do carimbo; **não trata a ausência que a motivou**.
- **A qualidade dos sinais do rhilo NÃO veio do nosso vendor** — veio do CLAUDE.md + da cultura
  da instância. Isso é humilhante e valioso: a camada mais fina do Onion (constituição + canais)
  carrega sozinha boa parte do valor. Mas os guard-rails determinísticos (lint, selftest, farol,
  pin-integrity) só existem onde o `.claude/` existe — e a sessão de produção está nua deles.

## 2. As duas opções do sinal, avaliadas com a lente do Onion

### Opção A — Reconciliar (merge develop ↔ rhilo/main)

**A favor:** uma linhagem só; pin único; `--update` alcança todo mundo; fim do split-brain.
**Contra, e é decisivo:** o conflito entre as linhagens **não é textual, é epistêmico**. A
`develop` carrega ~13 commits de *pesquisa* (sims Fase B, ADR-018) que **REFUTAM parcialmente** a
dose que o `rhilo/main` *shipou*. Um `git merge` não reconcilia verdades — mistura arquivos. O
resultado seria uma linhagem única onde doc de pesquisa contradiz código em produção **dentro do
mesmo commit**, o pior dos mundos para a governança DEV↔PROD. Além do risco operacional: merge
grande na linhagem que É a imagem de produção, no meio de uma auditoria viva.

### Opção B — Oficializar duas linhagens com política de sync

**A favor:** honesto com a realidade (o rhilo já corrigiu o CLAUDE.md com a tabela de linhagens);
multi-linhagem de longa duração é legítimo (produto estável + pesquisa ativa).
**Contra, se ficar só nisso:** oficializa também a **partição da identidade Onion** — o framework
continua onde ninguém trabalha. E cria débito no modelo de federação: o `members.yaml` assume UM
pin por membro ("pin espelha a branch onde o vendor vive"); duas linhagens com vendors distintos
exigem o modelo declarar isso, senão o pin-integrity vira loteria de branch (já vimos: o check na
working tree do rhilo acusa `pin-untrusted` sempre que a sessão está na linhagem de produção — o
guard certo gritando pelo motivo errado).

## 3. Recomendação — 3 movimentos, na ordem

**Movimento 1 — Reunificar a identidade (urgente, barato, mecanismo já existe).**
Um `/meta:adopt --update` mirando **uma branch de integração da linhagem de produção** (ex.:
`chore/onion-framework` cortada de `rhilo/main`, PR para `rhilo/main`). O manifesto do update já é
framework-only — não toca o motor. Resultado: as sessões que trabalham ganham lint, selftest,
farol, diary e guardas; o stamp da linhagem de produção vira **verdadeiro** pela primeira vez.
*(Detalhe de execução: o co-evolve/inbound continua canônico na `develop` — entregar avisos nas
duas linhagens custa nada, o inbound é untracked e atravessa branches.)*

**Movimento 2 — Oficializar o modelo de duas linhagens como estado declarado E verificado.**
(a) A tabela de linhagens do CLAUDE.md do rhilo (já feita por eles) vira padrão do core — skeleton
do `/meta:recover` já atualizado nesta entrega. (b) `members.yaml` ganha, para membros
multi-linhagem, o mapa explícito `lineages: {integration: develop@<pin>, production: rhilo/main@<pin>}`
— o pin deixa de ser escalar quando a realidade não é escalar (4º membro da família "declarado ≠
verificado": linhagem é hipótese até o mapa + canário confirmarem). (c) `/meta:branch-health`
continua **gated** — mas o gatilho amadureceu: *implementar quando o Movimento 1 rodar* (a
verificação de 2 pins × 2 canários à mão já será chata o bastante para justificar o comando).

**Movimento 3 — Reconciliar o CONTEÚDO com a ferramenta do próprio rhilo, não com git.**
O conflito pesquisa-vs-shipado é exatamente o caso de uso do **Knowledge Graph SDAAL**: modelar a
dose num `.kg.yaml` — claims do motor shipado (plane PROD, com migalha ECS) × claims da pesquisa
(plane DEV) — e deixar as arestas `REFUTES`/`SUPERSEDES` + o radar dizerem **o que merece virar
PR e em qual direção**. Só DEPOIS desse veredito decide-se o que a `develop` envia ao `rhilo/main`
(ou descarta). Bônus estratégico: **este seria o 1º dogfood do KG no fluxo do core↔adotante — o
gatilho exato que destrava o comando `/meta:kg`**. O rhilo inventou a ferramenta; a primeira
reconciliação de linhagens dele é o batismo natural dela.

## 4. O que o core absorve de doutrina (independente da decisão do rhilo)

1. **"Vendor onde se trabalha" é pré-condição, não detalhe:** adotante multi-linhagem sem framework
   na linhagem de trabalho = instância nominal. Candidato a check no relatório de update (o
   `--update` avisar: "a branch alvo não é ancestral das branches de trabalho recentes").
2. **Pin escalar é hipótese de linhagem única** — members.yaml precisa do conceito `lineages` para
   membros como o rhilo (schema a evoluir quando o Movimento 2 for autorizado).
3. **git merge não reconcilia verdades** — conflito epistêmico entre linhagens se resolve na camada
   de conhecimento (KG SDAAL), e só então na camada de código. Isso vira nota na KB
   `knowledge-graph-sdaal` quando o 1º dogfood acontecer.

## 5. Decisões pedidas ao maestro

| # | Decisão | Recomendação |
|---|---|---|
| D1 | Executar Movimento 1 (update na linhagem de produção do rhilo)? | **Sim, já** — mecanismo existente, risco baixo, destrava tudo |
| D2 | Oficializar 2 linhagens (CLAUDE.md padrão + `lineages:` no members.yaml)? | Sim, junto com D1 |
| D3 | Reconciliação de conteúdo via `.kg.yaml` (1º dogfood do KG, destrava `/meta:kg`)? | Sim, mas quem executa é a sessão do rhilo (é o domínio dela) — o core anuncia o convite |
| D4 | Merge total develop↔rhilo/main | **Não agora** — só após D3 dizer o que merece atravessar |
