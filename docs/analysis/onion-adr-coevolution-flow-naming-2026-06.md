---
title: 'ADR — Vocabulário dos fluxos de co-evolução: downstream / upstream / handoff (aposenta flow A/B/C)'
date: 2026-06-24
type: adr
status: accepted
decision-scope: co-evolution / vocabulary
supersedes: none
deciders: maestro + sessão de evolução
context_freshness: 2026-06-24
related:
  - ../evolution/rfc/rfc-0001-co-evolution-comms.md (fonte canônica do modelo de 3 fluxos)
  - ../meta-specs/code-standards.md §7 (regra: rotular referências opacas)
  - ../evolution/README.md (guia operacional dos fluxos)
---

# ADR — Vocabulário dos fluxos de co-evolução

> **Status: ACEITO.** Decisão de vocabulário (não de mecânica): renomeia os 3 fluxos de co-evolução de
> rótulos opacos (*flow/fluxo A/B/C*) para nomes próprios (**downstream / upstream / handoff**). A mecânica
> dos fluxos é inalterada — só o nome.

## Contexto

O modelo de co-evolução (RFC-0001) nomeava os fluxos por **letra**: *flow A* (core→projetos), *flow B*
(projetos→core), *flow C* (intra-repo). São **ids nus** — o leitor para e rebusca "qual era o A?" toda vez,
e por isso sempre vinham com glossa colada (*flow A core→projetos*). Isso **contraria a própria regra do
framework** "rotular referências opacas" (code-standards §7, elevada de regra pessoal). O maestro levantou
a pergunta diretamente: *"flow A/flow B são a melhor denominação única para isso?"*

Dois problemas: (1) **A/B/C são opacos** — letras não carregam direção nem conteúdo; (2) **C não é par de
A/B** — A e B são *direções cross-repo*; C é *concorrência intra-repo* (worktrees/handoff). Lump dos três
como "A/B/C" é cheiro de taxonomia: são eixos diferentes.

## Decisão

Adotar **nomes direcionais auto-explicativos**, promovendo os termos que a **própria RFC-0001 já usava como
glossa** (validação de coerência: não é termo novo):

| Antes | Canônico (a partir de 2026-06-24) | Natureza |
|---|---|---|
| flow A | **downstream** (anúncio/release; core→adotante) | direção cross-repo |
| flow B | **upstream** (sinal/feedback; adotante→core) | direção cross-repo |
| flow C | **handoff** (worktrees/um-escritor; intra-repo) | concorrência intra-repo (eixo distinto) |

`downstream`/`upstream` é o termo padrão OSS para a relação core↔derivados — único, preciso, sem precisar
de legenda. `handoff` separa o eixo intra-repo do cross-repo.

**Escopo da migração:** canônico (RFC-0001) + sweep dos artefatos **vivos** (README, comandos `co-*` e
`adopt`, hook, `members.yaml`, KBs e ADRs de federação). **Exclui história imutável** — `CHANGELOG.md`
(append-only, I7) e `*/_processed/` (auditoria) **preservam** "flow A/B": reescrevê-los violaria o
invariante append-only. Quem lê uma entrada antiga encontra a nota de equivalência na RFC-0001.

## Consequências

- ✅ Vocabulário auto-explicativo; elimina o id opaco da operação diária (cumpre code-standards §7).
- ✅ Separa o eixo intra-repo (handoff) das direções cross-repo (down/upstream).
- ✅ Coerente com a RFC-0001 (que já usava os termos) e com o mundo OSS (down/upstream).
- ⚠️ Convivência temporária: história append-only mantém "flow A/B" — aceitável (é auditoria; a nota de
  equivalência na RFC-0001 cobre o leitor).
- ⚠️ Sweep cross-cutting (~25 arquivos vivos) — feito numa rodada, com exclusão explícita da história.

## Alternativas consideradas

1. **anúncio / sinal** (semântico pt-BR) — bom e já era glossa de fato, mas menos preciso sobre *direção* e
   não cobre o eixo intra-repo; `downstream/upstream` é o padrão OSS reconhecível. Mantidos como apelidos
   semânticos aceitáveis na conversa.
2. **Manter flow A/B/C** — rejeitado: contraria a regra de rotular referências opacas que o próprio
   framework canonizou.
3. **Renomear só daqui pra frente (sem sweep)** — rejeitado: deixaria o id opaco vivo em metade dos
   artefatos operacionais; meia-migração é a pior das opções.
