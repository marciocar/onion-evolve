---
reviewed_diff_sha256: a708e92628d00f045e5337e59f6b31809e18f30d4f6d796ba3e48414df78e486
findings_total: 5
findings_real: 5
tokens: 135290
duration_min: 12
verdict: APROVADO
elenxo: sim
nota: >
  Elenxo opus em worktree isolada, mandato de refutar. APROVADO sem blocker; 2 recommended e 3
  opportunistic, todos curados neste mesmo PR antes do merge. A premissa central (o hook de carga é
  cego para skills) foi atacada no binário 2.1.289 e se sustentou.
---

# Resíduo — `fix/evolve-round-blockers`

As curas S da rodada do `/meta:evolve` de 2026-10-04 (os blockers 1, 2 e 3 da rodada e a premissa
falsa do D9). O refutador extraiu do binário as três funções que o harness usa para achar diretivas
e as rodou em node sobre os arquivos: **6 diretivas vivas antes, 0 depois**.

## O que o refutador tentou derrubar e não conseguiu

- **"O hook é cego para skills"** — o schema do evento só admite os quatro tipos de memória e os
  cinco `load_reason`; os dois pontos que disparam o hook filtram por esses tipos. O único caminho
  teórico (skill puxada por `@include`) foi testado em fixture: sai contada certo, não `NAO-MEDIVEL`.
- **Shell sob `set -e`** — o `evolve-census.sh` não usa `-e`; `grep -c . || true` com lista vazia
  devolve `0`, não vazio.
- **Mutantes** — os quatro (skill volta a `NUNCA`; tudo vira `NAO-MEDIVEL`; `_note` removido;
  `NAO-MEDIVEL` entra nos alvos) reprovam um caso cada. Nenhum caso decorativo.

## Os achados, e o que foi feito com cada um

1. **recommended — a mesma premissa falsa vivia no `context-freshness.md`**, o comando para onde o D9
   delega ("no framework os contextos são templates; vazio não é erro"). **Curado**: a dispensa
   passa a valer para repo recém-instalado, e o core é dito auditável, com a medição.
2. **recommended — a forma DESCRITA podia ser lida como a forma errada** ("o caractere ! colado ao
   comando entre crases" admite `!` dentro das crases), e o template ficou sem dizer que falta a
   diretiva. **Curado**: o texto diz a ORDEM e aponta a forma literal em
   `docs/knowledge-base/tools/agent-skills.md:170`; o template diz que o resumo fica sem dados sem ela.
3. **opportunistic — o harness NÃO injeta em corpo de agente** (medido: as 7 ocorrências da função
   executora estão no carregador de commands e skills). **Registrado** no nó do grafo: a cura no
   agente é preventiva.
4. **opportunistic — `I_BLIND` sem filtro de existência, e `[ ] && _note` como última linha do
   `if`.** **Curado**: mesmo filtro do `I_NEVER_LIST` e `if … then … fi`.
5. **opportunistic — o D9 citava só business e technical**; `design-context` também está populado
   (7). **Curado** no `evolve.md`. (O `instructions-loaded-census` só olhar `.claude/rules/*.md` sem
   subpastas é anterior a esta leva e fica anotado aqui, sem cura.)

## O que não foi verificado

O `/meta:create-skill` não foi invocado ao vivo; a prova é a simulação com as funções do binário.
