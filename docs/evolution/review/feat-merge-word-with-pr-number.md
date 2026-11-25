---
branch: feat/merge-word-with-pr-number
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: 5fd6eba161002fb5a625f81df5d44432a3a2e2a94beba869c3040c3a271409ab
reviewed_code_sha256: e607f75b1daeff884ee012250c1f9e5a3d13f3e73ebab87299b818212b397ac9
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
elenxo_isolado: false
reviewer: "Ainda sem revisão isolada: o core a encomenda depois da abertura do PR (brief do agente de execução, 2026-11-25). Este resíduo é da autoria; nenhuma passada adversarial rodou."
nota: "Números zerados = não medidos: não houve passada. PR de GUARDA que toca a própria catraca (ops/pr-merge-verified.sh): o merge segue do maestro."
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

Nenhuma passada adversarial rodou ainda; a revisão isolada é do core.

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

- Bancada: família `pr_merge_verified`, 363 ✓ e 0 ✗ (`LC_ALL=C`, `--families pr_merge_verified`). Cinco
  mutantes antigos (ot12, ot19, ot20, ot23, ot26) tiveram a âncora atualizada porque as linhas do motor mudaram; o
  sentido de cada um ficou o mesmo.
- Sem refutador neste PR: o brief pediu sem subagentes (cota alta); a revisão isolada é do core.

- Camada de **conformidade**, não fronteira de segurança: no mesmo usuário Unix o agente pode forjar o arquivo de
  aprovação, como no «pode rodar» de sempre.
- O hook gasta uma leitura no forge por número (medido: ~0,5 s cada; teto interno de 8 s, o settings dá 10 s).
- Só o checkout que tem o executor do merge verificado registra; o repo é o do `origin` do cwd.
- Na forma do meio do turno, o harness não marca `promptSource`: sugestão aceita não se distingue de digitada
  (limite herdado e já declarado no motor).
