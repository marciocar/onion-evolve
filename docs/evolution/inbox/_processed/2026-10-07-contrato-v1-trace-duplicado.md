---
title: "O contrato v1 do .kg.yaml mediu o core: 113 de 138 passam no MUST, e 5 grafos perdem um trace em silêncio por chave repetida"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: medium
decision_owner: core (maestro sela)
---

# O contrato v1 existe e já mediu o corpus do core

As três decisões de contrato que o core deixou com o produto foram seladas aqui (PR #13) e viraram o
contrato v1 (`A_CONTRACT_V1`): dois níveis de JSON Schema 2020-12, MUST (reprova) e SHOULD (alerta),
mais o perfil YAML 1.2 core no leitor de referência. O core já alinhou o `trigger` (PR B da leva de
2026-10-07). Este sinal traz a medição do corpus contra o v1 e um defeito de dado novo. Tudo foi medido
no core vivo (`33d4067a`) e no commit do spike (`d31ef4c0da6a`).

## 1. Cinco grafos repetem a chave `trace` num nó, e um dos dois some (severidade média)

**Medido no core vivo `33d4067a`**, com a regra de chave única do YAML 1.2 (`Yaml12CoreLoader` daqui):

| Grafo | Chave |
|---|---|
| `docs/evolution/research/engenharia-de-corpus-de-regras-2026-10/…kg.yaml` | `trace` |
| `docs/evolution/research/jev-type-safe-ai-2026-10/…kg.yaml` | `trace` |
| `docs/evolution/research/motores-de-regras-deterministicos-2026-10/…kg.yaml` | `trace` |
| `docs/evolution/research/unidade-bilhetavel-do-onion-2026-10/…kg.yaml` | `trace` |
| `docs/onion/graph/federation-health-2026-07.kg.yaml` | `trace` |

**Efeito:** o YAML 1.2 exige chaves únicas. O PyYAML fica com a última sem avisar, e o radar em awk lê as
duas como texto. Para qualquer leitor com lib YAML, um dos dois `trace` não existe, e a proveniência
some sem erro. Os quatro de pesquisa sugerem uma causa comum no gerador (`write(KG)` do workflow de
pesquisa?), a medir.

**Reproduzir:** `python3 -I tools/kg_contract_measure.py --git <core> --rev <sha> --list <lista>` daqui
conta `parse.duplicate-key` por arquivo; a chave aparece com `yaml.load(..., Loader=Yaml12CoreLoader)`.

## 2. O corpus contra o contrato v1 (informativo)

No MUST do v1 passam **113 dos 138** grafos (81,9%), contra 66 na régua estrita do spike
(`E_CONTRACT_V1_CORE_113_OF_138`). Os 25 que reprovam reprovam por **dado**, quase tudo já na leva de
correção do core: meta legado (sem `id` em 9, `schema_version` fora do valor em 7, ausente em 6), `on:`
em 5, `trace` repetido em 5 (item 1, novo), `valid_from` inteiro em 3, ids `SYNTHESIS.md_`.

No SHOULD, nenhum grafo sai limpo: 129 têm data sem aspas, 40 têm `note`/`purpose` no `meta` (à espera
de `Q_CONTRACT_FACT_NARRATIVE`, que o maestro ainda vai selar) e 12 têm nó PROD sem `verified_at`.

## 3. A guarda da REGRA 78 (`.kg.yaml` versionado é YAML VÁLIDO, com catraca) julga com o YAML 1.1 (severidade baixa)

**Medido:** um caso de conformidade com `baseline: 2026-02-30` sem aspas foi barrado como "não é YAML
válido (day is out of range for month)". No YAML 1.2 core esse valor é string, e o arquivo é válido. A
guarda usa o PyYAML com o resolvedor de timestamp do 1.1. Soma-se ao achado do sinal anterior (a guarda
não usa o predicado de fixture): o caso ficou com a extensão `.yaml`, como o outro. Se o contrato for
YAML 1.2 core, a guarda e o radar precisam ler com o mesmo perfil, ou o gate recusa o que o contrato
aceita.

## O que este sinal NÃO afirma

- Não mede o radar contra a suíte: essa é a matriz leitor × caso do E4 daqui.
- Não propõe o código da cura do item 1; a sugestão de olhar o gerador é hipótese, não medição.
