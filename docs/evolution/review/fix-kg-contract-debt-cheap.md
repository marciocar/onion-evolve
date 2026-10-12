---
branch: fix/kg-contract-debt-cheap
date: 2026-10-12
reviewed_diff_sha256: 32c7a782e9c6b7042045ba30a50254cf8df6df5124ae6a596eba7b19012c90d8
reviewed_code_sha256: a2fb63ae1945016ba1906c426ddbca5212fd03d07e7034c16ab65d65daa4f2a0
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 30
verdict: REPROVADO_E_CURADO
reviewer: passada própria + gate do contrato antes/depois (sem subagente) — gate mecânico: kg_gate.py + kg-radar em 124 grafos
---

# A frente barata da dívida do contrato, pedida pelo kg-ssot

## O pedido

A sessão do onion-kg-ssot pediu, em 2026-10-12, que a dívida SHOULD do corpus do core encolhesse.
Começamos pela parte mais barata: `testimony-in-prod` e `yaml.unquoted-date`. A outra condição era que
nenhum grafo novo entrasse na base, e nenhum entrou.

## Achados e curas (medidos pelo `kg_gate.py`, com os mesmos `--exclude` do CI)

1. **`yaml.unquoted-date`: de 129 para 58.** A cura foi o `kg-migrate-v3.py`, que é determinístico e
   idempotente, aplicado em 124 grafos. Ele só entrou nos grafos que tinham datas a citar e **nenhuma
   proveniência a derivar**, para não carimbar proveniência "DERIVADA" sem revisão. O diff tem 3.406
   linhas trocadas por 3.406, e **nenhuma** fora das chaves de data. O radar sai em exit 0 nos 124
   grafos. As 58 datas restantes estão em grafos que pediam proveniência derivada, ou em chaves que a
   ferramenta não cobre.
2. **`integrity.testimony-in-prod`: de 1 para 0.** O `E_MEDIDO_BLOAT_DO_PROPRIO_CORE_1001` era um nó
   PROD apoiado em relato. A medição foi reexecutada no mesmo commit (`44ceba79`), e o nó passou de
   testemunho a medição. Dois números reproduzem: os 408 arquivos `.md` com 71.675 linhas, e o `.sh`
   com 48.950 linhas contando fixtures. Um **não reproduz**: o `.sh` sem fixtures dá 48.919 linhas, onde
   o registro dizia 48.757. Isso ficou declarado no `method`, sem ajustar o número para casar.
3. **O ganho foi travado** com `kg_gate.py --update`. A base tem 151 grafos e **17** na dívida MUST
   herdada (o kg-ssot media 24 no pin antigo). O gate sai em rc 0 depois da trava.

## O que NÃO cobre

- As 58 datas restantes.
- O label longo (2.161 ocorrências): exige reescrever o label curto e passar o texto para `narrative`,
  o que é decisão humana. A ferramenta só lista.
- A queima dos 17 grafos MUST, que fica para as próximas levas, grafo por grafo.
