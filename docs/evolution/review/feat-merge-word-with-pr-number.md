---
branch: feat/merge-word-with-pr-number
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: aefdeb877c7ee6fe6ed117a07866d327be0eb57204f0117d8b1f163b6f51014b
reviewed_code_sha256: 10ef987bce62fe85f88d6479bae566113def32d48662faaf3c13dbac065edeea
findings_total: 5
findings_real: 5
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 5
verdict: FIXED
elenxo: true
elenxo_isolado: false
reviewer: "Revisor isolado merge-word-reviewer (opus), encomendado pelo core em 2026-11-25: FIXES_NEEDED sem bloqueio. Confirmou que o atalho OT_LIVE no _guard_pr_gate existe (o ajuste declarado é verdadeiro) e pediu A (important: a palavra com número amarra um head que o maestro não viu e valia até no PR da catraca), B (1,763 virava #1 e #763), C (palavra vencida ou gasta sombreando o pedido vivo), D (casos faltantes) e a doc do fallback de guarda. Os cinco curados neste commit, cada um com caso e mutante. elenxo_isolado fica false até o core pedir ao revisor a passada do delta."
nota: "tokens e duration_min = 0: não medidos aqui (a rodada do revisor é do core). PR de GUARDA que toca a própria catraca (ops/pr-merge-verified.sh): o merge segue do maestro."
---

# Passada adversarial: `feat/merge-word-with-pr-number`

## O que muda

Pedido do maestro (verbatim no brief): «quando eu digo "pode rodar 1763" ou "merge 1763" ou similar que você tenha
certeza do que eu estou falando, execute se ok». O «pode rodar» exigia o pedido prévio da sessão
(`--one-touch-request`) e a frase solta digitada no momento certo, dentro de 30 min.

- **Motor** (`.claude/utils/approval/one_touch.py`): `parse_word` reconhece a frase com número (lista fechada de
  verbos, conectivo opcional, 1 a 5 números, `?` final recusa); o hook, nesse caso, lê cada PR no forge pelo repo do
  `origin` do cwd e grava `approvals/<sessão>.pr-<n>.json` com o head daquele instante, sem pedido prévio. O
  `verify`/`consume` acham a aprovação daquele PR (`--pr`); o transcript tem de trazer a frase humana que nomeia
  aquele número; o id da palavra no livro leva o número (`prompt_id#n`).
- **Executor** (`ops/pr-merge-verified.sh`, core-only): o `consume` recebe `--pr`; PR `CLOSED` passa a ser recusado
  na âncora de estado, antes do auto-rebase e do comentário (antes só o forge recusava, depois de o script ter
  empurrado a branch e comentado); comentário do cabeçalho.
- **Hook**: só o cabeçalho (o comportamento mora no motor).
- **Esquema**: `evidence.pr`.
- **Docs e grafo**: README do motor, `decision-ratchet-doctrine.md`, grafo `one-touch-word-pr-2026-11.kg.yaml`.

**Ajustes do desenho do brief, declarados:**

1. **PR de guarda**: o brief listava «resíduo com elenxo_isolado para guarda» entre os gates. Hoje a palavra com
   pedido **substitui** o `--maestro` no PR de guarda (não pede resíduo isolado). Mantive a mesma força para a palavra
   com número: é a palavra do maestro, e o `--maestro` no terminal dele também não exige resíduo. Exigir resíduo
   isolado aqui deixaria o «pode rodar 1763» mais fraco que o «pode rodar» solto no caso exato em que o maestro
   reclamou da trava. Os outros gates (CI verde no head, ponta da base, catraca, rascunho) seguem todos.
2. **Validade**: 10 min a partir da palavra, como o brief pediu (o mesmo TTL de sempre).
3. **Pergunta não é ordem**: `merge 1763?` não registra.
4. **Data**: o brief data o pedido de 26/11; o relógio da máquina mediu 2026-11-25. Usei a medida.

## Achados

Rodada 1, revisor isolado `merge-word-reviewer` (opus), encomendado pelo core: **FIXES_NEEDED**, sem bloqueio.

| id | achado | cura | caso / mutante |
|---|---|---|---|
| A (important) | a palavra com número amarra o head lido na hora do hook, que o maestro nunca viu; com o `OT_LIVE` voltando antes do bloqueio da catraca, valia até para o PR que muda a própria catraca | (a1) o hook não registra em PR que toca a catraca e diz «peço o pedido com o sha na tela»; o executor também recusa (o `verify` devolve 4 para a palavra com número; lista única `_ratchet_hits`); (a2) o hook recusa head com menos de 120 s (data do commit do head no forge) | otn9, otn9-MUT, otn9b, otn9b-MUT; otn10, otn10-MUT |
| B | `1,763` virava #1 e #763 | vírgula só com espaço depois | otn16, otn16-MUT |
| C | palavra com número vencida ou gasta sombreava o pedido vivo do mesmo PR | o `load_live` ignora a vencida/gasta e usa o pedido; sem pedido, mensagem «a palavra com número para o PR #n venceu/já foi usada: diga de novo» | otn17, otn17-MUT; otn5b |
| D | casos faltantes | moldura pelo hook, TTL de 10 min e folga de 60 s no caminho numerado, timeout do gh, zero à esquerda, `1,763` | otn11, otn12, otn13/13b, otn14, otn15, otn16 (todos com mutante) |
| doc | README, grafo e resíduo diziam que a palavra substitui o `--maestro` sem ressalva | ressalva escrita: PR da catraca não sai por palavra com número, e com o revisor do CI em fallback (ou PR que muda a maquinaria do revisor) o resíduo isolado segue exigido pelo gate de fallback de guarda | — |

**Este PR é um desses**: muda a catraca e a maquinaria de guarda, então o merge exige o resíduo isolado; `elenxo_isolado: true` só depois da passada do delta.

## Mutantes

Família `pr_merge_verified`, casos `otn1` a `otn8`: frase com número registra e mergeia (mutante: sem o ramo, nada
registra); dois números registram dois usos (mutante: sem o número no id da palavra, o 2º PR é dado como usado);
texto a mais não registra (mutante: casar pelo começo registraria); pergunta não registra; PR inexistente e fechado
não registram (mutante: sem ler o estado, o fechado registraria); PR fechado depois da palavra, o executor recusa
antes de qualquer efeito (mutante: sem a recusa do CLOSED, seguiria adiante);
head mudado recusa e gasta (mutante: sem conferir o head, mergearia); sugestão aceita recusa (mutante: sem conferir a
origem, mergearia); repo errado recusa (mutante: sem conferir o repo, mergearia); frase de outro número recusa
(mutante: sem casar o número, mergearia).

## Limites declarados

- Bancada: família `pr_merge_verified`, 384 ✓ e 0 ✗ (rodada 1 curada; antes 363) (`LC_ALL=C`, `--families pr_merge_verified`). Cinco
  mutantes antigos (ot12, ot19, ot20, ot23, ot26) tiveram a âncora atualizada porque as linhas do motor mudaram; o
  sentido de cada um ficou o mesmo.
- Sem refutador neste PR: o brief pediu sem subagentes (cota alta); a revisão isolada é do core.

- Camada de **conformidade**, não fronteira de segurança: no mesmo usuário Unix o agente pode forjar o arquivo de
  aprovação, como no «pode rodar» de sempre.
- O hook gasta uma leitura no forge por número (medido: ~0,5 s cada; teto interno de 8 s, o settings dá 10 s).
- Só o checkout que tem o executor do merge verificado registra; o repo é o do `origin` do cwd.
- Na forma do meio do turno, o harness não marca `promptSource`: sugestão aceita não se distingue de digitada
  (limite herdado e já declarado no motor).
