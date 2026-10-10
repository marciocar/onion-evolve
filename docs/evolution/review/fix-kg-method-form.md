---
reviewed_diff_sha256: cc020469cdbc639f29d28d384f2c1c127e1367d53bc7238fa3607c88b5b65b34
reviewed_code_sha256: 53100656eaeb28ed51be033c9c39b8ea4bf2bc34d838fe74425eb2e5cc182fe3
findings_total: 7
findings_real: 5
tokens: 127207
duration_min: 4
verdict: APROVADO
elenxo: sim
nota: >
  Refutador opus julgou, nó a nó, a classe nova de cada um dos 34 method. Pediu 2 trocas de classe
  (uma delas em PROD), 1 detalhe vazio e 2 imprecisões, e REPROVOU por default. Também confirmou que a
  mecânica está limpa: kg_gate na HEAD e em origin/main diferem só na linha do código corrigido, e não
  sobrou testemunho em PROD. Os 5 achados foram curados em da93935f. APROVADO descreve o estado depois
  das curas.
---

# Resíduo — `fix/kg-method-form`

Sinal do onion-kg-ssot (2026-10-10): `form.pattern.node.provenance.method` 5 → 34 no corpus do core,
com nós escritos à mão sem o `: ` depois da classe. Os geradores já emitiam a forma certa. Aqui vão os
34 nós e, no mesmo PR, o pin do onion-kg-ssot (`54ef8ebdf150`, `registry-pins.sh --seal`, remoto).

| # | achado | desfecho |
|---|---|---|
| 1 | `D_COMANDO_PROPRIO_SCRIPT_MEDE_JUIZ_JULGA` (PROD) como medição sem invocação registrada; o `verified_against` é selo | curado: `leitura` do comando forjado (passos 1 a 10) |
| 2 | `E_SESSIONSTART_ASYNC_DUPLICAVA`: "observação do comportamento" exagerava, porque o comando não foi registrado | curado: `testemunho`, DEV (política 2) |
| 3 | `E_HOOK_ONFAILURE_BLOCK`: "leitura e medição" tautológico | curado: detalhe nomeia o que foi contado |
| 4 | 5 nós `juízes` descrevem leitura de linha primária, não veredito; `E_MODS` era inconsistente com eles | curado: os 6 viram leitura conferida pelo juiz |
| 5 | "leitura: o trecho citado no locator" em 7 nós não dizia nada | curado: o detalhe diz qual linha |
| 6 | o 138 → 139 do gate.json | não é achado: a base alcança o corpus que a main já media |
| 7 | labels da r8 afirmam sobre o core além do locator | **teto declarado**: fica para a próxima rodada do radar E3, não é desta onda |
