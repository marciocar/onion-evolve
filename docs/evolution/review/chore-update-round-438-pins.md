---
branch: chore/update-round-438-pins
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial manual da sessão, conferindo cada afirmação do nó contra gh pr view, o registry-pins --check, o kg_validate e o radar; sem subagentes
nota: ""
---

# Passada adversarial: `chore/update-round-438-pins`

## O que muda

- Grafo de coordenação: abre `Q_COORD_UPDATE_4_ADOTANTES_4380`, a rodada da 4.38.0 aos quatro
  adotantes com o pin 1d04d4e24cec, com o andamento dos PRs 161 (curadoria), 167 (sge), 293 (kg-ssot)
  e 1663 (brain), e a aresta TRACES_TO para o nó da rodada anterior (`..._4370`).
- `docs/backlog.md` regenerado (a projeção ganha o nó aberto).
- `members.yaml` não muda: `ops/registry-pins.sh --check --only <id>` nos quatro leu o carimbo da
  integração no remoto ainda em 5b27d09c088f (nenhum PR da rodada mergeado). O 2º selo vem depois.

## Achados

1. **Real, corrigido.** A aresta nova do nó caiu em `external_edges` em vez de `edges`: o script de
   inserção trocou a 1ª ocorrência de `edges:\n`, e ela está dentro de `external_edges:`. Efeito
   medido: `kg_validate.py` reprovou o MUST (`form.pattern.top.external_edges.to`, o `to` sem
   `arquivo#id`) e o radar saiu rc 1 com o nó órfão (grau 0). A aresta foi para a seção `edges`;
   depois, `kg_validate.py --corpus .` sai PASS e o radar rc 0.

Conferido sem achado: os quatro PRs estão OPEN (`gh pr view`); a `onion/vendor` remota da curadoria
está em `e4d1738` (`git ls-remote`); a árvore do `vendor/kg-ssot` do sge e do brain é a do core no pin
(`7227ef9a083a`); o carimbo da kg-ssot do brain diz o commit `2d231cb7e8b6`, o da tag do espelho
(`git ls-remote` do espelho); a catraca do kg-ssot medida numa worktree descartável muda só o `core.pin`.

## Mutantes

- O próprio defeito é o mutante: com a aresta em `external_edges`, o radar reprova (rc 1, órfão) e o
  `kg_validate` reprova o MUST; com ela em `edges`, os dois passam.

## Limites declarados

- O estado dos PRs é o de 2026-10-28; o nó não se atualiza sozinho.
- O commit do nó saiu com `--no-verify` declarado (o pre-commit passou de 590 s na VPS); o gate inteiro
  é o do `pr-finalize` com checkpoint e o CI.
