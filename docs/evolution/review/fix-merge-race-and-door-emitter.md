---
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
tokens: 83679
duration_min: 5
verdict: APROVADO
elenxo: sim
nota: >
  Passada adversarial (branch-code-reviewer, veredito default reprovado) devolveu 0 bloqueador,
  1 importante e 4 menores. Importante e dois menores curados no mesmo laço, cada cura com mutante
  que morre; dois menores aceitos e declarados.
---

# Resíduo — `fix/merge-race-and-door-emitter`

Duas curas: SAC-85 (o auto-rebase do `ops/pr-merge-verified.sh` comparava o head do PR antes de o
GitHub refletir o push, medido no #985 em 2026-10-09) e o emissor do `door-staleness-check.sh`, que
falhava sem `members.yaml` no `/meta:adopt --update` de um adotante (2026-10-11).

Famílias rodadas com `LC_ALL=C`: `pr_merge_verified` 40/40, `door_cycle` 13/13. O revisor reverteu
o script inteiro para o de origin/main: (w3)-(w6) reprovam, e (w)/(x)/(y)/(z) continuam verdes
(o `--allow-empty` do dublê não mudou o resultado dos casos antigos).

| # | sev. | achado | desfecho |
|---|---|---|---|
| 1 | IMPORTANTE | o (w6) procurava "o GitHub não refletiu o push", frase que também aparece no ramo "ref ilegível"; com esse ramo trocado, o caso seguia verde | curado: o oráculo é a frase exclusiva "a branch remota já está em" + ausência de "não foi legível"; o mutante (ramo trocado por `false`) agora reprova o (w6) |
| 2 | MENOR | a frase "nenhuma porta com pin", na emissão, ficou sem caso | curado: door-cycle (m), com registro e sem porta; o mutante que imprime a frase crua reprova o (m) |
| 3 | MENOR | o comentário dizia que o baseline do core viajava; no adotante medido era o stub do `--ensure-from` (o `vendor-branch.sh` já tira o do core) | curado: o comentário diz o que foi medido e quando o caso do core se aplica |
| 4 | MENOR | PR de fork, com `origin` sem a branch: antes morria na 1ª leitura; agora espera o teto (24×5 s) e só então morre | aceito e declarado: é latência, não buraco; continua sem mergear |
| 5 | MENOR | `git ls-remote` sem teto de tempo | aceito e declarado: o push acabou de passar pelo mesmo remoto com as mesmas credenciais |

Mutantes (`ops/mutate-and-restore.sh`): teto fixo em 1 leitura → (w3)(w4) · sem a parada pelo ref
remoto → (w5) · diagnóstico do teto trocado → (w6) · sem o ramo da emissão sem registro → (j)(l),
o (l) com a mesma mensagem do campo · frase crua na emissão → (m).
