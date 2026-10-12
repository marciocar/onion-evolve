# 9. Solução de problemas

[← Receitas](08-receitas.md) · [Índice](README.md) · [Glossário →](10-glossario.md)

Rode `kg_validate.py --where <arquivo>` primeiro: ele diz o código e o nó.

## Códigos MUST comuns

| Código | O que quer dizer | Como resolver |
|---|---|---|
| `form.required.node.provenance` | Nó `confirmed` ou PROD sem `provenance` | Acrescente `source`, `locator` e `method`. Sem fonte, mude o status para `unverifiable` |
| `form.pattern.node.provenance.source` | `source` é um marcador (`unknown`, `n/a`, `tbd`, `?`...) | Ponha a fonte real, ou use `unverifiable` |
| `form.unknown-key.node.<chave>` | Chave fora da gramática | Prefixe com `x_`, ou use o campo do contrato (por exemplo, `narrative`) |
| `form.required.node.<campo>` | Falta um dos sete campos obrigatórios | Acrescente o campo |
| `form.enum.node.<campo>` | Valor fora da lista (`node_type`, `plane`, `status`) | Veja as listas no [capítulo 3](03-formato.md) |
| `form.pattern.node.verified_at` | Data em formato errado ou que não existe no calendário | `AAAA-MM-DD`, entre aspas |
| `integrity.orphan-node` | Um nó sem nenhuma aresta | Ligue-o a outro nó, ou tire-o |
| `integrity.dangling-to` · `-from` | A aresta aponta para um id que não existe | Corrija o id, ou crie o nó |
| `integrity.duplicate-id` | Dois nós com o mesmo id | Renomeie um |
| `integrity.dangling-external` | A ponta externa não existe no corpus | Corrija o caminho ou o id depois de `#`, ou o grafo alvo ainda não foi para o git (`git add`) |
| `yaml.forbidden-key-on` | Aresta com a chave `on` | Troque por `trigger` |
| `parse.duplicate-key` | Chave repetida no mesmo mapa | Tire a duplicata |
| `parse.not-single-document` | Mais de um documento YAML (`---`) | Um grafo por arquivo |

## Avisos SHOULD comuns

| Código | Como resolver |
|---|---|
| `yaml.unquoted-date` | Ponha as datas entre aspas: `"2026-10-12"` |
| `form.range.node.label` | Encurte o `label` para até 280 caracteres e mova o resto para `narrative` |
| `form.pattern.node.provenance.method` | Use `<classe>: <detalhe>`, com a classe em `medição`, `leitura`, `juízes`, `derivado` ou `testemunho`. Reprova no v5 |
| `form.required.node.verified_against` | Diga o que foi conferido no `verified_at` |
| `form.required.node.verified_at` | Nó PROD sem `verified_at`: carimbe a última conferência |
| `integrity.untraced-decision` | Dê origem à decisão: `trace`, `provenance` ou uma aresta `TRACES_TO` |
| `integrity.testimony-in-prod` | Meça e troque a classe para `medição`, ou aceite o risco visível |

## O gate

| Sintoma | Causa | O que fazer |
|---|---|---|
| `GATE QUEBRADO  linha de base ausente` | Não há `.kg-ssot/gate.json` | `kg_gate.py --update` e commit da base |
| Um grafo novo não aparece na medição | O gate só mede arquivo rastreado | `git add` no grafo |
| `✗ PIOROU` num grafo que você não tocou | O contrato mudou de tag e o grafo passou a reprovar | Grave a base nova com `--update`; uma piora pede `--accept-regression "<motivo>"` |
| As fixtures do vendor entraram no corpus | `--no-default-excludes` foi usado | Tire a opção, ou passe `--exclude` |

## O vendor

| Sintoma | Causa | O que fazer |
|---|---|---|
| `check` dá rc 1 sem você ter editado nada | Um `.pyc` foi gravado no vendor por uma ferramenta que importou o kit | Apague o `__pycache__` e rode tudo com `python3 -I -B` |
| `update` se recusa a substituir | O destino não tem carimbo, ou o vendor diverge dele | Confira o que mudou; `--force` só se a edição local pode sumir |
| `update` de dentro do vendor falha | Falta `--source` | Passe o caminho ou a URL do repositório do produto |

## Ambiente

`pip install` recusado com `externally-managed-environment`: crie um venv (`python3 -m venv .venv`) e use o
Python dele. Detalhes no [capítulo 6](06-adocao-e-ci.md#nota-de-ambiente).
