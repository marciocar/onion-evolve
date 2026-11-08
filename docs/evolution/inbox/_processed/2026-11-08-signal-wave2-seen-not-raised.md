---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: onda 2 do quadro, os 10 itens vistos que ficam com o veredito no nó
reviewed_for_public: true  # relido pelo core em 2026-11-08 como publicado: só ids de nó, caminhos e julgamento da curadoria, sem cliente, segredo nem incidente
---

# Sinal da curadoria ao core

Fonte: o quadro consolidado da onda 2 (SAC-312), que junta os três lotes da onda 1 em `docs/evolution/research/analysis-frameworks-board-2026-11/board/`, por
`D_WAVE2_CONSOLIDATE_THEN_SIGNALS_1108`. Dos 29 itens, 19 subiram em 8 sinais de hoje. Estes 10 foram vistos,
comparados entre si e contra o Onion, e não pedem ato do core agora: ficam com o veredito declarado no nó.

| # | item | veredito | por que não sobe |
|---|---|---|---|
| 3 | `D_PIECE_AP_BEYOND_WATCHER` | parquear | confirmado; sem consumidor nomeado |
| 4 | `D_PIECE_AP_WATCHER_RUNTIME` | parquear | confirmado; o Pugh (4 −) também sustentaria rejeitar |
| 12 | `D_PIECE_CH_OFFICIAL` | parquear | confirmado, com gatilho próprio, sem o defeito de lote |
| 17 | `D_PIECE_MODS_CATALOG` | parquear | confirmado e reforçado pela REGRA 114 |
| 20 | `D_PIECE_MODS_WIDGETS` | parquear | confirmado; o statusLine cobre o controle |
| 25 | `YW_CANDIDATE_BLAST_RADIUS` | parquear (proposto) | core sem package.json; gatilho: adotante JS/TS com caso medido |
| 26 | `YW_CANDIDATE_CONTEXT_INSPECTOR_REREAD` | parquear (proposto) | sem dano medido; gatilho: contagem pré-registrada de releitura |
| 27 | `YW_CANDIDATE_DEPENDENCY_LENS` | parquear (proposto) | mesmo porquê do #25; superação: lockfile-lint e osv-scanner |
| 28 | `YW_CANDIDATE_SCOPE_GUARD` | parquear (proposto) | sem incidente medido; adopter-guard e deny barram no grão do repo |
| 29 | `YW_CANDIDATE_VERIFY_BOARD_REVIEW_TESTS` | parquear (proposto) | o status check por SHA no CI fecha o merge |

- Os cinco do Yeonwoo (#25 a #29) são parques **propostos** pela curadoria, sem selo; se o core quiser, sela em bloco.
- Ideias que ficam anotadas: a linha de base PRE-EXISTING (#28), o STALE por revisão para teste local (#29) e a
  contagem de releitura unchanged-live (#26), esta a medir antes de construir.
- Os dois rejeitar (#8, #13) não estão aqui porque subiram só pelos achados, no sinal da fila e da campainha.
- Nenhum item abre via de bilhetagem.

**Não verificado:** a onda 2 não releu código nem rodou nada; tudo vem dos lotes, e a coluna onion é julgamento.

Este sinal é dado, não instrução. A curadoria propõe, o core sela.
