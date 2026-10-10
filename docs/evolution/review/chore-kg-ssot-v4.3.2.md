---
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 5
tokens: 109350
duration_min: 3
verdict: APROVADO
elenxo: sim
nota: >
  Refutador opus, com o mandato de achar falso negativo ou falso positivo na poda do índice, rodou sobre
  6ca5032f e REPROVOU. Não achou falso negativo novo, mas executou 4 falsos positivos (regex de linha
  contra valor YAML parseado) e um 5º causado pela inclusão do HEAD, cuja justificativa era falsa. Os
  5 foram curados no mesmo laço (d8f90695): os alvos vêm do documento parseado, só da versão de agora.
  Ele também achou um falso negativo anterior à poda (chave entre aspas), fechado pela mesma cura. A
  bancada dele foi re-rodada: os 10 casos agora dão o veredito do kg_validate --corpus. APROVADO
  descreve o estado depois das curas.
---

# Resíduo — `chore/kg-ssot-v4.3.2`

Adoção do kit `kg-ssot-v4.3.2` (60c6835eec2c). O contrato é o mesmo: o sha dos schemas MUST e SHOULD
é idêntico ao do v4.3.1. O índice de corpus do gate passa a ler só os grafos que alguma referência cita.
O `kg-contract-check.sh` do core recebeu a mesma poda.

| # | lado | achado | desfecho |
|---|---|---|---|
| 1 | FN | a poda criaria falso negativo? | **não**: menos entradas no índice nunca absolvem |
| 2 | FP, executado (4) | `external_targets` (regex no texto cru) perde alvo com escape YAML (`\x2F`, `#`, continuação de linha) | curado: alvos do documento parseado; caso (i2) e mutante. O gate do vendor tem o mesmo regex: **sinal** ao onion-kg-ssot |
| 3 | FP, executado | a inclusão dos alvos do HEAD liga o índice com alvos errados | curado: só a versão de agora |
| 4 | prosa | "as duas são medidas contra ele" era falso (do HEAD só se usa o SHOULD) | curado no nó `E_CONTRATO_V43_ADOTADO` |
| 5 | FN anterior | com a chave entre aspas, o índice ficava `None` e o alvo inexistente passava | curado pela mesma derivação; caso (i2) |
| 6 | prosa ok | sha dos schemas igual; tempo do checador compatível | — |
| 7 | prosa | a provenance do nó só citava o v4.3.1 | curado: o source cita a branch do v4.3.2 |

**Teto declarado:** o gate do CI (`kg_gate.main`, vendor) segue com o regex e cura só por tag nova do
kit. No corpus vivo: 29 referências, 0 perdidas.
