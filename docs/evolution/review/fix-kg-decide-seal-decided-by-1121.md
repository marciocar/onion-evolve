---
branch: fix/kg-decide-seal-decided-by-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: 623cbd67dff76690ace2e990db6d13d68354bb0ae435545db7f5b38fdce6b960
reviewed_code_sha256: 4ae51fbd367a0ac6a1e9a915a5e3f46356ccf5fb962461424ad9be4be07b8d1c
findings_total: 7
findings_real: 4
findings_blocking: 0
tokens: 125455
duration_min: 12
findings_fixed: 3
verdict: APPROVED
elenxo: true
reviewer: "agente revisor isolado (general-purpose), que não escreveu o código"
nota: "tokens e duração medidos pelo harness do agente revisor (125455 tokens, 740 s)"
---

# Passada adversarial: `fix/kg-decide-seal-decided-by-1121`

## O que muda

O selador do /meta:decide (`kg-decide-seal.sh`) ganha `--decided-by maestro|core`, com padrão maestro e o
comportamento antigo intacto. Com `core`, o selo grava source «sessão do core…», method «testimony: decisão do core
dentro da autorização do maestro, <data>, com revisão do maestro pendente», e verified_against e narrative dizendo o
mesmo, tanto no nó existente quanto no `--new`. Não se mistura com `--other` nem com `--batch` (rc 2). A bancada
ganha o caso s18, a doutrina e o comando ganham uma linha cada, e a narrative de D_PLAIN_LANGUAGE_STITCH_1121 passa a
dizer que o texto do selador foi reescrito à mão.

## Achados

1. Falso-positivo descartado: o padrão não mudou. O revisor comparou byte a byte a versão da origin/main com a nova,
   num grafo real, com e sem `--other`, `--new` e as recusas: grafo e saída idênticos.
2. LIMITE, curado: o s18 não cobria a recusa de `--batch` (o mutante que a apagava sobrevivia). O s18 agora roda o
   lote em `--preview` e julga pela mensagem própria da recusa. Com isso o mutante morre (s18 reprova com `[--batch]:rc0`), e a cópia limpa passa.
3. LIMITE, declarado no cabeçalho do selador: o radar (`kg-radar.sh:975`) só reconhece o método «decisão do maestro»
   como selo aceito em DEV, então a decisão do core fica no aviso SOFT `decision-done-em-DEV`. Quando o maestro
   concorda, o selador não tem como baixar a marca «revisão do maestro pendente», porque não re-carimba nó done. É
   fora do escopo deste PR e fica para uma peça própria.
4. Cosmético, curado: o comentário do selador citava um nó que ainda não está na main (PR #1711). Agora cita o
   D_PLAIN_LANGUAGE_STITCH_1121 pelo grafo e o outro pela descrição.
5. Real, curado pelo autor no meio da revisão e julgado certo: a âncora do mutante do s1m deixou de casar, porque a
   linha `method =` foi para dentro do `else`. O sed aceita recuo agora e casa só a linha do maestro.
6. A nova narrative do nó é verdadeira (commits 151ec983f e 760065c94) e o radar sai 0.
7. Outros caminhos conferidos, todos corretos: flag sem valor, valor torto, `--decided-by=core`, a releitura depois da
   escrita e a reexecução por grafo do lote, que cai no padrão.

## Mutantes

- s18: `if decided_by == 'core':` → `if False:`. Morre: o selo volta a dizer maestro.
- Recusa do `--batch` apagada: morre depois da cura (s18 reprova, rc 1 na família). Antes da cura, sobrevivia.
- `DECIDED_BY="core"` como padrão (revisor): morre em 10 casos.
- locator do core de volta a «pergunta com opções» (revisor): sobrevivia. O s18 agora confere o locator.
- Família `decide` limpa: rc 0, 51 casos verdes.

## Limites declarados

- O radar trata a decisão do core em DEV como aviso SOFT, e não há caminho mecânico para registrar a concordância
  do maestro (achado 3).
- D_DISCARDED_OPTION_AS_NODE_1121 vive só no PR #1711, ainda aberto: a narrative dele não é tocada aqui. O método
  escrito à mão lá («decisão do core na ausência do maestro…») difere da forma que o selador grava agora.
