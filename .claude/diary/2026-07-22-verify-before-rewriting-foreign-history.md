---
date: 2026-07-22
instance: onion-evolve
type: reflection
classification: collective
tags: [verification, git, federation, foreign-repo, near-miss, declared-vs-verified]
affects: [meta, engineering, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "Antes de QUALQUER operação destrutiva sobre histórico de terceiro (rebase, filter, force-push, 'limpar' branch), a diagnose tem de ser verificada contra o estado real — não contra a aparência. Para 'vendor poluído com produto': medir `git rev-list --count <integração>..onion/vendor` (commits próprios do vendor) e `<vendor>..<integração>`. Zero commits próprios = ancestralidade compartilhada por design, NÃO pollution. Só agir se a medição confirmar a hipótese. A régua sobe com o custo do erro: destrutivo + repo alheio + irreversível = verificação obrigatória, sem exceção de pressa."
review_after: 2026-10-20
conflict_class: static
significance: "A disciplina de verificar-antes-de-agir, no seu teste de maior aposta do dia: impediu reescrever 640 commits do repo de outra pessoa para consertar um problema que não existia."
---

## Signal
**A verificação-antes-de-agir teve seu maior teste no dia mais destrutivo possível — e passou.** O core
diagnosticou "o vendor do metagamify está poluído com histórico de produto" e cogitou limpá-lo. Errado. A
medição, feita ANTES de tocar em qualquer coisa, refutou o diagnóstico. Sem ela, eu teria reescrito 640
commits do repo de um terceiro para consertar um problema inexistente.

## Evidence
- **O diagnóstico veio da aparência:** `git log onion/vendor` mostrava 640 commits, quase todos de produto
  (`wrr`, PRs #73-77). Salto imediato: "poluído". **É exatamente o erro que a sessão inteira combateu** —
  caracterizar pelo que se vê na superfície, não pelo que se verifica.
- **A medição refutou:** `chore/onion-framework..onion/vendor` = **0 commits** (o vendor não tem NENHUM
  commit próprio); `onion/vendor..chore/onion-framework` = **3 commits** (o vendor é ANCESTRAL da integração,
  3 atrás). Os commits de produto são **ancestralidade compartilhada por design** — o `onion/vendor` é
  ramificado da integração (o próprio cabeçalho do `vendor-branch.sh` diz isso), e produto é snapshot
  intocado. Não é pollution; é o esperado.
- **O custo do erro evitado era assimétrico e irreversível:** reescrever histórico num repo alheio viola o
  I3 (um escritor por repo), destrói referências de outros, e não tem 'ctrl-z'. O ganho pretendido era
  cosmético (uma mensagem de commit com data no lugar do hash).
- **Quem pediu a verificação foi o maestro** ("verifique antes"), não eu — e essa é a parte que fica: meu
  impulso ainda era agir. A régua "custo do erro alto → verificar é obrigatório" precisa ser minha, não
  esperar o freio de fora.

## Next crumb
Ver `next_recommended`. Regra: **operação destrutiva em repo alheio exige medição que confirme a hipótese,
nunca a aparência que a sugeriu.** Da mesma família de [[worst-truth-is-uncertain]] (a pior verdade é a que
não temos certeza) e [[read-full-content-before-triage]] (não caracterizar pelo título) — aqui a
"característica pelo título" era o `git log`, e o custo de errar era máximo.
