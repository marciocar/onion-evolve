---
branch: fix/adopt-writes-guard-core-line
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 3ce1a37c71a44b1b128e9470cca5083d9fd8b3479eec99b374b4eedb7d4d8874
reviewed_code_sha256: bac019eeb9ce45d9e9c8bd805ea08bf230ce82222d9546efe2ea4340408b5de0
findings_total: 3
findings_real: 2
findings_blocking: 2
tokens: 0
duration_min: 15
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: autor (passada adversarial própria, sem subagente por instrução da sessão principal)
nota: "tokens não medidos (0): a passada foi do próprio agente de execução, dentro do mesmo contexto."
---

# Passada adversarial: `fix/adopt-writes-guard-core-line`

## O que muda

O `/meta:adopt` (adoção e `--update`) passa a escrever a linha `core` do `.claude/adopter-guard.tsv` do
adotante, pelo `.claude/utils/adopt/adopter-guard-core.sh` chamado no passo (0.6) do Procedimento de
Configuração pós-cópia. Até aqui nenhum helper escrevia o arquivo (`git grep adopter-guard.tsv` em
`.claude/utils/adopt` e no `adopt.md`: zero), e o hook do adotante veta a sessão que o escreve. Os adotantes por
URL (kg-ssot e curadoria) ficavam com a REGRA 118 (Veto de repo alheio do adotante registrado e com lista)
armada e sem lista. A seção «Gate do alvo» do relatório passa a pedir a linha que o helper imprime. Bancada nova:
`adopter_guard_core`, 9 casos.

## Achados

1. **REAL, curado.** Uma linha `core` RELATIVA que, a partir do cwd de quem roda o update, parecesse um core
   (diretório com `docs/evolution/federation/members.yaml` e sem carimbo) era tratada como «escolha do maestro»
   e mantida. A lib do hook só aceita caminho absoluto, então o veto continuaria sem lista e o relatório diria
   «mantida». Cura: `_is_core` exige caminho absoluto. Caso (d2) na bancada.
2. **REAL, curado.** `git rev-parse --path-format=absolute` exige git ≥ 2.31; num git mais velho o helper
   pulava calado de lista («pulada»), e o adotante seguiria desarmado. Cura: resolve o `--git-common-dir`
   relativo a partir da fonte com `cd` + `pwd -P`, que vale em qualquer git com worktree.
3. **Não real.** Suspeita de conflito no merge da `onion/vendor`: o arquivo não está na árvore do core, então
   não viaja pela vendor e não conflita; chega ao adotante pelo commit durável, que staja `.claude` inteiro
   (conferido: `git check-ignore` não o ignora no kg-ssot nem na curadoria).

## Mutantes

- (g) na bancada: a leitura da linha `core` existente trocada por `{ next }` → a 2ª rodada duplica a linha, e a
  família acusa. Morto.
- Manual: tirar o `case "$1" in /*)` do `_is_core` → o caso (d2) reprova («manteve o relativo»). Morto, e o
  arquivo foi restaurado (diff conferido).

## Limites declarados

- O caminho escrito é o ABSOLUTO do checkout do core, que inclui a home do usuário. A forma `~/…` seria portátil
  entre máquinas, mas se outro usuário rodar a sessão do adotante na mesma máquina o `~` dele aponta outro lugar e
  o veto ficaria sem lista. Escolhi o absoluto.
- `ops/materialize-adopter.sh` (core-only) não chama o helper: a fixture da família `adopter_shape` segue sem a
  linha, como antes.
- O helper não arma o veto sozinho: o `role:` do carimbo e o registro do hook no `settings.json` seguem de quem os
  escreve.
- Caminho do core com espaço: pula, dizendo (a lib não o lê).
