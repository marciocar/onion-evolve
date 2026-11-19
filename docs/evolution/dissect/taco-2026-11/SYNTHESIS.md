---
kg: docs/evolution/dissect/taco-2026-11/taco-2026-11.kg.yaml
run_id: dissect-taco-2026-11-19
tokens: 430000
agents: 2
duration_min: 75
---

# Dissecação do `pelles-ai/taco` (19/11/2026)

> Projeção do grafo [`taco-2026-11.kg.yaml`](taco-2026-11.kg.yaml) (radar 0, contrato rc 0). O nó vence a
> página. Etapa 0 pré-registrada em [`STAGE0.md`](STAGE0.md), commitada antes do N0. Família `ferramenta`,
> destino `core`, régua `onion`, nível-alvo N3 (nível 3, transferibilidade). O veredito nasce `open`, e
> quem sela é o maestro. `tokens`, `agents` e `duration_min` são estimativa de quem conduziu (a sessão e o
> revisor isolado), não medida do harness.

## O que é

**TACO, «The A2A Construction Open-standard»**: uma camada de ontologia da construção civil sobre o
protocolo A2A, com:

- tipos de tarefa (`takeoff`, `estimate`, `rfi-generation`…);
- esquemas JSON tipados (`bom-v1`, `estimate-v1`, `rfi-v1`…);
- a extensão `x-construction` no Agent Card;
- uma taxonomia de escopos;
- um SDK Python de referência (`taco-agent` no PyPI).

Quem mantém é a Pelles AI.

## N0 (nível 0 do /meta:dissect), identidade

- **Licença real: Apache-2.0.** O `gh` lê «Other» porque o `LICENSE` traz só o cabeçalho de aplicação,
  sem o texto integral. O `pyproject` declara `Apache-2.0`. Vendorizar seria permitido, com aviso.
- **Vivo.** São 206 commits de 01/03 a 03/11/2026 e 48 tags, todas 0.x, até a v0.7.1. Contribuem dois
  autores humanos, o dependabot e 77 commits com autor «Claude». A sucessão não está declarada.

## N1 (nível 1, capacidade), os verbos

- **CLI:** `taco discover | inspect | send | health | list-tasks`.
- **SDK:**
  - `A2AServer.register_handler`/`register_streaming_handler` e admin de skills em runtime;
  - `TacoClient.discover`/`send_message`/`stream`;
  - `AgentRegistry.find` e `TacoAgent.send_to_peer`;
  - `JsonFileTaskStore`;
  - push com checagem de SSRF;
  - escopos `taco:task:<tipo>`, que dão 403 por padrão.
- **O delta contra o Onion:** o taco serve o ciclo de vida da A2A Task. O bridge A2A do core
  (TypeScript) só recebe sinais e não serve `tasks/get` nem SSE.

**Os temas em decisão:**

- **Núcleo de tarefas:** toca. O taco é a forma concreta de «construir o núcleo sobre o contrato A2A
  Task», a opção que a curadoria nomeou sem medir.
- **Orquestração de várias sessões:** toca. Os agentes se descobrem pela skill, se chamam pelo tipo de
  tarefa e, só na spec, delegam com token estreitado.
- **Company Brain:** não toca, porque o taco não tem memória, grafo nem conhecimento.

## N2 (nível 2), o mecanismo

Rodei num ambiente descartável (clone e venv no scratchpad, sem dependência global, sem chave). A suíte
deu **660 testes verdes**.

**O que vem do `a2a-sdk` 1.3.1:** o protocolo (executor, stores, push).

**A camada própria do taco, neutra quanto ao domínio:**

- despacho por `metadata.taskType` para um dicionário de handlers;
- escopo por tipo de tarefa;
- store de tarefas por dono, com escrita atômica;
- push com checagem de SSRF.

**Duas sondas:**

- **Esquema não cobrado na borda.** Montei uma skill declarada `bom-v1 → estimate-v1` e mandei entrada e
  saída fora do esquema. A tarefa sai `completed`, e o artefato não valida como `EstimateV1`
  ([`probe_output_schema.py`](probe_output_schema.py)). O SDK oferece validação **opcional** dentro do
  handler (`get_schema_model`), mas não a cobra.
- **Fora da construção.** Com um card A2A comum, sem `x-construction`, uma tarefa `code-review` sai
  `completed` ([`probe_plain_card.py`](probe_plain_card.py), sonda do revisor reproduzida). A camada
  genérica serve tarefa de software.

## N3 (nível 3), a transferibilidade

- **Igual → transfere o conceito.** Despacho por tipo, escopo por tipo e store por dono são o que um
  núcleo de tarefas do Onion sobre A2A precisa. O `a2a-sdk` não os tem.
- **Diferente → desenha.**
  - **Substrato:** o bridge do Onion é TypeScript, e usar o taco põe um runtime Python a mais na borda.
  - **Vocabulário:** a extensão `x-construction` e o `AgentRegistry.find` são falsa analogia.

## O veredito: **rejeitar** o uso do código (`D_TACO_VERDICT`, open)

As razões, datadas de 19/11/2026:

1. **Substrato.** Python contra o bridge TypeScript.
2. **Tamanho.** A camada genérica é pequena, e a casa absorve reescrevendo, não por dependência.
3. **Vocabulário.** A parte de construção é falsa analogia.
4. **Contrato.** O esquema por tipo de tarefa não é cobrado na borda.
5. **Mantenedor.** Uma organização de duas pessoas, com 48 tags 0.x em 8 meses.

**Superação: nenhuma.** Os SDKs oficiais do A2A, o Python 1.3.1 (rodado) e o JS 1.3.0 (lido no npm), dão o
protocolo, mas não a camada genérica. **Objeção sobrevivente** (`C_OBJ_PIECES_ALTERNATIVE`): um veredito em
peças também é defensável, rejeitando a `x-construction` e parqueando a camada genérica. Se o núcleo de
tarefas nascer em Python, a camada genérica volta a ser candidata a costura.

## O registro de ideias (segue mesmo com o uso rejeitado)

| Ideia | Tipo | Onion | Valor | Destino |
|---|---|---|---|---|
| Tipos de tarefa com esquema por skill no Agent Card | funcionalidade | não temos | 4 | `Q_ONION_TRACKER_CORE_GAP_2026_11` (curadoria, repo privado) |
| A borda cobra o esquema declarado (o taco só oferece) | decisão de desenho | diferente | 4 | `Q_ONION_TRACKER_CORE_GAP_2026_11` (curadoria, repo privado) |
| Store de tarefas por dono, ListTasks paginado | funcionalidade | não temos | 3 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| Escopo por tipo de tarefa e projeto (read < write < admin) | decisão de desenho | diferente | 3 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| Delegação com token estreitado a cada salto (RFC 8693) | estratégia | não temos | 3 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| Chamar o par pelo tipo de tarefa (`send_to_peer`) | funcionalidade | diferente | 2 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| Tier de confiança por verificação de terceiro | estratégia | diferente | 2 | `D_A2A_BACKBONE_PRODUCT_2026_11` |
| «Ontologia, não protocolo» | estratégia | temos | — | `D_A2A_BACKBONE_PRODUCT_2026_11` (confirma) |
| Bancada nos dois dialetos A2A | decisão de desenho | não temos | — | nenhum (o bridge não tem RPC de tarefas) |

Os destinos na curadoria ficam num repo privado, que um terceiro não consegue conferir.

## O que não foi verificado

- A adoção do padrão fora da Pelles.
- O demo com LLM, que exige chave.
- O registro, os tiers e a delegação, que existem só na spec.
- O `@a2a-js/sdk`, que não foi instalado.
- O capital da Pelles, que seria outro estudo, da família `ator`.
