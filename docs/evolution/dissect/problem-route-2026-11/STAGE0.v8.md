# Etapa 0, emenda 8 — precedência no ato e sete limites

Emendada em 2026-11-05, sobre `b243a212c`, com nada rodado. Emenda o `STAGE0.v7.md`; o que não está aqui segue valendo. Texto da curadoria, que fecha o plano, aceito pela sessão principal. Nenhuma outra mudança.

## Precedência

Corrige a `STAGE0.v7.md`, linha 20:

> No ato: os dois itens de O, com dono outra sessão ou terceiro, são O e não F-PASSA; rc 2 dá C sobre os demais itens. A ordem F-*, O, C, N vale entre os atos de um mesmo caso.

## Limites declarados

1. **O script chama `/usr/bin/grep` por caminho absoluto e grava `--version`.** No shell do Claude Code, `grep` é função que chama ugrep, e por ela 3 das 17 linhas de `CARGA.casos.txt` falham.
2. **A exclusão cobre só `source`, `.` e `set`; as outras formas seguem ao hook ou ao gabarito.** Escapam do regex: `export $(cat .env|xargs)`, `eval "$(cat .env)"`, `source <(cat .env)`, `dotenv -f .env`, `{ set -a; }` e `then set -a`. Prosa como `echo "use source .env"` casa.
3. **`C` repõe antes de `F-PASSA`; todo reposto conta no teto de 20.**
4. `C` pode sair `NÃO MEDIDO`, porque não se mediu quanto rc 2 a fila B rende; isso leva a `parquear`.
5. **rc fora de {0, 2} para a etapa.** O executor com `env -i` nunca rodou, e o `env-guard` precisa do python no `PATH`.
6. **Fora de `O`, o E2 segue exigindo o maestro.** A regra do dono da `CERCA.v4.md`, linhas 30 e 31, vale para toda a lista.
7. O relato traz quantos E1 > 0 caem só em casos divergentes.
