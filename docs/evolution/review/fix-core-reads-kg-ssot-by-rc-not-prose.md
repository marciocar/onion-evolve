---
branch: fix/core-reads-kg-ssot-by-rc-not-prose
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 241b91c1e98943835381ccdf71967de6a53287387c14b03cb6ca10d713950152
reviewed_code_sha256: 4d855a13e5ae2c4e2758434c1e28ed06816c8a5e6edfb6fd9c77a189657a6c54
findings_total: 4
findings_real: 4
findings_fixed: 3
tokens: 0
duration_min: 60
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: passada própria sobre o diff inteiro, com 4 mutantes aplicados e medidos nas famílias kg_migrate_v3, plan_contract_migration e pre_push
nota: "tokens 0 = não medido. Um achado fica declarado sem cura: o mutante do sítio (x) só morde quando a 4.18.0 existir."
---

# Passada adversarial: `fix/core-reads-kg-ssot-by-rc-not-prose`

## O que muda

A kg-ssot 4.18.0 vai imprimir a saída humana em inglês por padrão. A diretriz do maestro (2026-10-22) é que
o core decida por rc, JSON ou código de regra, nunca pela prosa de outra ferramenta. A língua não se fixa com
`KG_SSOT_LANG`, porque isso esconderia a dependência. A varredura cobriu `.claude/validation/`, `ops/`,
`.claude/hooks/`, `.claude/utils/` e `.github/` atrás de toda chamada de `vendor/kg-ssot/tools/*.py` e dos
wrappers (`ops/kg-gate-ci.sh`, `kg-contract-check.sh`) cuja saída é casada por grep, awk ou case.

| Sítio | Antes | Depois | Base |
|---|---|---|---|
| `lint-selftest.sh` kg-migrate-v3 (x) | `grep -q '^PASSA'` na saída do kg_validate | `_kmv_contract_ok` lê o rc (0/1/2) | rc |
| `lint-selftest.sh` plan-contract-migration (e) | `grep -q 'ENTRADA QUEBRADA'` | `ENTRADA QUEBRADA\|BROKEN INPUT` (`_pm_broken_re`) | bilíngue: o rc 2 do migrador é o mesmo do argparse |
| `ops/pr-finalize.sh` passos 0 (--check) e 4 | `grep -E '^✗\|ausente\|Error\|erro' \| grep -v '(herdado)'` | `_kg_gate_digest`, bilíngue, mais `QUEBRAD\|BROKEN\|diverg…` | só exibição: a decisão já era o rc. O kg_gate não tem `--json` |

## Achados

1. **O filtro do pr-finalize escondia o gate quebrado.** `GATE QUEBRADO` e `VENDOR QUEBRADO` (rc 2) não
   casavam com `^✗|ausente|Error|erro`, e o motor dizia "reprovou" sem mostrar linha nenhuma. **Curado:** o
   digest inclui `QUEBRAD|BROKEN`. O mutante 1 mostra o efeito: com o filtro antigo o ramo pt também cai.
2. **O 1º mutante não isolava a exclusão em inglês.** Ele derrubava os dois ramos pela linha do gate
   quebrado, e a exclusão do `(inherited)` ficava sem prova. **Curado:** a linha herdada do stub em inglês
   traz `missing`, que o digest novo casa, e o mutante 1b (sem `inherited`) derruba só o ramo en.
3. **O mutante do sítio (x) não morde na 4.17.2.** Ela ainda imprime `PASSA`, e por isso o predicado de
   prosa passa no grafo conforme. **Curado em parte:** o predicado foi para uma função única
   (`_kmv_contract_ok`), que o (x) usa e o (xl) exercita com um shim em inglês. O mutante morde no (xl). No
   próprio (x) a prova fica **NÃO MEDIDA até a 4.18.0**.
4. **A variável pt_BR não tem locale instalado na VPS.** `locale -a` só traz `C.utf8`, então
   `LANG=pt_BR.UTF-8` cai para C no glibc. A kg-ssot lê o VALOR da variável, que é o que a 4.18.0 usa para
   escolher a língua, e por isso o ambiente pt continua sendo o do contrato. O grep do core casa `✗` por
   byte. Fica declarado, sem cura: instalar locale na VPS precisa da autorização do maestro.

## Mutantes

| # | Mutação | Caso que cai | Medido |
|---|---|---|---|
| 1 | `_kg_gate_digest` volta ao filtro antigo | pre_push "contrato KG-SSOT em en" e "em pt" | 2 falhas |
| 1b | `_kg_gate_digest` sem `inherited` na exclusão | pre_push "em en" (só ele) | 1 falha |
| 2 | `_pm_broken_re='ENTRADA QUEBRADA'` | plan-contract-migration (k), no alvo em inglês | 1 falha; (e) segue verde |
| 3 | `_kmv_contract_ok` lê `^PASSA` em vez do rc | kg-migrate-v3 (xl): 6 de 8, o shim en no conforme | 1 falha; (x) segue verde (achado 3) |

Os quatro foram revertidos por cópia de segurança e conferidos por grep antes do commit.

## Ficam como estão (declarado)

- `lint-selftest.sh` kg-migrate-v3 (l): `form.enum.node.provenance.locality` é código de regra, que não muda.
- `plan-contract-migration.sh`: a planilha TSV do kg_migrate (colunas `ação`/`revisar`, valores `fora`,
  `provenance`, `review`, `scope`) continua em português. O `startswith("a proposta reprovaria no contrato")`
  lê a célula `revisar` da TSV e fica. **Risco nomeado:** se a 4.18.0 traduzir essa célula, a contagem
  "recusados pelo contrato" do resumo vai a 0 (só exibição, não decide o rc).
- `plan-contract-migration.sh` l.166 repassa a última linha do stderr do migrador (`tail -1`). É exibição,
  neutra de língua.
- `kg-radar.sh` `*"unrecognized arguments"*--due*`: é prosa do argparse do Python, não da kg-ssot. Só
  acrescenta a dica "vendor anterior à 4.15.0", porque o NÃO MEDIDO já sai pelo rc.
- `kg-decide-seal.sh`, `meeting-graph-check.sh`, `ops/kg-gate-ci.sh` e `.github/workflows/onion-validate.yml`
  decidem pelo rc. `kg-contract-check.sh`, `remeasure-contract.sh` e `migrate-seed-graph.sh` importam o
  módulo e leem códigos (`measure_texts`). O `server.py` do kg-writer usa a API do armazém e repassa o
  `message` só para exibição.
- `.claude/hooks/` não chama ferramenta da kg-ssot.

## Limites declarados

- Toda a prova em inglês é **simulação**: o stub do pre_push, o shim do kg_validate e o migrador falso.
  O inglês real só existe na 4.18.0, que ainda não tem tag. Re-rodar as três famílias quando o vendor subir.
- As três famílias passaram nos três ambientes (`LC_ALL=C`, `C.UTF-8`, `pt_BR.UTF-8`): 107 de 107 em cada.
