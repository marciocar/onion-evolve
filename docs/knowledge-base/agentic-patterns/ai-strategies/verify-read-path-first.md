# Verify-the-Read-Path-First — onde o dado vive é hipótese até rastrear quem o lê

> **Origem (crédito):** uma instância adotante (T1 hub), auditoria real de produção
> (auditoria de produção, 01/jul/2026) — sinal upstream
> `docs/evolution/inbox/_processed/2026-07-01-sinal-verificar-read-path-antes-de-concluir.md`.
> Triado e promovido pelo core em 2026-07-02 (radar: `assess` → `trial`).

## A regra

> Numa auditoria data-driven, a afirmação de um agente sobre **onde um dado vive** é uma
> **hipótese** até ser confirmada contra o **read-path real no código**. Antes de concluir a
> partir de um store (tabela, arquivo, cache, env), rastreie qual caminho de runtime
> **efetivamente lê** aquele dado na operação sob auditoria — e consulte **esse** store,
> não o de nome mais óbvio.

## O caso golden (antipadrão real)

Auditoria de deploy quebrado: a forense de banco quase cravou *"config da journey vazia"*
consultando a tabela de nome óbvio (`WRRJourneyConfig`) — quase vazia, congelada há um mês.
**O motor não lê essa tabela.** O caminho vivo do `decide()` lê **outra** (`Journey.config`,
acesso cru com `as any`, sem cache/validação), onde a config estava **completa**. As duas
coexistem e divergem em silêncio ("split-brain"). A conclusão certa não era "config vazia" —
era **"há duas fontes e o motor usa a que ninguém audita"**. O que evitou o veredito falso:
parar e rastrear no código de onde o runtime lê, antes de concluir a partir do banco.

## Corolários

1. **Split-brain é comum e invisível.** Camada "nova" (repo + cache + validação) coexistindo
   com caminho "legado" que lê o store cru → divergem em silêncio. Auditar só o novo dá
   falso-verde.
2. **Resumo de sub-agente ≠ evidência.** O que uma frota reporta como "fonte de X" entra no
   dossiê como *claim a verificar*, com citação `arquivo:linha` do read-path — nunca como
   fato herdado. (Foi um resumo herdado que quase produziu o veredito falso.)
3. **Verificação adversarial vale para dados, não só para código.** O hábito de "esse achado
   de bug é real?" aplica-se igual a "esse número do banco significa o que eu acho?".
4. **Divergência de fonte é achado, não ruído.** Quando dois extratores (ou um extrator e o
   banco) discordam sobre onde um dado vive, o sintetizador deve **sinalizar** — é
   provavelmente um split-brain sendo descoberto.

## Aplicação no Onion (contrato de worker)

- **Extrator (frota/Explore):** toda afirmação de *localização de dado* sai com
  **read-path verificado (`arquivo:linha`)** ou nasce marcada como **hipótese** — nunca como
  nó confirmado. (Disciplina registrada na skill `onion-orchestration`.)
- **Sintetizador (fan-in):** divergência de fonte entre workers = **achado** no relatório.
- No Knowledge Graph SDAAL: claim de localização sem `TRACES_TO {file:line}` do read-path
  fica `confidence` baixa e `status: open`.

## Família doutrinária — "estado declarado ≠ fato verificado"

Família consolidada em 2026-07-02/03 (todos com guarda/migalha; a migalha
`declared-vs-verified-family` manda: ao achar um caso novo, atualizar esta tabela):

| Membro | Declarado | Verificado | Registro |
|---|---|---|---|
| Pin é hipótese | stamp/members.yaml | artefato vendorizado (canário) | `pin-integrity-check.sh` + diário `forged-pin` |
| Working tree livre é hipótese | `git status` limpo | sessões vivas (farol 🕯️) | `session-beacon.sh` + diário `live-session-collision` |
| **Onde-o-dado-vive é hipótese** | tabela de nome óbvio / resumo de agente | **read-path no código** | este padrão + skill `onion-orchestration` |
| Linhagem de branch é hipótese | doc "PRs miram develop" / nome da branch | commit **deployado** (registry/ECS) + merge-base real | sinal de campo `2026-07-03-branch-lineage-divergence` (4º membro; comando `/meta:branch-health` é candidato gated — 2ª instância com multi-linhagem OU próxima confusão de base de PR) |

| **Gramática do artefato é hipótese** | o selo `meta.schema_version` (auto-declarado) | o parse extraiu nós — o radar **leu**? | `kg-radar.sh` guarda de legibilidade + fixture `bad-grammar` (PR #398, 2026-07-17 — o falso-verde de um adotante regulado) |
| **Síntese declarada ≠ achado verificável** | veredito em **prosa** (`H1·F6`, contável por grep — errável) | id de nó consultável no KG via `kg-radar` | pipeline pesquisa→KG + 1ª pesquisa nascida em KG (`docs/evolution/research/whatsapp-api-2026-07/`) |
| **Doutrina declarada ≠ praticada** | `effort` obrigatório na skill de orquestração | scripts Workflow que de fato **passam** `effort` | guarda a nomear — achado 2026-07-17 (~0 scripts passam hoje) |

> **Raiz da família** (maestro, 2026-07-17): *"a pior verdade é aquela que não temos certeza"* — a falsidade que
> se **sabe** falsa é inofensiva (ninguém age nela); a verdade que não se sabe incerta atravessa o gate e vira
> decisão. Por isso **certeza é CAMPO, não TOM**: todo gate/relatório distingue "conferi e está ok" de "não
> consegui conferir" — foi o fix do `kg-radar` ("o radar tem que saber que NÃO SABE").

Parentesco direto: [onion-dogfooding-doctrine](../../concepts/onion-dogfooding-doctrine.md)
("RODE o artefato; veredito de leitura é hipótese, exit code é evidência") e a governança
DEV↔PROD do [knowledge-graph-sdaal](../../concepts/knowledge-graph-sdaal.md) (plane PROD =
artefato vivo).
