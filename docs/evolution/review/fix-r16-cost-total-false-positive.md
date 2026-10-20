---
branch: fix/r16-cost-total-false-positive
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: f762a404f810e5cc5a80e4a3af8d542a5154780fe89b63a09bf9e6bedf80f279
reviewed_code_sha256: 95c7591145a43a0461cbf1dd0e606fd9f01b73bc7b8c89a02f664be66047b6c1
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: a sessão executora; ataques por 2 mutantes executados e pelo lint do core inteiro
nota: "tokens e duration_min em 0 = não medidos."
---

# Passada adversarial: `fix/r16-cost-total-false-positive`

## O que muda

A REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT) acusava, na main, a linha
`| **Total** | | **8.749.759** | **122** | **43 min** |` da síntese
`docs/evolution/research/chat-agent-isolation-2026-10/SYNTHESIS.md` (l.166). A tabela é de custo.

A causa é o feeder (c), o da linha 'Total' de tabela. Ele extraía o 1º inteiro da linha com
`grep -oE '[0-9]+'`, sem olhar de que coluna o valor vinha. O separador de milhar cortava
`8.749.759` em `8`, que não bate com nenhuma contagem da SSOT.

A cura é de vocabulário, sem isentar arquivo nem nome:

1. 'Total' só é inventário quando a população vem nomeada: no cabeçalho da coluna do 1º valor
   (`| Categoria | Comandos |`) ou na própria célula (`**117 comandos**`). As populações são
   comandos, agentes, skills, knowledge bases e KBs.
2. O número é lido como token inteiro, com o separador de milhar: `8.749.759` vira 8749759, nunca 8.

A comparação contra o conjunto dos totais e o 'Total' case-sensitive não mudam.

## Achados

1. **O mutation test provava só metade da cura.** Na 1ª forma, o caso (a-MUT) aceitava qualquer
   acusação do mutante "régua antiga". Esse mutante desfaz duas linhas. Se o `sed` do milhar
   virasse no-op, o `cmp` ainda diferiria pela outra linha, e o caso passaria sem provar o `8`.
   Corrigido: o mutante tem de acusar exatamente `'8'`. A metade do milhar também tem um mutante
   próprio, o (c-MUT).

2. **Veredito por `produtor | grep -q` no caso novo.** O pré-voo do `pr-finalize` reprovou a
   família `shell_pipefail_robustness`. O motivo: dois sítios do caso fechavam o pipe cedo, e sob
   pipefail o EPIPE vira falso ✗. Corrigido com here-string. As duas famílias ficaram verdes.

## Mutantes (executados no sandbox da bancada)

- **Régua antiga** (`if (1)` no lugar da exigência de população, mais `/[0-9]+/` no lugar do
  token com milhar): a tabela de custo volta a ser acusada como `'8'`. O caso (a) reprova.
- **Só o milhar** (`/[0-9]+/`): `51.000` sob a coluna 'Agentes' vira `51`, que é o total de
  agentes, e a regra cala. O caso (c) reprova.

## Conferência nos sítios reais

- `docs/technical-context/02-ai-context/codebase-guide.md`, com cabeçalhos 'Comandos' e 'Agentes':
  com 117 → 118 trocado à mão, a regra ainda acusa `'118'`. Revertido depois.
- O lint completo dá 0 HARD, e a acusação da SYNTHESIS sumiu.

## Limites declarados

- Uma tabela de custo cuja 1ª coluna numérica seja 'Agentes', no sentido de frota de run, ainda
  seria lida como inventário. Era assim antes. O vocabulário da população não distingue o agente
  do inventário do agente de um run.
- O cabeçalho é a linha logo antes da separadora `|---|`. Pipe escapado (`\|`) numa célula
  desalinha as colunas.
