---
branch: feat/load-lease
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: 1131a3c3913b487901f9b1ef7159fa523e8c42e8cfc93cf332d13d80bde5a2aa
reviewed_code_sha256: af62cfd7665952b0a422c29e681de4a7507d558235abcf524d1ede53cb6c8738
findings_total: 6
findings_real: 6
tokens: 0
duration_min: 0
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão do core (claude-opus-5-5), passada própria, mais a leitura do diferencial pela sessão principal; NÃO independente"
nota: "tokens e duração não medidos (0). A passada NÃO é independente: é a do autor do diff mais a leitura do diferencial pela sessão orquestradora, que não refutou por subagente. Dois achados ficam como limite declarado (riscos 1 e 3); um foi curado (risco 2)."
---

# Passada adversarial: `feat/load-lease`

## O que muda

A regra de carga da VPS deixa de ser acordo entre as sessões e vira a peça `ops/load-lease.sh` (`check`, `wait`,
`run` com a vaga única de bancada cheia por `flock`, `status`), com a régua em `ops/load-lease.conf` nos números
de hoje (15, 12, 1800 s). A peça está ligada no pre-commit antes da faixa de bancada, no `ops/pr-finalize.sh` antes
do pré-voo e no `run_all.sh` do lab, que perde o 16 próprio. A bancada se marca como já admitida
(`ONION_LOAD_LEASE_HELD=bench`). A medida PSI contra load e a proposta de régua vão para o grafo
`session-orchestration-2026-11` (`E_SO_PSI_CONTRA_LOAD_1106`, `D_SO_LIMITES_DERIVADOS_DO_LEASE_1106`, aberto para o
maestro).

## Achados

1. **Risco ao usuário: o commit pode esperar até 30 min com a máquina carregada.** LIMITE DECLARADO, não cura. É a
   regra pedida: com o load em 15 ou mais ninguém abre a faixa de bancada, e a espera é dita na hora e a cada 5 min.
   No teto o commit é bloqueado dizendo o load, em vez de rodar a bancada calado na fila (o caso das 192 famílias em
   70 min). Escape declarado: `ONION_LOAD_LEASE=off`. Só o commit que toca o domínio da bancada passa pelo lease; o
   resto do pre-commit não espera.
2. **Risco ao usuário: o rc 2 ("não mediu") bloqueia o commit.** CURADO em parte, e o restante é limite declarado. A
   1ª versão bloqueava todo commit do domínio da bancada numa plataforma sem `/proc/loadavg` (macOS, BSD), onde não há
   o que medir. Agora a fonte ausente passa direto e diz "sem fonte de carga" (caso (k) da família, com mutante). Fonte
   que existe e lê lixo, ou régua inválida no conf, segue rc 2 e bloqueia: ali a régua deveria valer e não pôde.
3. **Risco ao usuário: o fd da vaga é herdado com `ONION_SELFTEST_FULL=1` no pr-finalize.** LIMITE DECLARADO. O
   pr-finalize carrega a lib e segura a vaga no próprio shell até sair, então os filhos (git, o pré-voo) herdam o fd.
   O efeito ruim é um neto que sobreviva ao pr-finalize, como o `git gc --auto` destacado, segurar a vaga por mais uns
   segundos. Nada fica preso para sempre, porque o fd morre com o processo. No `run` direto o fd NÃO desce ao comando
   (`{LL_FD}>&-`). Cura possível, se a recorrência aparecer: segurar a vaga num processo filho dedicado.
4. A 1ª versão do caso (i) do pre-commit procurava o literal `load-lease.sh" wait`, mas o hook chama
   `"${_LEASE}" wait`. O caso reprovou o intacto e a guarda-da-guarda acusou o mutante idêntico. Curado: o caso casa a
   forma real e exige a ordem atribuição → espera → faixa.
5. O nó `E_SO_PSI_CONTRA_LOAD_1106` nasceu com dois caminhos de máquina (pressão de memória do kernel e os
   arquivos do sysstat), que a REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela classe) acusou. Curado
   pela forma ⟨descrição⟩.

## Mutantes

A família `load_lease` tem 13 casos sobre a cópia limpa, cada um provado verde no mesmo arranjo e com o mutante
reprovando, pelo `_prove_mutation`: (a) livre, (b) ocupado na borda 15.00, (c) teto estourado, (d) histerese
16→13→11, (e) vaga disputada, (f) rc do comando, (g) aninhado, (h) régua invertida, (j) PSI ligado, (k) sem fonte de
carga, e a ligação (i) no pre-commit, no pr-finalize e no lab. Rodada isolada: 26 de 26.

## Limites declarados

- A régua NÃO mudou. A troca (PSI 30 como 2º sinal, ou 12/8 derivado de nproc) é decisão do maestro em
  `D_SO_LIMITES_DERIVADOS_DO_LEASE_1106`.
- O lease só vale para quem passa pelos três chamadores. Agente que roda bancada à mão sem o lease segue no acordo
  social.
- O CI (`GITHUB_ACTIONS=true`) passa direto: um job por runner.
- A série do sysstat amostra de 10 em 10 min, então pico curto entre duas amostras não aparece na medida.

## Re-revisão depois do rebase (2026-11-06)

O `--rebase` sobre `origin/main` @ 0a5dcaf39 mudou o hash de código porque o driver de famílias juntou, lado a lado,
o bloco `plugin_write_guard`, que já estava na main, com o `load_lease`. Conferi: os dois blocos estão inteiros, a
bancada passa no `bash -n` e o pré-voo do finalize rodou `load_lease` e `shell_pipefail_robustness`, com 29 de 29
verdes. Nenhuma linha deste PR mudou no rebase.

## Achado do contrato KG-SSOT no 1º finalize (2026-11-06)

O 1º `pr-finalize` sob o lease parou na etapa 4: o contrato KG-SSOT do commit acusou `form.range.node.label` de 2160
para 2163, porque os três nós deste PR tinham label acima de 280 caracteres. Curado: as labels foram encurtadas e o
detalhe ficou na `narrative`. O `ops/kg-gate-ci.sh` local voltou a 2160 e saiu com rc 0. É o 6º achado, real e
curado, e entra na contagem do frontmatter (6 achados, 4 curados).
