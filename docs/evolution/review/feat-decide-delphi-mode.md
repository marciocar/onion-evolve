---
branch: feat/decide-delphi-mode
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_blocking: 1
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: REJECTED_AND_FIXED
elenxo: false
reviewer: o próprio construtor, numa passada adversarial sobre o diff (o brief desta execução proibiu lançar agentes; o refutador independente fica para a sessão principal antes do PR)
nota: "tokens e duration_min 0 = não medidos. Sem refutador independente: elenxo false, declarado. Os 5 achados são da passada do construtor e do dogfood"
---

# Passada adversarial: `feat/decide-delphi-mode`

## O que muda

Forja do **modo Delphi** do `/meta:decide` (`D_FORGE_DELPHI_MODE_IN_DECIDE_1111`, maestro, 2026-11-11), peças 2,
3 e 7 (o decide já tinha 5 e 6):

- **Doutrina (peça 2):** cláusula 11 da `decide-doctrine`: quando usar, as três rodadas, o anonimato da rodada
  2, o dissenso declarado como parte do selo e o que o modo não promete.
- **Estado e medidor (peça 3):** `.claude/validation/decide-delphi.sh` (`open`, `record`, `propose`, `anon`,
  `status`, `synthesis`), com o estado fora do git em `~/.local/state/onion/delphi/<id>.json` (700/600,
  escrita atômica sob flock), ordem embaralhada por sal guardado no estado e cerca R15.2 ao reexibir.
- **Superfície:** seção "Modo Delphi" no `decide.md` (versão 1.4.0); o selo segue pelo `kg-decide-seal.sh`,
  com a narrative gerada pelo `synthesis` no nó que nasce `open`.
- **Bancada (peça 7):** família nova `run_decide_delphi_selftests`, casos (d1) a (d8), sete com mutante.
- O script entra no manifesto do plugin `onion` (viaja com o decide).

## Achados

1. **Bloqueante, curado.** O `anon` de uma rodada incompleta marcava a rodada como emitida, e quem respondia
   depois lia as posições alheias antes de escrever a sua. Cura: `anon` incompleto só com `--partial`, e a
   resposta gravada depois do anon da rodada fica marcada **tardia** no `status` e na síntese. Prova: (d7).
2. **Curado.** A síntese e o dissenso do condutor saíam sem desarme na saída que também carrega cercas.
   Cura: `defang` nos dois.
3. **Curado (dogfood).** A reencenação mostrou o texto do core denunciando o autor ("o core não vira
   dependência"). O `anon` agora avisa, sem dizer qual sessão, quando uma posição cita um participante; o
   limite fica declarado na doutrina.
4. **Limite.** O `status` liga sessão a confiança, e o `anon` mostra confiança por posição: os dois juntos
   desfazem o anonimato. Declarado no cabeçalho e na doutrina: às sessões vai só o `anon`.
5. **Limite.** O nome de quem objetou é conferido por palavra inteira; "onion-core" conta como "core", e a
   conferência prova a presença do nome, não a fidelidade do dissenso.

## Mutantes

Dez mutantes plantados pelo `ops/mutate-and-restore.sh` no `decide-delphi.sh` real, cada um contra
`lint-selftest.sh --families decide_delphi` com `LC_ALL=C`: todos **morreram** (rc 1 do helper), com o caso do
defeito reprovando no SUT limpo: autor no cabeçalho do anon (d1), ordem sem o sal e ordem dos participantes
(d2), status sem o nome de quem falta (d3), synthesis sem a recusa da rodada 3 incompleta (d4), sem a recusa
da objeção sem dissenso e sem a do dissenso que não nomeia (d5), sem o desarme da cerca (d6 e d2), sem a
ordem das rodadas e sem a exigência do `--partial` (d7). A família também carrega os próprios mutantes em
cópia (11, inclusive a chave instável que muda com o estado), e roda verde: `decide,decide_delphi` 57 casos,
0 falhas, 0 pulos, com `ONION_ASK_DIR` isolado.

## Dogfood

Reencenação do Delphi do serviço Onion na VPS (curadoria, kg-ssot, core) a partir do selo
`D_VPS_SERVICE_EDGE_WITH_TWO_BLOCKING_GATES_1111`: as rodadas originais não estão no repo, então as posições
foram reescritas do label, dos nós vizinhos e da opção descartada, e o dissenso do core é reconstruído. O
modo de falha rodou: rodada 2 antes do anon (rc 2), synthesis com rodada 3 incompleta, sem dissenso e com
dissenso sem o nome (rc 2 nas três), e a síntese final rc 0. O bloco `narrative` gerado entrou num grafo de
sandbox e o `kg-decide-seal.sh` selou rc 0 com a narrative verbatim (resposta do maestro simulada no sandbox;
nenhum grafo real tocado).

## Limites declarados

- Os achados 4 e 5 acima.
- O anonimato é dos metadados; o texto pode denunciar o autor, e reescrever é da condutora.
- `--from` é declaração da condutora: o estado não prova que a resposta veio da sessão nomeada.
- Sem refutador independente nesta execução (o brief proibiu lançar agentes).
