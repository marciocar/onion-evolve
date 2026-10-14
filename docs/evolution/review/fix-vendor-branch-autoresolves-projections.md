---
branch: fix/vendor-branch-autoresolves-projections
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 2
findings_fixed: 2
tokens: 60000
duration_min: 25
verdict: CORRIGIDO
elenxo: sim
reviewer: passada adversarial do próprio autor (SAC-139), com mutantes executados
nota: o vendor-branch resolve sozinho o conflito que só toca projeção gerada; 3 mutantes reprovam a bancada
---

# Passada adversarial: `fix/vendor-branch-autoresolves-projections` (SAC-139)

## O que muda

Quando o merge da `onion/vendor` conflita e **todo** arquivo em conflito está na lista do
`regen-ssot-projections.sh --list-outputs` (comparação por linha inteira, `grep -vxF -f`), o
`vendor-branch.sh` faz `checkout --theirs`, regenera as projeções no alvo, stageia, conclui o merge e
sai com rc 0, **declarando** quantos e quais conflitos resolveu. Se um arquivo estiver fora da lista,
ou se o gerador faltar ou falhar, devolve rc 10 com a mensagem de hoje, e os marcadores voltam
(`checkout -m`).

## Achados (medidos)

1. **REAL, curado.** Na 1ª redação, o mutante que tira só a trava da lista (`[ -z "${outside}" ] || return 1`)
   **não mudava o desfecho** (rc 10): o stage só cobria as saídas do gerador, então o arquivo de
   framework seguia `U` e a checagem pós-stage recusava. A defesa em profundidade escondia que a trava 1
   não estava sendo provada por ninguém. A cura foi stagear explicitamente os arquivos em conflito (a
   trava 1 passa a ser a única que protege a customização, e isso fica dito no código). Com a cura, o
   mutante (b) dá rc 0 e reprova a bancada.
2. **REAL, curado.** Gerador que falha **depois** do `checkout --theirs` deixaria o alvo com a versão
   deles, sem marcadores, e rc 10: o maestro veria "conflito" num arquivo que já não tem conflito
   visível. A cura é o `checkout -m` (os marcadores voltam). O mutante que o remove reprova (g3c).
3. **Limite declarado, não curado.** Se o commit do merge for recusado por hook do alvo, o índice já
   está resolvido e o rc é 10 com aviso ("conclua com `git commit`"). A lista de "Arquivos:" da
   mensagem de conflito nomeia arquivos que já não estão `U`. Não uso `--no-verify` no alvo: pular a
   guarda do adotante em silêncio seria pior.

Também conferido: nome acentuado (`core.quotePath=false` + `--literal-pathspecs`), modify/delete (o
`--theirs` recusa → marcadores de volta → rc 10), o conflito lido por here-string (sem `| grep -q`,
a classe da `shell_pipefail_robustness`), e a assinatura do adotante continua como último parágrafo
do commit do merge (a nota da resolução entra antes dela).

## Bancada (família `vendor_branch`, 18/18)

- (g3a) conflito só em projeção → rc 0, nenhum `U`, sem `MERGE_HEAD`, commit com 2 pais, projeção = saída do gerador, resolução declarada.
- (g3b) projeção + `.claude/commands/foo.md` customizado → rc 10, os dois seguem `U`, marcadores na projeção.
- (g3c) sem gerador no alvo → rc 10, marcadores de volta.
- (g3-MUT a/b) mutantes dentro da bancada (motor copiado com `_adopt_sibs_beside`, que já inclui o `regen-ssot-projections.sh` desde o #1117).

## Mutantes por `ops/mutate-and-restore.sh` (arquivo real, restaurado por hash)

| Mutante (`ONION_MUTANTE`) | Reprovou |
|---|---|
| sem a cura (chamada do `_autoresolve_projections` vira no-op) | (g3a) rc=10 |
| resolve mesmo com arquivo fora da lista | (g3b) rc=0 |
| sem restaurar os marcadores quando o gerador falha | (g3c) |

Famílias: `vendor_branch`, `shell_pipefail_robustness`, `role_cut`, `vendor_baseline_removido`,
`vendor_core_removed`, `vendor_manifest`, `vendor_pin`: 89 passaram, 0 falharam. Lint: 0 HARD (a
REGRA 80 (Números do harness saem de SSOT gerada, nunca de comentário) acusou o
`testing-inventory.md`, que foi regenerado).
