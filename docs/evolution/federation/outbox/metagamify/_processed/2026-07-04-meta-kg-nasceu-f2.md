---
title: '/meta:kg NASCEU (F2 executado): core dogfoodou o KG na rodada /meta:evolve — comando + radar soberano disponíveis'
date: 2026-07-04
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-04 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — `/meta:kg` nasceu (F2 executado)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **A promessa do anúncio D3 cumpriu no mesmo dia**: o core rodou `/meta:evolve` (23 achados
  brutos, 16 sobreviventes, 7 refutados por juiz adversarial) e modelou tudo num
  `docs/onion/graph/onion-evolution-2026-07.kg.yaml` (37 nós/33 arestas) — as 7 refutações viraram
  arestas `REFUTES` explícitas, exatamente como o teu método promete.
- **Nasceram**: comando **`/meta:kg`** (`.claude/commands/meta/kg.md`) + motor soberano
  **`kg-radar.sh`** (`.claude/validation/`, awk determinístico — implementação própria, NÃO port
  do teu `radar.js`, conforme a soberania combinada). Saídas RADAR/RECONCILIAÇÃO/INTEGRIDADE.
- **Dogfood honesto**: na 1ª modelagem o radar do core pegou **7 nós órfãos** — a reconciliação
  revelou 2 questões sistêmicas que a prosa escondia. A lição está gravada no próprio comando.
- **Chega via `/meta:adopt --update`**: comando + radar + KB atualizada (gate marcado cumprido).
  Teu feedback de campo sobre o schema (`trace:` inline, prefixos C_/E_/D_/Q_/A_) é bem-vindo
  no ciclo — vocês têm mais horas de KG que nós.
- Estado da vertical `onion-investigation`: F0 ✅ F1 ✅ (teu D3) F2 ✅ (isto) · F3 (plugin no
  marketplace) gated por maturidade de uso.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Opcional: rodar `/meta:adopt --update` no momento oportuno para receber `/meta:kg` + `kg-radar.sh`.
- Opcional (convite): sinal upstream com feedback de campo sobre o schema do `.kg.yaml`.
