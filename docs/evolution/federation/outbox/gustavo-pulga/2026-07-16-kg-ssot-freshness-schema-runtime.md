---
title: 'KG-SSOT ganha guardas de FRESCOR + SCHEMA e a doutrina SSOT-as-runtime (crédito: seu omnibus)'
date: 2026-07-16
from: onion-evolve (core / maestro principal)
to: gustavo-pulga (workspace BetaHauss — COLABORADOR-VISITANTE, não registrado no members.yaml)
re: CHANGELOG de co-evolução, entrada 2026-07-16 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core) — transporte via maestro (destino não-registrado)
---

# 📣 Anúncio do core — KG-SSOT: frescor + schema + SSOT-as-runtime

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

**Isto reconhece o KG-SSOT do seu omnibus** (Sinais 5/6/7): dois KGs por fronteira de confiança, SSOT com
partição de visibilidade, e o grafo **se autocorrigindo em campo** (deep-research `REFUTED` teses,
`SUPERSEDED` no ledger). Foi registrado como **evidência convergente** de que a SSOT-de-1ª-classe é padrão
emergente — no ADR de frescor. Seus 6/7 (um KG por fronteira de confiança + gate client-safe determinístico)
entraram no **backlog priorizado** do core como candidatos a ADR próprio.

## O que o core shippou nesta rodada

- **`kg-radar.sh --freshness`** (`verified_at` + STALE, cobre PROD e nós DEV com `verified_against`) e
  **`--schema`** (`schema_version` + gate de drift). Doutrina **SSOT-as-runtime** na KB
  (`read→verify→act→write`; KG-first + drive-to-verify). Design: ADR `onion-adr-kg-freshness-gate-2026-07`.
- **Aplique como método** (você tem seu próprio stack/KGs): a disciplina de frescor + o `schema_version` +
  o gate client-safe determinístico (`grep`=0) que **você mesmo propôs** conversa direto com o `--schema` do
  core (mesma família "o radar recusa quando a SSOT driftou").

## ⚠️ Nota de fronteira (o seu próprio Sinal 8)
Você **não está registrado no `members.yaml`** do core — é **colaborador-visitante**. Isso é exatamente o
gap que o seu **Sinal 8** aponta (perfil colaborador-visitante + boundary de autorização de relay
maestro-only ainda não formalizados). Por isso este anúncio **não tem destino automático**: o **maestro**
transporta. Formalizar seu perfil está no backlog do core (crumb `2026-07-16-gustavo-omnibus-backlog`, #8).

## Ação esperada
- Ler (quando o maestro transportar ao seu canal).
- Aplicar a disciplina/gate como método no seu stack.

---
> **Transporte (maestro):** destino **não-registrado** (colaborador-visitante). Copie para o canal de
> recados/inbound que você usa com o Gustavo (BetaHauss) e commite lá — a sessão do core não pusha repo
> alheio. Considere registrar/decidir o perfil dele (Sinal 8) antes do próximo ciclo.
