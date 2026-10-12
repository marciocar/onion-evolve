---
branch: fix/gate-verdict-absolute-hookspath
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 40
verdict: REPROVADO_E_CURADO
reviewer: passada própria + mutantes executados (sem subagente) — gate mecânico: família adopter_gate
---

# O veredito do gate dava PARCIAL a um gate vivo numa worktree irmã

## Defeito medido

Nos dois `--update` do onion-kg-ssot em 2026-10-12, o `verify-adopter-gate.sh` deu **✗ PARCIAL** na
worktree irmã. O hook tinha executado e barrado o commit-sonda. A causa foi ancorada por medição, no
adotante e depois no core: o **Claude Code 2.1.296 regrava `core.hooksPath` em forma absoluta** no
`.git/config` compartilhado quando **cria** uma worktree de agente (`isolation: worktree`). Numa worktree
irmã, o git passa então a rodar o hook do checkout principal. A guarda olhava só o diretório (`-ef`), não
o conteúdo.

## Achados

1. **Falso PARCIAL.** O hook do checkout principal era byte-idêntico ao da worktree e mesmo assim
   reprovava. Curado: hook absoluto **byte-idêntico** vira aviso ⚠, com a causa e o conserto, e não
   reprova. Hook **diferente** continua reprovando.
2. **Da passada: o (b) deixou de ser load-bearing.** Com a cura, o mutante (b-MUT), que volta a comparar
   por string, só avisava no mesmo diretório e o caso passava. Curado: o (b) agora exige silêncio total no
   mesmo diretório, sem acusação e sem aviso.

## Prova

- Família adopter_gate **10/0**. Casos novos (f), (f-MUT) e (f2), e o (b) endurecido.
- Com o `verify-adopter-gate.sh` de `origin/main`, o (f) reprova.
- Evidência no grafo da r9: `E_WORKTREE_DE_AGENTE_REGRAVA_HOOKSPATH_ABSOLUTO`. O valor era `.githooks` e
  passou a `<raiz>/.githooks`, com mtime de 15:29:37Z para 15:29:40Z. Radar e kg-contract-check rc 0.

## O que NÃO cobre

- Não impede o Claude Code de regravar. A forma absoluta não quebra nada no core, e cada worktree irmã
  passa a rodar o hook da principal. Isso fica declarado no aviso.
- Não volta o valor para relativo sozinho: mudar a config local é do dono do repo.
