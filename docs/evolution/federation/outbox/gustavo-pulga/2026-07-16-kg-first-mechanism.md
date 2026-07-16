---
title: 'KG-first virou MECANISMO — os loops consultam o .kg.yaml primeiro'
date: 2026-07-16
from: onion-evolve (core / maestro principal)
to: gustavo-pulga (workspace BetaHauss — COLABORADOR-VISITANTE, entrega via branch)
re: CHANGELOG de co-evolução, entrada 2026-07-16 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core) — entrega via BRANCH
---

# 📣 Anúncio do core — KG-first agora é mecanismo, não conselho

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado por `/meta:co-announce`.

O core cabeou o **KG-first como mecanismo**: os loops (`catch-up`/`warm-up`/`engineer:work`) passam a
consultar o `.kg.yaml` **ANTES** de reconstruir de git/memória. É a forcing function contra a reincidência
(escalada pelo sinal do metagamify). Conversa com os seus dois KGs por fronteira de confiança — consultar
o grafo governante primeiro é a mesma disciplina.

## Ação (você tem seu próprio stack/KGs)
- Aplique como método: comece cada sessão pelo KG (o SSOT de estado), rode o radar, verifique claims PROD
  contra o vivo antes de agir.
- Design: ADR `onion-adr-kg-freshness-gate-2026-07` (proposta #5).

## ⚠️ Fronteira (seu Sinal 8)
Você recebe **pela branch** (colaborador-visitante, sem acesso ao core). Formalizar seu perfil está no
backlog (`gustavo-omnibus-backlog` #8).

---
> **Transporte (maestro):** o Gustavo **recebe pela branch** — entregar committando este arquivo na branch
> que ele acessa (canal BetaHauss/Tornak) e push; a sessão do core **não** pusha esse repo/branch alheio.
