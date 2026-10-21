---
title: Maquinaria de auditoria contínua — o que as primárias sustentam para os itens 1 e 2
date: 2026-10-21
kg: docs/evolution/research/audit-evidence-machinery-2026-10/audit-evidence-machinery-2026-10.kg.yaml
run_id: wf_25b440d5-1f7
tokens: 1713138
agents: 24
duration_min: 19
review_after: 2026-11-20
type: research
mode: primaries
---

> **Projeção do grafo, nunca fonte.** Toda afirmação aqui tem nó no `.kg.yaml` do frontmatter. As
> cinco decisões `D_AUDIT_*_1021` estão **`open`**: esta sessão não sela, o maestro sela pelo
> `/meta:decide`. Origem: `D_AUDITORIA_CONTINUA_PESQUISA_ANTES_DE_1_2` (pesquisar antes de desenhar a
> três) e o sinal do hub regulado, redigido em `docs/evolution/inbox/_processed/2026-10-20-audit-evidence-machinery.md`.

## O que a rodada sustenta

1. **O estado mora no banco do próprio produto, e o OSCAL fica na borda.** CISO Assistant (SQLite ou
   Postgres), Probo (Postgres) e Comp AI (Postgres e Redis) guardam estado em banco relacional próprio.
   O Lula v2 trocou o OSCAL como armazenamento por YAML em Git e manteve o OSCAL só na importação. Isso
   apoia "grafo YAML em git é o armazenamento, OSCAL é formato de importação e exportação", mas o apoio
   git-nativo vem de **um** fornecedor pequeno (`D_AUDIT_GRAPH_IS_STORAGE_OSCAL_IS_EDGE_1021`).
2. **OCSF 1.9.0, Compliance Finding (2003), é alvo de exportação de achado**, não base de vocabulário.
3. **A licença do SCF veta o ERL como base distribuível.** É CC BY-ND 4.0, e conteúdo derivado exige
   licença comercial. As portas públicas tornam o "uso interno" discutível
   (`D_AUDIT_SOURCE_NORM_EXCLUDE_SCF_ERL_1021`).
4. **O compliance-trestle (Apache-2.0) é só candidato a validador de exportação.** Não há prova de
   validação de ponta a ponta de AR e POA&M, e ele declara OSCAL 1.2.1 contra a 1.2.3 vigente
   (`D_AUDIT_TRESTLE_EXPORT_VALIDATOR_CANDIDATE_1021`).

## O que a rodada NÃO sustenta (e corrige)

- **`oscal_method` (EXAMINE/INTERVIEW/TEST) não tem âncora.** As cinco claims do OSCAL caíram na
  ancoragem. `acceptance` não existe no OSCAL: se entrar, é cunhagem do Onion, declarada como tal.
- **Os "7 dias" do FedRAMP 20x valem para o pacote inicial**, não como cadência recorrente. A cadência
  recorrente (CPO-CSX-CPM) varia por classe e também caiu sem citação. Nada ancora o radar no FedRAMP
  ainda (`D_AUDIT_REANCHOR_OSCAL_FEDRAMP_BEFORE_ITEMS_1021`).
- **Duas premissas do pedido corrigidas pelo core medido:** o `STALE-OLD` do `kg-radar.sh` compara
  `verified_at` com `meta.baseline`, então não há cadência por nó e o item 2 é um **leitor novo**; e o
  contrato v4 fecha as chaves do nó num enum de 22 (com `owner`), então campo novo sem `x_` reprova no
  MUST (`D_AUDIT_VOCAB_CONTRACT_VS_CORE_SPLIT_1021`, opções `C_OPCAO_A/B/C`).

## As cinco decisões para o maestro

| Nó | Pergunta | Recomendação do Elenxo |
|---|---|---|
| `D_AUDIT_REANCHOR_OSCAL_FEDRAMP_BEFORE_ITEMS_1021` | reancorar OSCAL e FedRAMP antes de escrever, ou escrever já com cunhagem declarada | reancorar (rodada curta, 2 chaves) |
| `D_AUDIT_VOCAB_CONTRACT_VS_CORE_SPLIT_1021` | o que vai ao contrato kg-ssot e o que fica no core | opção A: neutros no contrato, auditoria no core |
| `D_AUDIT_GRAPH_IS_STORAGE_OSCAL_IS_EDGE_1021` | selar grafo como armazenamento e OSCAL como borda | sinal fraco: selar com a ressalva, ou pesquisar mais |
| `D_AUDIT_SOURCE_NORM_EXCLUDE_SCF_ERL_1021` | qual norma alimenta `source_norm` | ponteiro opaco até medir licença |
| `D_AUDIT_TRESTLE_EXPORT_VALIDATOR_CANDIDATE_1021` | trestle como validador da exportação | candidato, condicionado a dogfood |

> **Fora do grafo (insumo de conversa, não nó):** em troca de mensagens de 2026-10-21, a sessão do
> kg-ssot aceitou que o campo de cadência pertence ao eixo da **verificação** (como `verified_at`), não
> ao do fato (`valid_from`), propôs `reverify_every` como candidato e deixou a escolha para depois desta
> pesquisa. O nome não está fixado e não é afirmação desta rodada.

## NÃO-VERIFICADOS

- **Rejeitadas na ancoragem: 30.** 15 sem citação e 15 exageradas, contadas em `E_LACUNAS_*`. Entre as
  sem citação: a versão OSCAL v1.2.3 (medida pela API, não pela página), os métodos de `observation`, a
  cadência CPO-CSX-CPM e a validação persistente FRC-CSX-VVK do FedRAMP, o OCSF 1.9.0 como estável mais
  recente, e tudo do CycloneDX (1.7.2 e a forma do VEX).
- **Fontes com 0 claim ancorada:** oscal-releases, fedramp-20x, cyclonedx-vex.
- **Lacunas abertas: 9**, entre elas os métodos OSCAL e a cadência do FedRAMP. Inalcançáveis: 0 (o
  seedtable devolveu HTTP 403 dentro da chave probo-compai, e o pré-seed do Comp AI ficou sem fonte).
- **Não aberto nesta rodada:** o `oscal-cli` do NIST, alternativa ao trestle.
- **Objeções sobreviventes: 10** (`E_OBJECAO_01` a `E_OBJECAO_10`). As de Probo e Comp AI dizem que
  Postgres e licença vêm do locator, não da citação.

## valeu-a-pena

1.713.138 tokens ÷ 57 nós ≈ **30k por nó**, com 24 agentes em cerca de 19 min. Abaixo da referência
do modo primárias (≈42k por nó, `wf_1865aba9-e20`) e muito abaixo da varredura (≈291k por nó). O
ganho principal foi negativo e barato: a ancoragem derrubou as três afirmações de mercado em que o
desenho mais se apoiava (métodos OSCAL, 7 dias do FedRAMP, ERL do SCF), antes de virarem campo de contrato.

Retorno integral do run: `data/run-wf_25b440d5-1f7.json`.
