---
reviewed_diff_sha256: 2900b3d9fe327995bfd16d655c48f96e482aa12d4a4ff6e97beface1df924788
reviewed_code_sha256: 91a7078d32b17ea7ef623a9517c7efca884966ce265213e751135052bebe3d2a
findings_total: 7
findings_real: 6
tokens: 148078
duration_min: 5
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Um refutador com o veredito começando em reprovado. Ele achou um bloqueador: a porta mini passava a
  reprovar a própria verificação, porque o door-mini-check não conhecia o .gitattributes novo. Achou
  também quatro defeitos menores no helper: governo de EOL lido em padrão alheio, binário .ts
  rastreado, pathspec recursivo em .githooks/* e linha aparada reacrescentada. Os cinco foram curados,
  cada um com caso e mutante. A catraca nº7 do registro tem um teto, que ficou declarado no código
  (26 das 93 regras). A projeção desatualizada é pendência de fechamento, resolvida pelo pr-finalize.
  Depois do PR aberto, o contexto principal rebaseou sobre a main com as REGRAS 102 (#1028) e 103 (#1029).
  O registro gerado (lint-rules.md) conflitou e foi regenerado: 95 regras, 98-103 presentes. Famílias
  rules_registry, eol_gitattributes, gitattributes_eol, door e door_mini com 51 verdes; selftest do hook de título OK.
---

# Resíduo: `fix/small-registry-and-door-gaps`

Três correções pequenas:

1. **REGRAS fora do registro.** As REGRAS 98, 99, 100 e 101 usavam o cabeçalho
   `# REGRA N (Título) — HARD`, que o `rules-registry.sh`, o `_rule_map_build` do lint e o hook
   `rule-title-in-prose.sh` não casam. Elas rodavam e ficavam fora do `lint-rules.md`. O registro
   passou de 89 para 93 regras. A causa estrutural ganhou a catraca nº7: regra emitida pelo dispatcher
   e ausente do registro faz o gerador sair com 2. Cobertura: bancada rules-registry (h) e selftest (d)
   do hook.
2. **Label duplicado na r9.** A premissa foi refutada por medição, então o grafo não recebeu cura.
   Rodei um loader PyYAML que acusa chave duplicada, com controle positivo, sobre a origin/main, todo
   o histórico do arquivo, as worktrees e o PR #1028, e nenhum tem duplicata. Os dois leitores pegariam
   uma duplicata: o `kg-radar.sh --integrity` sai 1 ("label repetido … a última venceu em silêncio") e
   o `kg-contract-check.sh` acusa `MUST parse.duplicate-key`. O leitor não tem lacuna. O nó ganhou
   apenas a narrativa do fechamento do item 3.
3. **O `.gitattributes` não viajava às portas.** O helper `emit-eol-gitattributes.sh` atua em dois
   lugares:
   - na porta, pela materialização, em todo papel, com o subconjunto medido;
   - no adotante, pelo passo 7 do `/meta:adopt`, em modo never-clobber.

   Ensaio real sem push (`publish-door.sh onion-standalone --from <branch>`): a raiz recebeu
   `.gitattributes` com `*.sh *.awk *.py *.js *.mjs`, o lint da porta deu 0 HARD e o índice do clone
   ficou com 734 arquivos em i/lf.

## Passada adversarial: REPROVA, curada

1. **BLOQUEADOR, real e curado.** O `door-mini-check` acusava o `.gitattributes` como arquivo a mais
   (`door-mini (a)` vermelho). Agora ele é esperado quando existe e traz o cabeçalho do helper. Mutante
   morto.
2. **MENOR, real e curado.** `*.png -text` e `[attr]` contavam como governo do .sh. Agora só conta
   governo no padrão nosso, em `*` ou em `**`. Caso (e2) com mutante.
3. **MENOR, real e curado.** Um `.ts` binário rastreado (i/-text) perderia CRs na renormalização.
   Agora ele fica de fora, nomeado. Caso (f2) com mutante.
4. **MENOR, real e curado.** O pathspec cru de `.githooks/*` era recursivo. Agora usa `:(glob)`, com
   `**/` só para padrão sem barra. Casos (f3) e (f), este com o .sh num subdiretório, cada um com mutante.
5. **COSMÉTICO, real e curado.** A linha nossa com recuo ou CR era reacrescentada. Agora a comparação
   é aparada. Caso (c2) com mutante.
6. **PENDÊNCIA DE FECHAMENTO.** As projeções `testing-inventory`/`testing-state` estavam desatualizadas
   (89→93). O `pr-finalize` as regenera.
7. **TETO DECLARADO.** A catraca nº7 vê 26 das 93 regras. A emissão multilinha, a mensagem sem
   prefixo e o cabeçalho com sufixo escapam. O teto está declarado no comentário da catraca.

## Achados (não curados aqui)

- **REGRA 65b**: o cabeçalho `# REGRA 65b — … [HARD]` não casa o parser (`\d+ [—-]`), então a guarda
  `check_session_models_baseline` roda fora do registro. É a mesma classe das 98-101, e a catraca nº7
  não a vê. Curar exige decidir a numeração de sub-regra.
- **REGRA 102** (PR #1028) já nasce com o cabeçalho canônico. Quem mergear por último precisa pôr a
  categoria dela em `rules-registry.sh`.
