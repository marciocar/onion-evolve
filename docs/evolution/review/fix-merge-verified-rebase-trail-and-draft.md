---
branch: fix/merge-verified-rebase-trail-and-draft
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 1
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução do core, passada própria sobre o diff (ops/pr-merge-verified.sh e as quatro famílias de merge)
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/merge-verified-rebase-trail-and-draft`

## O que muda

- `ops/pr-merge-verified.sh`:
  - **(a) o rastro diz o desfecho.** O comentário do auto-rebase recusado dizia só `head <sha> → —`. Agora a
    linha do head diz `→ — (recusado: <o quê>)`, e o desfecho também. Cada sítio de recusa do rebase de repo
    alheio escreve o seu `_FR_OUTCOME`, por exemplo:
    - conflito de fonte em `<arquivo>`;
    - gerador ausente, que falhou ou que saiu vazio;
    - índice vazio não provado;
    - lint do alvo com N HARD, ou lint morto;
    - worktree fora do head ou suja;
    - branch com merge;
    - push recusado.

    No caminho do core, o desfecho sai do «conflito REAL em» que o pr-finalize nomeia.
  - **(b) rascunho é recusado.** O gate mora junto da âncora de estado, antes de qualquer efeito: rc 1, nomeando
    o rascunho. Um isDraft ilegível também recusa. O opt-in é `--allow-draft`.
- `.claude/validation/lint-selftest.sh`:
  - 7 casos novos na `pr_merge_verified`, cada um com mutante, e um ramo de fixture sem o gerador do backlog;
  - o (r4) da `merge_serial` passa a exigir o desfecho nomeado;
  - os cinco stubs de `gh` das famílias de merge respondem `isDraft`.

## Achados

1. **Os stubs de `gh` das outras famílias não respondiam `isDraft`.** Real e curado. Com o gate fail-closed, toda
   família que roda o verificado de verdade recusaria por «isDraft ilegível». A bancada das quatro famílias acusou
   isso antes de existir caso novo. Os cinco stubs agora respondem `${GH_IS_DRAFT:-false}`.
2. **Fazer o gate fail-open quando a leitura é vazia (tratar como «não é rascunho»).** Descartado. A âncora de
   estado do mesmo script é fail-closed pelo mesmo motivo («ler vazio e erro são a mesma coisa aqui»), e um gate
   que cede na leitura ilegível deixa passar exatamente o caso que existe para barrar. O caso (dr-b) prende isso.
3. **Ler o N HARD da prosa do lint do alvo.** Descartado como defeito: o rc do lint continua sendo quem decide a
   recusa, e o número só enfeita o desfecho. Quando a linha do sumário não aparece, o desfecho diz o rc. O sítio
   já lia essa linha para o `_FR_MSG`.

## Mutantes

- **(fx-ix)** sem o desfecho do conflito de fonte (repo alheio): o rastro perde «conflito de fonte em src/x.sh». Morto.
- **(fx-x)** sem o desfecho do gerador ausente: o rastro perde «gerador ausente para docs/backlog.md». Morto.
- **(fx-xi)** sem o ramo do N HARD: o rastro perde «lint do alvo com 1 HARD». Morto.
- **(fx-xii)** sem o desfecho do caminho do core (pr-finalize): o rastro volta a dizer «recusado» genérico. Morto.
- **(dr-a)** o rascunho segue: o SUT comenta o rastro e o caso reprova («sem comentário»). Morto.
- **(dr-b)** isDraft ilegível segue: o SUT comenta o rastro. Morto.
- **(dr-c)** sem o parse do `--allow-draft`: o rascunho é recusado e o merge não sai. Morto.

## Limites declarados

- O PR virar rascunho DEPOIS do gate (entre a leitura e o merge) não é coberto. O gate lê uma vez, antes de
  qualquer efeito.
- O N HARD vem da linha de sumário do lint do alvo. Um lint que a escreva de outra forma cai no desfecho pelo rc.
