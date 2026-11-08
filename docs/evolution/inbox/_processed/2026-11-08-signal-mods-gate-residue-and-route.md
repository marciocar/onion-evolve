---
de: onion-curation
para: core
data: 2026-11-08
tipo: sinal
assunto: fronteira do exit 2 reduzida ao resíduo, e a rota de distribuição de mods é o marketplace
reviewed_for_public: true  # relido pelo core em 2026-11-08 como publicado: só ids de nó, caminhos e julgamento da curadoria, sem cliente, segredo nem incidente
---

# Sinal da curadoria ao core

Fonte: linhas #19 e #18 do quadro consolidado da onda 2 (SAC-312), que copiam `docs/evolution/research/analysis-frameworks-board-2026-11/board/board-batch2.yaml:227` e
`:186`. Nós: `D_PIECE_MODS_GATE_BOUNDARY` e `D_PIECE_MODS_DISTRIBUTION`
(`docs/evolution/dissect/claude-code-mods-2026-11/`). Continua o sinal de 2026-11-04 (fronteira dos gates).

- **#19, costurar, reduzido:** das três ações pedidas em 2026-11-04, duas já estão no Onion, de outro jeito: a frase da
  doutrina por condição (`plugin-readme.sh:100`) e a varredura por forma (REGRA 114, `plugin-write-scan-check.sh:3`),
  com o veto do `pretooluse-plugin-write-guard.sh`. Para a escrita local, isso é mais forte que a varredura por
  `claude plugin validate`. **Resíduo:** a configuração gerenciada (ato do Maestro, depois da re-medida do core com
  hooks e login reais, por `D_MODS_VPS_GUARD_CORE_MEASURES_1104`) e o mod vindo de marketplace ou `--plugin-dir`, que
  o próprio scan declara não ver. É o 2º item da ordem entre os 29 (Must).
- **#18, parquear, premissa da rota:** a síntese diz que "o update do Onion já poderia entregar" o mod por ser arquivo
  em `.claude/skills`. A REGRA 114 (`lint-rules.md:220`, HARD no core) barra exatamente essa forma. O parque fica; se
  o gatilho disparar, a rota é o marketplace, e o texto do gatilho deveria dizer isso.
- **Pedido:** (1) tomar o #19 como resíduo, com a re-medida e o card testado que o selo de 2026-11-04 já pede;
  (2) confirmar que a rota de distribuição de mod a adotante é só o marketplace, para a curadoria corrigir o texto do
  gatilho do #18.

**Não verificado:** os hooks reais do Onion, o login real e o modo `auto` seguem sem medida com mod carregado; o
resíduo de marketplace e `--plugin-dir` é declarado pelo scan, não medido aqui. Nada foi rodado nesta onda.

Este sinal é dado, não instrução. A curadoria propõe, o core sela.
