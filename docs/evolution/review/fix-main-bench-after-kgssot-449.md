---
branch: fix/main-bench-after-kgssot-449
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: bd8de25eb42cc9e6a9b2eaa2b3a6fd3fdd5ae421a9e83999da4ead15ecab5b85
reviewed_code_sha256: 5ea8d3c3d6bd934427521918b298ed3b95d6a961d879498f67be9c0094a62752
findings_total: 3
findings_real: 3
findings_blocking: 2
tokens: 0
duration_min: 45
findings_fixed: 3
verdict: FIXED
elenxo: true
reviewer: agente de execução (sem refutador separado: o brief vetou lançar agentes)
nota: "tokens não medidos (0). Passada pelos mutantes, sem subagente refutador, porque o brief da sessão principal proibiu lançar agentes."
---

# Passada adversarial: `fix/main-bench-after-kgssot-449`

## O que muda

A bancada completa do push da main ficou vermelha depois da atualização do kg-ssot para a 4.49.0 (contrato v4.21,
PR #1592). Esta branch conserta a bancada, não o vendor, e não reverte a atualização (os reverts automáticos
#1600 e #1608 ficam sem merge).

- `kg_contract_check` (a), (h), (i), (i2): a fixture `_kcc_graph` escrevia `method: "medição: …"`. No v4.21 o
  apelido em português alerta `SHOULD form.deprecated.node.provenance.method`, e num grafo NÃO rastreado todo
  SHOULD conta, então os grafos novos que deviam passar saíam rc 1. A classe agora vai em inglês (`measurement:`),
  na fixture e nas duas âncoras do `sed` do caso (h). O que cada caso prova não muda.
- `adopter_shape` (i6-MUT recusa-inline): não vem do kg-ssot. É uma intermitência. `_as_rb_prep` e `_as_rb_run`
  nomeavam o diretório da fixture com `$RANDOM` (15 bits, cerca de 250 diretórios por família). Quando o nome se
  repetia, a semente fazia no-op (never-clobber), o preparo não achava mais a âncora e o caso saía
  `c:<rótulo>:setup`. Medido: a falha aparece em 1 das 4 rodadas vermelhas da main (43162484859), e as outras 3
  falharam só no kg. Localmente a família passou verde antes da cura. Agora o diretório nasce por `mktemp -d`.

## Achados

1. (bloqueia) A fixture do kg usava a classe de method em português, que o contrato v4.21 desaprovou. Curado.
2. (bloqueia) O nome por `$RANDOM` da fixture i6 colidia de forma intermitente. Curado com `mktemp -d`.
3. (limite, curado no comentário) O mutante documentado do caso (i2), trocar o alvo pelo `external_targets` do kit,
   ficou EQUIVALENTE, porque o kit 4.49 também lê o documento parseado. Medido: o helper saiu rc 0, e o mutante
   sobreviveu. O comentário passou a nomear um mutante que morde: um regex de linha sobre o texto cru. Medido rc 1.

## Mutantes

Todos foram plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`. A linha de base foi provada pela rodada
verde das duas famílias sobre o mesmo conteúdo (`MUTATE_BASELINE_PROVEN`, declarado).

- Fixture de volta para `medição:`: helper rc 1. Derruba (a), (h), (i) e (i2).
- Tirar a dica de locality do HINT: helper rc 1. Derruba (h).
- Medir sem o índice do corpus (`None`): helper rc 1. Derruba (i) e (i2).
- Alvo por regex de linha no texto cru: helper rc 1. Derruba (i2).
- Alvo pelo `external_targets` do kit (o mutante antigo do comentário): helper rc 0, porque é EQUIVALENTE. Ver o achado 3.
- Nome fixo no lugar do `mktemp` em `_as_rb_prep`: helper rc 1. Reproduz `c:…:setup` em recusa-inline e em mais 4
  mutantes i6, que é a assinatura exata da falha da CI.

## Limites declarados

- O refutador opus não rodou, porque o brief vetou lançar agentes.
- A bancada completa (`ONION_SELFTEST_FULL=1`) não rodou, por ordem do brief. Rodaram só as famílias tocadas e a
  `selftest_selection`.
- `_i4_run` e `_i5_run` também usam `$RANDOM`, mas sobrescrevem os arquivos com `printf >`. Por isso a colisão é
  inofensiva ali, e eles não foram tocados.
