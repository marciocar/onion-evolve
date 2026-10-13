---
branch: refactor/evolve-workflow-rename-fanout
date: 2026-10-13
reviewed_diff_sha256: 0f7dc9f3a973deb9cfca65c6945bbbe1366c68244bc02acd253f93a6f72f1b6b
reviewed_code_sha256: 3f8af79f36b5b848e95fb44f2e6099571c23859709db32a2a3248f9f12a1d6a9
findings_total: 4
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial curta no contexto principal (refutador com dois mandatos, sondas executadas em fixture); sem subagentes — tokens 0 = nenhum subagente (o custo ficou no contexto principal, não medido à parte); duration_min estimado
---

# Passada adversarial: o workflow do evolve vira peça interna `meta-evolve-fanout`

Mandato do refutador, os dois da tarefa: (1) **referência viva ao nome antigo que sobrou** e
(2) **adotante que fica com os dois arquivos** depois do `--update`.

| # | achado | sev | destino |
|---|---|---|---|
| 1 | **O adotante ficava com OS DOIS arquivos.** Medido em fixture antes de qualquer cura: o core renomeia o workflow, o `vendor-branch.sh update` sai rc=0 "merge limpo", e o `onion/vendor` e o HEAD do alvo têm `evolve.js` E `meta-evolve-fanout.js`. O `tar -x` sobrepõe e nunca apaga, e isso vale para todo rename e toda remoção do core | blocker | **curado**: bloco `D_CURE-core-removed` no `vendor-branch.sh` (sai o que o core transportava no pin anterior e não transporta mais); família `vendor_core_removed` (a)-(d) + (MUT) |
| 2 | A 1ª redação da cura passava `--literal-pathspecs` ao `git rm`, que o recusa: falhava calada e o arquivo ficava. A fixture pegou | recommended | **curado**: opção global do git, e a falha do `rm` agora é DITA em stderr |
| 3 | A detecção de "removido" sumia quando a raiz inteira (`.claude/workflows/`) deixava de existir no core: o manifesto só lista raiz que existe no HEAD. O caso (c2) caiu nisso na 1ª fixture | opportunistic | **teto declarado** no `vendor-branch.sh` (no core vivo `.claude/workflows/` segue com o `onion-research.js`) |
| 4 | O comentário da cura no `vendor-branch.sh` citava o workflow **com extensão**. Esse arquivo viaja e ANCORA peças por citação (`vendor-manifest.sh`, "_is_anchor"), então manteria o workflow vivo num papel que corta o `/meta:evolve` | recommended | **curado**: nomes sem extensão, e o porquê no comentário |

## Referências ao nome antigo (`grep -w`, depois do rename)

Atualizadas (vivas): `.claude/commands/meta/evolve.md` (tabela de peças, Passo 2.5, Passo 3, a
correlação por construção, a nota do atalho, Passo 5), `evolve-doctrine.md` (a peça 4 entrou na lista
de peças), o comentário do `vendor-manifest.sh` (agora diz o nome de hoje), a família `evolve_workflow`
e o `trace:` dos dois nós vivos (`E_LEVA2_PECA4_DO_EVOLVE`, `E_EVOLVE_ATALHO_DECLARA_COBERTURA`), com o
caminho antigo guardado em `x_trace_renamed_from`, sem apagar nada.

Mantidas por serem históricas (Aufhebung): labels e `provenance.source` dos grafos (o que se leu no dia),
os resíduos de revisão de 2026-10-04 e 2026-10-12, o relatório `docs/analysis/onion-evolution-2026-10-04.md`
e o inbox processado. Os exemplos de casamento de token no `vendor-manifest.sh` (`evolve.js` não casa
`onion-evolve.js`) ficam: ilustram a regra e não citam arquivo nenhum.

## Os `confirmed` dos grafos editados

A edição nos dois grafos é só o `trace:` de um nó (e o `x_trace_renamed_from` ao lado). Conferi os de
maior impacto do `evolve-cures-2026-10`: `E_LEVA2_CHECKPOINT_DO_DRIVE_NO_GRAFO` (o checkpoint do drive),
`E_LEVA1_SKILL_E_NAO_MEDIVEL` e `E_LEVA1_DIRETIVAS_DESCRITAS_NAO_ESCRITAS`. Nenhum fala do nome do
workflow, e nenhum é contrariado. No `triagem-evolve-kgssot-2026-10`, o próprio
`E_EVOLVE_ATALHO_DECLARA_COBERTURA` segue verdadeiro: o retorno com `not_measured` e `complete` não
mudou, só o nome do arquivo.

## O que não foi medido

- **Qual campo o harness usa para o nome da lista** (o `meta.name` ou o nome do arquivo): não medi. Os
  dois agora dizem `meta-evolve-fanout`, e o caso (n) reprova se divergirem.
- **O `--update` num adotante real** (o `onion-kg-ssot`): a cura foi provada em fixture, não no repo dele.
  Lá o `evolve` chamado pelo nome deixa de existir depois do update; o caminho é o `/meta:evolve`.

## Bancada e mutantes

`evolve_workflow` 14/14 e `vendor_core_removed` 6/6 com `LC_ALL=C`. Mutantes por
`ops/mutate-and-restore.sh` no caso (n): scriptPath do Passo 3 de volta a `evolve.js`, `meta.name` de
volta a `'evolve'` e `whenToUse` sem a 1ª frase reprovam o caso, e `evolve.js` recriado ao lado também.
Na cura do vendor-branch, o (MUT) da própria família apaga o bloco e o antigo volta a ficar.
