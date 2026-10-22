---
branch: chore/kg-ssot-4.18.0
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: ae4fcd7ee3999be9108c8204801253c07ac25cf5f88b1ddcf7ed01d173034ece
reviewed_code_sha256: def8f98944c745098d63f0c9e7dcea9e2b01ca4d5c5af519dce26dbc497c20de
findings_total: 5
findings_real: 5
tokens: 0
duration_min: 25
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: agente-execucao
nota: >-
  Subida do vendor kg-ssot de 4.17.2 para 4.18.0 (68e805df5ad5), sob a diretriz do maestro de 2026-10-22:
  decisão de máquina lê rc, JSON ou código de regra, nunca prosa de ferramenta alheia, e a cura não fixa
  KG_SSOT_LANG. A 4.18.0 traz o i18n (tools/kg_i18n.py e locale/, inglês fora de pt*) e o `plan --json` do
  kg_migrate com {"reason":"broken_input"} no stdout para a entrada quebrada.
---

# Passada adversarial: `chore/kg-ssot-4.18.0`

## O que muda

- `vendor/kg-ssot/` na tag `kg-ssot-v4.18.0` (521 arquivos; o perfil `gate` tem 12 entradas, com
  `tools/kg_i18n.py` e `locale/`). O comentário do pin no `onion-validate.yml` acompanha.
- `plan-contract-migration.sh`: com o vendor do alvo em 4.18.0 ou mais (lido do carimbo `.kg-ssot-version`), o
  `plan` roda com `--json`, e o rc 2 se classifica por máquina: `reason broken_input` no stdout (entrada recusada),
  stdout vazio (erro de uso) ou saída fora do contrato. Vendor 4.13–4.17 segue sem `--json`, com a frase dele
  (só pt-BR) apenas repassada.
- Bancada: o (e) e o (k) do plan-contract-migration cobram a frase do helper que nomeia o `reason`, não a prosa do
  migrador; o (l) novo separa os dois rc 2; três mutantes novos. O (xl) do kg-migrate-v3 troca o shim que imitava
  o inglês pelo vendor real, em 12 leituras, e exige ter visto as duas línguas.

## Achados (todos corrigidos neste PR)

1. **O caminho do manual sumiu.** A 4.18.0 renomeou `docs/manual/05-ferramentas.md` para
   `docs/manual/pt-BR/05-ferramentas.md` (o raiz agora é inglês). O helper orientava o dono do corpus para um
   arquivo inexistente. Corrigido para o caminho pt-BR.
2. **Os dois rc 2 do migrador eram indistinguíveis sem a prosa.** O helper só dizia o rc e a última linha; a
   bancada distinguia pela frase (`ENTRADA QUEBRADA|BROKEN INPUT`). Agora a classe sai do `reason` do JSON.
3. **O (xl) ficou vácuo com o vendor real.** O shim trocava `PASSA` por `PASS`, o que na 4.18.0 em inglês não
   muda nada. Trocado pelo eixo `KG_SSOT_LANG` (ausente, en, pt-BR) × locale, com a asserção de que as duas
   línguas apareceram.
4. **Mutante de prosa com o caso errado.** O mutante que lê `BROKEN INPUT|ENTRADA QUEBRADA` no stdout derruba o
   (e), não o (l) (a saída fora do JSON não chega à comparação). Corrigido o caso cobrado antes de rodar.

## Mutante 3 do #1290

O `_kmv_contract_ok` voltando a `grep -q '^PASSA'`: em `LANG=C.UTF-8` o (x) cai (o vendor real responde `PASS`),
e o (xl) cai nas duas rodadas. Com `KG_SSOT_LANG=pt-BR` o (x) passa, como esperado: é a prova de que a
dependência era só da língua.

## NÃO MEDIDO

- Um adotante real com vendor entre 4.13 e 4.17 rodando o helper novo: coberto só pelo falso com carimbo 4.17.2.
- O `--json` do `plan` num corpus grande (a saída JSON inteira fica em memória no bash): medido só nos fixtures.
- O stub do pre_push simula a língua do gate; o `_kg_gate_digest` com o `kg_gate.py` real em inglês reprovando
  não foi exercitado (ele só exibe; quem decide é o rc).

## Achado 5 (CI do PR, curado pela sessão principal)

O selftest do kg-writer (`ops/mcp-onion-kg-writer/selftest.py`) monta um vendor FALSO e copiava só o
`kg_store.py`. Desde a 4.18.0 o armazém importa o `kg_i18n`, que lê o catálogo em `vendor/kg-ssot/locale/`,
e o caso (a) caiu no CI com `ModuleNotFoundError: No module named 'kg_i18n'`. É harness incompleto, não
produção: o servidor real carrega o vendor inteiro. A cura copia o `kg_i18n.py` e o `locale/` quando existem
(vendor antigo segue funcionando). `LC_ALL=C bash .claude/validation/lint-selftest.sh --families
mcp_onion_kg_writer`: 65/0, com o (a) em 62 casos. Varredura de outro harness que copie ferramenta do
vendor peça a peça: só este (`git grep` por cópia de `kg_*.py` fora do vendor).

