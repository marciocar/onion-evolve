---
branch: feat/r56-residue-generator
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: 3294375aad6796b9b2cf719c0d9937153393bf7a7ce92402b21c195017979670
reviewed_code_sha256: 5ecf898ddb3593614d50bb948e595949c743fdbf63a6b4e59fab66d431621529
findings_total: 4
findings_real: 4
tokens: 0
duration_min: 0
findings_fixed: 4
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: a sessão executora (SAC-142), sem revisor independente; ataques por 3 mutantes, pelo estudo prévio de um analista opus só leitura e pelo dogfood do próprio gerador neste resíduo
nota: "tokens e duration_min em 0 = não medidos (não é custo zero). Este resíduo nasceu do --skeleton, o caminho que o PR cria."
---

# Passada adversarial: `feat/r56-residue-generator`

## O que muda

Decisão do maestro de 2026-10-15 sobre a SAC-142 («A agora + D em seguida»), tomada sobre um estudo só de leitura.
O estudo derrubou o veto em Write antes de ele existir:
- o resíduo não tinha gerador, então vetar a criação à mão barraria o único caminho;
- o caso de hoje veio por heredoc no Bash;
- 41 grafos novos legítimos virariam falso positivo.

Esta é a parte A.

- O esquema do resíduo passa a morar em constantes no topo do `review-artifact-check.sh` (`VERDICT_ENUM`,
  `NUMERIC_FIELDS`, `_verdict_ok`). Os três caminhos leem as mesmas constantes: o julgamento do PR, o `--skeleton`
  (o esqueleto, com os campos a preencher) e o `--schema` (só o frontmatter, em ms).
- O `pr-finalize` ganha o passo 0a, antes do pré-voo. Sem resíduo, gera o esqueleto pelo validador e para. Fora do
  esquema, para nomeando o campo.
- O `/engineer:pr` manda executar o gerador e o `--schema`, em vez de descrever os campos.

## Achados

1. **Comentário dentro do valor.** A 1ª versão do esqueleto punha `# um de: …` na linha do `verdict`, e esse
   comentário vira parte do valor quando a sessão preenche só o começo da linha. A orientação foi para o corpo.
2. **Catraca de pipefail.** Escrevi dois `printf | grep -q` no validador, e a catraca `shell_pipefail_robustness`
   reprovou. Troquei por here-string.
3. **Mutante antigo sem efeito.** O mutante (p) da família `review_artifact` ancorava no laço do verdict que
   refatorei, e o `sed` não mutava mais nada. A âncora agora segue a forma nova.
4. **Caminho de falha que aborta.** Com o passo 0 removido pelo mutante, o caso (f) **abortava a bancada** (o
   diretório do resíduo não existia e o redirecionamento falhava sob `set -e`), e um `| grep -q` sob pipefail no
   (e) herdava o rc do validador. É a mesma classe achada no #1130: o caminho de falha de um caso só se testa com
   o mutante.

## Mutantes

- M1, sem o passo 0 → reprovam (e) e (f).
- M2, esqueleto já preenchido com 0 → reprova (a).
- M3, sem checar `reviewed_code_sha256` → reprova (c).

## Limites declarados

- `tokens: 0` e `duration_min: 0` com a nota "não medido" passam no esquema, e seguem sendo declaração. O
  esquema confere a forma, não a verdade.
- A parte D (cada adapter SDAAL declara o ponto de cobrança, com lint HARD) é o próximo PR.
- Ficam com gatilho nomeado, sem forjar: o veto em Write/Bash na criação de resíduo, o veto no `gh pr create` e o
  gatilho na leitura da prosa. Os três foram refutados pela medição.
