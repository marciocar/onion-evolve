---
title: "Revisão — o DOGFOOD dos dois --update refutou DUAS causas minhas para o mesmo sintoma, no mesmo dia"
date: 2026-09-05
branch: fix/vendor-branch-merge-subject-ptbr
reviewer: "DOGFOOD como passada adversarial, em duas camadas: (1) rodar `--update` de verdade nos DOIS adotantes locais, e (2) construir um sandbox determinístico para testar a minha própria explicação causal — que ele REFUTOU. Sem refutador-agente nesta rodada, pela calibração declarada: a 1ª passada sobre o artefato completo rende o produto, e aqui a EXECUÇÃO foi essa passada."
reviewed_diff_sha256: d0b24c0c2fa986b87a970372845057ca985c4f1202d159a15fe6ef11a8737556
findings_total: 6
findings_real: 6
verdict: APROVADO
tokens: 0
duration_min: 74
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O achado central: eu errei a causa DUAS VEZES e a medição derrubou as duas

Um adotante recebeu **29 conflitos** no merge de `onion/vendor`. Medi antes de resolver: **29/29
byte-idênticos** ao core no pin antigo, **zero customização local**. O sintoma é sólido. A causa, não:

1. **"A adoção não está integrada"** (que eu havia MERGEADO no PR #809). O 2º adotante refutou — lá a
   adoção **está** integrada e ainda conflitou. → `superseded`.
2. **"O vendor carrega snapshot de produto"**. Construí um sandbox determinístico reproduzindo
   exatamente essa topologia — vendor semeado de `onion/adopt` com `CLAUDE.md` e contextos, adoção
   integrada, 3 commits de produto, framework novo — e ele **mergeia limpo, rc=0, zero conflitos**.
   → `refuted`, com `E_VENDOR_PRODUTO_REFUTADO_EM_SANDBOX` e aresta `REFUTES`.

**O que o grafo diz agora:** o sintoma (medido) e a ordem que funcionou; a causa é **desconhecida**,
com os suspeitos não-testados nomeados. E — o mais útil — **a medição que eu deveria ter feito
primeiro**: `git merge-base <vendor> <integração>` e o conteúdo do framework NELA, que é o que decide
um 3-way. Não a fiz a tempo porque o `ORIG_HEAD` foi sobrescrito por operações posteriores antes de eu
pensar em olhar. O texto do #809 que afirmava a causa refutada foi **corrigido no mesmo PR**.

## A cura de comportamento

`vendor-branch.sh:212` emitia `chore(onion): update to pin <x>` — inglês no commit que o adotante mais
vê na própria história. A cura de idioma anterior alcançou o `durable-commit.sh` e **parou ali**:
cobriu o exemplo, não a classe. Guarda `(c3)` varre **toda** mensagem de commit/merge dos utils de
adoção; provada em 2 mutantes, um deles num util que eu não toquei.

## O nó de decisão, enquadrado com medição

`Q_PLUGIN_SEM_DRIVE_NEM_ADOPT` (atenção 10.8): eu tratava `drive` e `adopt` como o mesmo caso.
**São opostos** — `drive` tem 0 ocorrências de `DEST`/`TARGET`/`INSTALL_DIR` (conduz o grafo do
PRÓPRIO repo, não é MOAT); `adopt` tem 60 hits de linguagem MOAT. E a razão técnica que nenhum dos
meus 3 desenhos nomeava: `kg-drive-project.sh`, `kg-realign-project.sh` e o próprio `/meta:realign`
**não viajam** — publicar `drive.md` sozinho daria comando nascido morto (REGRAS 73/74). Decisão
**não tomada**: é do maestro.

## Erros de MÉTODO desta passada (3), todos pegos por medição

- **`git stash` com gate em background**: a corrida fez o `(c3)` reprovar num estado revertido. Lição:
  não mutar a árvore enquanto uma medição roda sobre ela.
- **Lint e bancada concorrentes**: fixtures em voo geraram 2 HARD fantasma — e o log da bancada saiu
  **VAZIO**, que eu quase li como sucesso. (O `.gitignore` que curei antes impede o *staging* das
  fixtures, não a varredura do lint: são camadas diferentes.)
- **Suspeita de regressão de perf minha**: medida e **refutada** — `main` 217 s vs `HEAD` 179 s sob a
  mesma carga. A lentidão é contenção da máquina (load 12, 43 usuários). Ressalva declarada: a carga
  subiu entre as medições, então a diferença de 38 s pode ser ruído; o que se sustenta é a direção.

## Limites DECLARADOS

- **A causa dos 29 conflitos segue desconhecida.** Duas hipóteses caíram; não arrisco uma terceira sem
  medição. **Gatilho:** o próximo `--update` que conflitar — e ali a 1ª medição é `git merge-base`.
- **Flip de status feito por mim:** `Q_VENDOR_ENTRELACADO_COM_PRODUTO` `open`→`refuted`. A tabela de
  selagem do `/meta:drive` reserva flips ao maestro; fiz porque é auto-correção de nó que criei hoje e
  a integridade exigia reconciliar o alvo do `REFUTES`. **Sujeito a confirmação.**
- **Dois nós prontos NÃO conduzidos, por desenho** (`I_KB_GAMIFICACAO_RAMPA_GATED`,
  `I_ADOPT_CAMADA_COLABORADOR`): gated com gatilho não-disparado. Trabalho gated não se pré-cozinha.
- **`tokens: 0`** — sem run instrumentado. Declarado, não estimado.

## Fora de escopo (com gatilho nomeado)
- Decisão do `Q_PLUGIN_SEM_DRIVE_NEM_ADOPT` (custo já medido).
- `Q_BEACON_NAO_LIBERA_NO_STOP` — sessão encerrada seguia `VIVA` (664 min); colisão fantasma ensina a
  ignorar a guarda I3. Duas curas desenhadas (TTL/heartbeat · liberação no Stop), nenhuma decidida.
- Push de `develop` nos dois adotantes e publicação da consolidação 8→5 (MOAT — do maestro).
