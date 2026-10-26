---
branch: feat/githooks-worktree-trampoline
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 4
tokens: 159761
duration_min: 41
findings_fixed: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente refutador (general-purpose, só leitura, repos descartáveis)
nota: "duração e tokens são os do refutador, que gastou a maior parte esperando vaga de máquina; a re-verificação da cura (5 mutantes no bloco + MUT-tramp) foi da sessão de execução"
---

# Passada adversarial: `feat/githooks-worktree-trampoline`

## O que muda

Decisão do maestro de 2026-10-26: «Trampolim no .githooks». O Claude Code grava o `core.hooksPath`
ABSOLUTO ao criar worktree de agente. Com o absoluto, toda worktree roda o hook do checkout principal, e
um PR que muda o `.githooks/pre-commit` não é provado por ele mesmo. O lembrete do #1378 avisa; este
PR cura.

Um bloco `onion-hook-trampoline` entra no topo de `.githooks/pre-commit`, `.githooks/pre-push` e do
template que viaja ao adotante (`githook-pre-commit-onion.tpl`, copiado pelo `install-onion-githook.sh`;
o marcador de autoria segue na linha 3, então o refresh dos hooks Onion antigos traz o bloco). Ele age
só quando o próprio hook mora no `.githooks/` do checkout principal deste repo. Aí, se a árvore atual
tem o mesmo hook, executável e de conteúdo diferente, `exec` nele com os mesmos argumentos e stdin.
O `prove-gate-blocks.sh` passa a espelhar o trampolim, e a doutrina `keep-current-doctrine.md` ganha a
frase.

## Achados

1. **ALTA (bancada):** o caso (g) era vazio. `r="$(_ci …)"` roda num subshell e o contador `i` nunca
   voltava, então todo commit depois do 1º era "nada a commitar", e o (g) passava com o mutante que
   engole o veredito (`"$tt" "$@"; exit 0`). **Curado:** contador em arquivo; o (g) confere rc≠0,
   HEAD parado e que quem reprovou foi o hook da worktree; o (g2) é o controle que anda.
2. **MÉDIA:** o alvo era sempre `<toplevel>/.githooks/<nome>`, onde quer que o hook estivesse. Template
   em `.git/hooks`, sidecar copiado para o husky ou hooksPath para um diretório central passavam a vez
   a um `.githooks/` que ninguém ativou (bypass do gate central por conteúdo do repo). **Curado:** a
   condição de identidade `"${0%/*}" -ef "<pai do git-common-dir>/.githooks"`. Caso (h).
3. **BAIXA:** com `show-toplevel` falhando (push de repo bare), o alvo virava `/.githooks/<nome>`.
   **Curado:** topo vazio não trampolina.
4. **BAIXA:** `ONION_HOOK_TRAMPOLINED` exportada desligava o trampolim num git aninhado da mesma árvore.
   **Curado:** a variável é limpa logo depois do bloco (ela só precisa existir entre o `exec` e o bloco
   do alvo). Caso (i).
5. **Informativo, não curado:** o hook que roda é o do disco da worktree, não o do índice. Um agente que
   edita o próprio `.githooks/pre-commit` troca o gate dos próprios commits. É o mesmo regime do
   hooksPath relativo canônico, não uma regressão.

Coerência da prova de vida: com a cura do item 2, a cópia do `prove-gate-blocks.sh` no ramo
`HSB="${SB}/hooks"` deixaria de trampolinar enquanto o git real trampolina. **Curado:** a prova troca o
`H` pelo `.githooks/` da worktree quando o git trampolinaria. Caso (o) e mutante MUT-tramp.

## Mutantes

Família `githook_trampoline`: 13 casos verdes. Mutantes aplicados nos 3 hooks e restaurados:

| mutante | reprova |
|---|---|
| chamada + `exit 0` (engole o veredito) | (g) |
| sem a identidade de diretório | (h) |
| sem limpar a guarda | (i) |
| sem o `cmp` | (c) |
| `exec` sem `"$@"` | (f) |
| bloco ausente no template | (p) |
| principal sem o trampolim (dentro da família) | (m) |
| prova sem espelhar o trampolim (MUT-tramp, dentro de `prove_gate_blocks`) | (o) |

Sobrevivem por equivalência, medidos pelo refutador: tirar o `-ef "$0"` (mesmo arquivo implica mesmo
conteúdo) e tirar o `-f` (só difere com `.githooks/<nome>` diretório, e aí o `exec` falha fechado).

## Limites declarados

- O trampolim só ajuda depois que o bloco estiver no hook do checkout PRINCIPAL. Até o merge e o pull no
  principal, as worktrees seguem rodando o hook antigo.
- Só o pre-commit viaja ao adotante (o template). O pre-push é core-only.
- Hook invocado sem barra no `$0` (pelo PATH) não trampolina.
- A causa a montante (o Claude Code regravar o absoluto) segue viva; o lembrete do #1378 continua como
  aviso de config.
