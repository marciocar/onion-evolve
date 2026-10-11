---
title: 'Resíduo — a REGRA 30 varre ids de nó e caminhos de grafo, e o corpus é renomeado pelo id (SAC-99)'
date: 2026-10-11
branch: fix/projection-scrub-ids-graph-names
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
findings_fixed: 6
tokens: 174898
duration_min: 10
verdict: CORRIGIDO
elenxo: sim
nota: >-
  Refutador em passada adversarial (default reprovado) com mandato de achar referência quebrada e falso
  positivo. Veredito REPROVADO, 1 bloqueador e 6 menores; 6 curados com caso e mutante, 1 virou teto
  declarado. Referência quebrada: nenhuma fora dos registros históricos (as duas projeções resolvem ao
  regenerar, conferido pelo refutador em cópia).
---

# Resíduo — `fix/projection-scrub-ids-graph-names`

## O que mudou

- **REGRA 30 (Segurança de PROJEÇÃO: nome comercial de membro privado não sai)**: modo P7
  `--kg-identifiers` em `projection-safety.sh`, chamado pelo `check_projection_safety` sobre `docs/`.
  Varre o `id:` de nó e de meta e o caminho de todo `.kg.yaml`, com os termos derivados do
  `members.yaml` mais os do `client-terms.txt`, menos o termo que normalizado é id público.
- **Corpus renomeado pelo id do membro `hub-operacoes-enterprise`**: 4 ids de nó e 1 grafo (diretório,
  arquivo e `meta.id`). Arestas reescritas, `x_renamed_from` com o hash do id antigo, narrative
  "id anterior" com a parte privada marcada, labels dos nós renomeados usando o id, e a ligação por id
  no label virou `external_edge` conferida pelo gate.
- **REGRA 63 (Colheita de grafo emite os ids colhidos no resíduo de revisão)** reconhece renome
  declarado por `x_renamed_from`.
- **kg-contract-check** reconhece renome: o par que o `git diff --cached -M` detecta E que preserva ao menos metade dos ids de nó.
- `rito-task-manager-2026-09`: `gatilho` → `x_gatilho` (MUST herdado); `.kg-ssot/gate.json` travado.

## Ids renomeados (REGRA 63)

Os ids antigos não são escritos aqui por desenho: cada nó renomeado carrega `x_renamed_from` com o
sha256[:12] do id antigo, que é o que a REGRA 63 confere. Escrever os ids antigos verbatim gravaria de
novo o nome que o renome veio tirar. Os novos:

- `Q_HUB_OPERACOES_ENTERPRISE_MAIN_DIVERGIU` (`docs/onion/graph/rito-task-manager-2026-09.kg.yaml`)
- `E_hub_operacoes_enterprise_demo_route_caddy` (`docs/onion/graph/vps-shared-tools-2026-07.kg.yaml`)
- `Q_HUB_OPERACOES_ENTERPRISE_FALSOS_POSITIVOS_SEM_TRIAGEM` (`docs/evolution/research/inbox-triage-2026-10/`)
- `E_HUB_OPERACOES_ENTERPRISE_VEREDITO_DOS_TRES_FALSOS_POSITIVOS` e o grafo
  `hub-operacoes-enterprise-update-547-2026-10`.

## Achados da passada adversarial

| # | Sev. | Achado | Cura |
|---|------|--------|------|
| 1 | bloqueador | A REGRA 63 tratava renome como colheita e exigia o id antigo, com o nome privado, no resíduo | `x_renamed_from` (hash) isenta; casos (f)/(f2) em `harvest_residue`, mutante mordendo |
| 2 | menor | O comentário do P7 dizia não imprimir o caminho casado, e imprimia | comentário corrigido: o id não sai; o caminho sai porque é o artefato a renomear |
| 3 | menor | As projeções levam o nome também pelo label e pelo caminho do `trace:` | labels dos nós renomeados passaram ao id; o resto é teto declarado no grafo da forja |
| 4 | menor | Falso negativo: nome partido em tokens (`E_BETA_HAUSS_X`) | forma espremida (P7h) |
| 5 | menor | Falso positivo: sigla dentro de palavra e `id:` dentro de bloco escalar | termo curto casa só como token (P7g, P7j); bloco escalar é texto (P7i) |
| 6 | menor | O P7f grepava o fonte do lint, não o comportamento | P7f roda o `lint-artifacts.sh` de verdade num repo-sandbox |
| 7 | menor | Renome com limiar 50% herdaria dívida de grafo apagado | renome exige também metade dos ids de nó em comum; caso (k3), mutante reprova. O limiar de texto 90% sugerido foi medido e descartado: o próprio renome deste PR ficou em 85% |

**Não curado, declarado (teto):** id em estilo flow (`{id: X}`), com chave entre aspas ou com acento não
é visto. O radar, que é awk, também só lê o estilo de bloco, e id só aceita `[A-Za-z0-9_]`.

## Mutantes (todos com `ops/mutate-and-restore.sh`, `LC_ALL=C`)

P7: sem client-terms · sem exclusão de id público · sem teste de caminho · sem normalização · sem
varredura de id · sem token para termo curto · sem forma espremida · sem pular bloco escalar ·
dispatcher sem a chamada · dispatcher com `IS_LEAF` invertido. REGRA 63: sem o bloco do
`x_renamed_from`. kg-contract-check: sem o bloco de renome; sem a exigência de ids em comum. Todos mordem.

## Confirmed conferidos (REGRA 87)

Os `confirmed` dos grafos editados foram lidos antes de editar, e nenhum contraria o renome: o renome
muda o id, não a afirmação. `E_HUB_OPERACOES_ENTERPRISE_VEREDITO_DOS_TRES_FALSOS_POSITIVOS` e
`E_hub_operacoes_enterprise_demo_route_caddy` seguem com o mesmo label e a mesma provenance (só o nome
privado nos labels e na narração do update virou o id). No grafo da forja, `E_ID_E_CAMINHO_FORA_DO_ALCANCE_DA_REGRA_30`,
`E_SEIS_CASOS_SEIS_MUTANTES_MORDEM` e `E_ELENXO_REPROVOU_E_AS_CURAS` são os que este PR produz; o
segundo teve o label atualizado depois do Elenxo (10 casos, um mutante por cura).

## Teto

O P7 falha pelo vocabulário: nome que não está nem nos termos derivados nem no `client-terms.txt` passa.
Registros históricos (resíduos, mailbox `_processed`, CHANGELOG da federação) citam a forma antiga e
ficam como estão.
