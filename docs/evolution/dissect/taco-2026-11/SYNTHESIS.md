---
kg: docs/evolution/dissect/taco-2026-11/taco-2026-11.kg.yaml
run_id: dissect-taco-2026-11-19
tokens: 260000
agents: 2
duration_min: 50
---

# Dissecação do `pelles-ai/taco` (19/11/2026)

> Projeção do grafo [`taco-2026-11.kg.yaml`](taco-2026-11.kg.yaml) (radar 0, contrato rc 0). O nó vence a
> página. Etapa 0 pré-registrada em [`STAGE0.md`](STAGE0.md), commitada antes do N0. Família `ferramenta`,
> destino `core`, régua `onion`, nível-alvo N3. O veredito nasce `open`, e quem sela é o maestro.
> `tokens`, `agents` e `duration_min` acima são estimativa de quem conduziu, não medida do harness.

## O que é

**TACO, «The A2A Construction Open-standard»**: uma camada de ontologia da construção civil sobre o
protocolo A2A, com tipos de tarefa (`takeoff`, `estimate`, `rfi-generation`…), esquemas JSON tipados
(`bom-v1`, `estimate-v1`, `rfi-v1`…), extensão `x-construction` no Agent Card, taxonomia de escopos e um
SDK Python de referência (`taco-agent` no PyPI). Quem mantém é a Pelles AI.

## N0 (nível 0 do /meta:dissect), identidade

- **Licença real: Apache-2.0.** O `gh` lê «Other» porque o `LICENSE` traz só o cabeçalho de aplicação,
  sem o texto integral. O `pyproject` declara `Apache-2.0`. Vendorizar seria permitido, com aviso.
- **Vivo:** 206 commits, 48 tags até a v0.7.1 (03/11/2026), último commit na main 16 dias antes desta
  medida. Dois autores humanos, o dependabot e 63 commits com autor «Claude». A sucessão não está declarada.

## N1 (nível 1, capacidade), os verbos

- **CLI:** `taco discover | inspect | send | health | list-tasks`.
- **SDK:** `A2AServer.register_handler`/`register_streaming_handler` e admin de skills em runtime;
  `TacoClient.discover`/`send_message`/`stream`; `AgentRegistry.register`/`find`/`refresh`/`remove`;
  `TacoAgent.send_to_peer`; `JsonFileTaskStore`; push com checagem de SSRF; escopos por token.
- **O delta contra o Onion:** o taco serve o ciclo de vida da A2A Task (send, stream, get, list, cancel,
  push). O bridge A2A do core só recebe sinais e não serve `tasks/get` nem SSE.

**Os temas em decisão.** O taco toca **o núcleo de tarefas**: é a forma concreta de «construir o núcleo
sobre o contrato A2A Task», a opção que a curadoria nomeou sem medir. Toca também **a orquestração de
várias sessões**, em que agentes se descobrem pela skill e se chamam pelo tipo de tarefa. **Não toca o
Company Brain**, porque não tem memória, grafo nem conhecimento.

## N2 (nível 2), o mecanismo

Rodado num ambiente descartável (clone e venv no scratchpad, sem dependência global, sem chave): **660
testes verdes**.

- **Substrato.** É uma camada fina sobre o `a2a-sdk` 1.3.1: 7 dos 15 módulos o importam.
- **Despacho.** O executor roteia por `metadata.taskType` para um dicionário de handlers. A entrada é o
  primeiro DataPart. O executor emite `working`, depois o artefato, depois `completed` ou `failed`.
- **Persistência.** O store é por dono, com escrita atômica, e o próprio código o declara single-process.
- **Onde mora o determinismo.** Na bancada: paridade entre os modelos pydantic e os JSON Schema, e entre os
  dialetos A2A 0.3 e 1.0.

**O que a sonda mediu.** Montei uma skill declarada `bom-v1 → estimate-v1` e mandei entrada e saída fora do
esquema. A tarefa sai `completed`, com um artefato que não valida como `EstimateV1`. **O esquema fica no
Agent Card e não é cobrado no fio.** A sonda está em [`probe_output_schema.py`](probe_output_schema.py).

## N3 (nível 3), a transferibilidade

- **Igual → transfere, mas de outra fonte.** O que serviria ao Onion (o ciclo da Task, os stores, o push,
  os dois dialetos) é do `a2a-sdk`, e o taco só o embrulha.
- **Diferente → desenha.** O vocabulário é da construção civil e está em `Literal` no código. Para tarefa
  de software do Onion, seria falsa analogia. Transfere a **forma** (uma ontologia de domínio nos pontos de
  extensão do A2A), não o conteúdo.

## O veredito: **rejeitar** o uso (`D_TACO_VERDICT`, open)

Rejeito o código e a dependência, com data de 19/11/2026, por três razões:

1. O genérico vem do `a2a-sdk`, que o Onion pode usar direto.
2. O que é próprio do taco é vocabulário de construção.
3. O diferencial que interessaria, o esquema por tipo de tarefa, é declarado e não cobrado.

A **superação** está medida: o `a2a-sdk` oficial (1.3.1, Apache-2.0, Linux Foundation) entrega o servidor
de Task e os stores sem o vocabulário (`E_A2A_SDK_DIRECT`).

## O registro de ideias (o que segue, mesmo com o uso rejeitado)

| Ideia | Tipo | Onion | Valor | Destino |
|---|---|---|---|---|
| Tipos de tarefa com esquema por skill no Agent Card | funcionalidade | não temos | 4 | `Q_ONION_TRACKER_CORE_GAP_2026_11` (curadoria) |
| O gate cobra o esquema declarado (o contrário do taco) | decisão de desenho | diferente | 4 | `Q_ONION_TRACKER_CORE_GAP_2026_11` (curadoria) |
| Store de tarefas por dono, ListTasks paginado | funcionalidade | não temos | 3 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| Escopo por tipo de tarefa e projeto (read < write < admin) | decisão de desenho | não temos | 3 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| Chamar o par pelo tipo de tarefa (`send_to_peer`) | funcionalidade | diferente | 2 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| Tier de confiança atribuído pelo registro | estratégia | diferente | 2 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| «Ontologia, não protocolo» | estratégia | temos | — | `D_A2A_BACKBONE_PRODUCT_2026_11` (confirma) |
| Bancada nos dois dialetos A2A | decisão de desenho | não temos | — | nenhum (sem RPC de tarefas no bridge) |

## O que não foi verificado

- A adoção do padrão fora da Pelles.
- O demo com LLM, que exige chave.
- O registro compartilhado e os tiers de confiança, que existem só na spec.
- O capital da Pelles, que seria outro estudo, da família `ator`.
