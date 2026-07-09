---
tipo: sinal-upstream
data: 2026-07-09
origem: rhilo-metagamify + rhilo-app (odisseia WRR → KG-SDAAL → redesenho de front)
assunto: O SDAAL GENERALIZA — de knowledge-graph de auditoria para arquitetura de informação de UI
relacionado:
  - docs/evolution/inbox/2026-07-08-kg-dogfood-completo-promover.md
  - docs/knowbase/concepts/knowledge-graph-sdaal-spec.md
  - rhilo-app: apps/frontend/docs/design/command-center-atom-map.md
---

# Sinal: o método SDAAL se provou GERAL — o mesmo padrão modelou o domínio E redesenhou a UI

## A odisseia (o que aconteceu, em uma frase)

Partimos de um relatório de super-alocação WRR → construímos um **KG-SDAAL de domínio** (SSOT com rastreabilidade) →
validamos 3 decisões de negócio → e então, ao atacar o **redesenho do front de gamificação**, descobrimos que o
**mesmo método** resolvia a UI. Não por analogia — por identidade: o redesenho **é** SDAAL aplicado à arquitetura de
informação.

## A descoberta que vale promover

O `/meta:kg` estava gated esperando **1 dogfood**. Fizemos **dois**, e o segundo revela algo maior:

1. **1º dogfood (domínio):** o KG-SDAAL modelou o motor WRR — nós tipados (entidade/estado/evento/regra), arestas
   rastreáveis (`TRACES_TO` → código/endpoint), radar (PageRank + integridade), Fase-2 semântica (embeddings). O
   **SLOT-limbo caiu do modelo** como estado absorvente. (Já sinalizado em 2026-07-08.)

2. **2º dogfood (design/IA):** o redesenho do Command Center v2 (10 abas, ~100 elementos) sofria da MESMA doença que o
   KG cura — **os mesmos átomos de informação exibidos N×, de fontes divergentes** (Gini 4×, cap/floor 5×/3 endpoints,
   SLOT-não-materializado com 3 nomes). A cura foi **idêntica ao SDAAL**:
   - **Atom-map** = o `.kg.yaml` aplicado à UI: cada **átomo de informação** tem **1 fonte (endpoint) + 1 dono de
     exibição + 1 dono de escrita**. É o "1 conceito, 1 SSOT" do SDAAL, na tela.
   - **`SourceTag`** = **rastreabilidade-como-UI**: todo dado exibe `endpoint → conceito de domínio (nó do KG) → cálculo`.
     É a migalha `TRACES_TO` do KG, materializada como componente React.
   - **Invariante de verificação** = grep "cada endpoint-dono aparece em 1 componente" — o análogo da integridade do radar.

**Tese para o core:** o SDAAL **não é um padrão de auditoria** — é um **método geral de rastreabilidade e fonte-única**
que se aplica a qualquer camada onde a informação se duplica: conhecimento de domínio (KG), **e agora arquitetura de
informação de produto (UI)**. Candidato a uma **vertical de design/IA** no Onion, com o `SourceTag` + o atom-map como
artefatos de 1ª classe.

## O método completo (o padrão de trabalho que produziu isso)

`explorar-em-frota` (fan-out de agentes read-only mapeia o terreno) → `modelar como grafo SDAAL` (átomos tipados +
linhagem) → `validar` (adversarial + prova viva no dump) → `construir` (fundação à mão → frota por-sítio contra o
contrato). O atom-map/KG **é o guard-rail que torna a frota segura**: cada agente fica preso à fonte-única, então o
fan-out converge em vez de divergir. Isto é orquestração-guiada-por-SSOT — vale documentar como padrão.

## A agência (quem fez — porque importa para o core)

Foi **maestro humano + frota + método Onion**, e a lição é sobre a divisão: o **humano** deu direção, barra e os **vetos**
(rejeitar o raso forçou a profundidade); a **frota** deu largura e síntese; o **Onion** deu o método que fez o KG e a UI
**rimarem**. O padrão de colaboração que produz trabalho profundo = humano-define-o-invariante + IA-mantém-o-invariante.
O SDAAL é o que torna "o invariante" concreto e verificável.

## Proposta ao core

1. **Des-gate o `/meta:kg`** (o pré-requisito está cumprido em dobro).
2. **Promover o SDAAL como método geral**, não só KG-de-auditoria: adicionar a **vertical design/IA** (atom-map +
   `SourceTag` + o invariante de fonte-única) ao vocabulário do core.
3. **Documentar o método de trabalho** `explorar-frota → modelar-SDAAL → validar → construir` como padrão de orquestração
   guiada por SSOT.

— Rode `/meta:co-evolve` para triar. Companheiro do sinal de 2026-07-08 (aquele = o KG; este = a generalização).
