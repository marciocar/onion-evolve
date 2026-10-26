---
branch: feat/hookspath-absolute-reminder
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
tokens: 90598
duration_min: 5
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente refutador (general-purpose, só leitura, repos descartáveis)
nota: "duração e tokens são os do refutador; a re-verificação da cura (6 mutantes externos) foi da sessão de execução"
---

# Passada adversarial: `feat/hookspath-absolute-reminder`

## O que muda

O `session-currency-check.sh` (UserPromptSubmit) ganha o lembrete do `core.hooksPath` ABSOLUTO. Com o
caminho absoluto, toda worktree roda o `.githooks/` do checkout principal, e um PR que muda o
`pre-commit` não é provado por ele mesmo. O defeito foi medido em 2026-10-26, git 2.43, e reproduzido
num repo descartável: relativo dá `HOOK-DA-BRANCH`, absoluto dá `HOOK-DA-MAIN`. É LEMBRETE e sai com
exit 0 sempre. Avisa 1× por (sessão, valor) e roda antes do censo, sem depender dele.

A família nova de bancada é a `hookspath_reminder`. O grafo da forja está em
`docs/evolution/research/guard-hookspath-absolute-2026-10/`, e a doutrina `keep-current-doctrine.md`
ganha um parágrafo.

## Achados

Mandato do refutador: falso positivo, regressão no censo, rc≠0 ou trava, e mutante sobrevivente.

1. **FP1 (média):** um absoluto para outro `.githooks`, compartilhado, avisava. O conserto trocaria
   quais hooks rodam. **Curado:** a comparação agora é por identidade (`-ef`) com o `.githooks/` da
   árvore atual ou do checkout principal. Caso (e2).
2. **FP2 (baixa):** um `.githooks` global na home da conta avisava. **Curado** pela mesma
   identidade. Caso (e3), com gitconfig global isolado.
3. **FP3 (baixa):** com `extensions.worktreeConfig`, o valor efetivo era relativo e o `--local`
   absoluto, e mesmo assim avisava. **Curado:** o lembrete lê o valor efetivo (`git config --get`).
   Caso (g).
4. **m1:** sem o teste do diretório, nada reprovava. **Curado:** caso (h), com `.githooks/` ausente.
   O teste agora é o próprio `-ef`.
5. **m2:** sem limpar a marca no relativo, o (b2) passava, porque voltava com um valor diferente.
   **Curado:** o (b2) volta ao MESMO valor do (a), e o (b3) cobre a barra final.
6. **m3:** o ramo do til estava sem caso. **Curado:** caso (f), com o til resolvendo no `.githooks`
   do repo.
7. **m4:** o `--local` estava sem caso. **Curado:** a leitura passou a ser a do valor efetivo, e o
   caso (g) a protege.

O refutador não achou regressão no censo, nem rc≠0, nem trava. Testou config corrompida, stdin
vazio, `CLAUDE_PROJECT_DIR` dentro de `.git/` e um diretório fora de git.

## Mutantes

A família tem 16 casos e todos passam com `LC_ALL=C`. HOME, gitconfig global e de sistema ficam
isolados. Re-rodei os mutantes externos sobre a cura, e cada um reprova o caso nomeado:

| mutante | reprova |
|---|---|
| sem a identidade (`-ef`) | (e) (e2) (e3) (h) (m) |
| sem limpar a marca | (b2) |
| sem o til | (f) |
| só `--local` | (g) |
| sem dedupe | (a2) |
| `exit 1` | todos os 16 |

O mutante (m) mora dentro da família: é o hook sem a linha do ramo do absoluto, e o (a) cala. Se a
âncora mudar, o caso reprova em vez de passar vazio.

## Limites declarados

- O texto do conserto escreve no `--local`. Se o absoluto vier de config por worktree, o lugar certo
  é `--worktree`, e o texto não distingue.
- Subagente não dispara UserPromptSubmit. O lembrete aparece na sessão principal, no prompt seguinte
  à regravação.
- Não conserta nada. A causa a montante, o Claude Code regravar o caminho, segue viva.
- Dogfood: a config do core estava ABSOLUTA de novo no dia em que o maestro a devolveu a relativo. Não
  provei quem a regravou; a forja não mexeu nela.
