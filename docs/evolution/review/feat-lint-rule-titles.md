---
title: "Revisão — o lint imprime REGRA N (Título): o número é chave, o título é significado"
date: 2026-09-03
branch: feat/lint-rule-titles
reviewer: "condutor (mudança de 1 função + mapa; dogfood = saída real do lint com as 3 VIOLATION vivas; bancada inteira no pre-commit por failsafe)"
reviewed_diff_sha256: 8089a4911ddac61ed337361aa9d7d256d953bdca61f20d221feda31da893dbbd
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 40000
duration_min: 25
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Reforço do maestro: "não sei o que é a regra quando você diz REGRA 65". Decisão: `REGRA N (Título)`; mecanismo: `violation()`
do lint mapeia a função chamadora ao cabeçalho `# REGRA N — Título` (mesma associação do `rules-registry.sh`) e imprime o
título em toda linha VIOLATION (69 títulos, 68 funções mapeadas). Migalha `learning` registra a decisão.

## Achados

1. **Só 15 de ~65 mensagens citavam o número da regra**; as demais dependiam de quem lê saber qual `check_*` falou. O mapa
   por `FUNCNAME` cobre as duas formas (com prefixo "REGRA N" → insere o título; sem → prefixa pela função).
2. **Eu tinha a memória desta regra desde julho e reincidi hoje** — a cura foi movida da disciplina para a saída da ferramenta.
   Nenhuma doc mostra o formato antigo; fixtures do manifest casam por substring.
3. **9 casos da bancada casavam o formato antigo** (`REGRA N: …` literal e `arquivo: mensagem` adjacentes) e reprovaram o 1º gate —
   convertidos para casar `REGRA N (` + o resto da mensagem (agnósticos ao título, que é SSOT do cabeçalho). Re-rodados: 28 ✓.
