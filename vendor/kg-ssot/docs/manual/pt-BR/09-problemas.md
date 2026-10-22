<!-- translation-of: docs/manual/09-troubleshooting.md sha256:43b4b90e23ac6e1f -->
# 9. Solução de problemas

[English](../09-troubleshooting.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

[← Receitas](08-receitas.md) · [Índice](README.md) · [Glossário →](10-glossario.md)

Rode `kg_validate.py --where <arquivo>` primeiro. Ele diz o código e o nó.

## Códigos MUST comuns

| Código | O que quer dizer | Como resolver |
|---|---|---|
| `form.required.node.provenance` | Nó `confirmed` ou PROD sem `provenance` | Acrescente `source`, `locator` e `method`. Sem fonte, mude o status para `unverifiable` |
| `form.pattern.node.provenance.source` | `source` é um marcador (`unknown`, `n/a`, `tbd`, `?`...) | Ponha a fonte real. Sem fonte recuperável, tire a `provenance` e use `unverifiable` |
| `form.unknown-key.node.<chave>` | A chave está fora da gramática | Prefixe com `x_`, ou use o campo do contrato (por exemplo, `narrative`) |
| `form.required.node.<campo>` | Falta um dos sete campos obrigatórios | Acrescente o campo |
| `form.enum.node.<campo>` | O valor está fora da lista (`node_type`, `plane`, `status`) | Veja as listas no [capítulo 3](03-formato.md) |
| `form.pattern.node.verified_at` | A data está em formato errado, ou não existe no calendário | Use `AAAA-MM-DD`, entre aspas |
| `integrity.orphan-node` | Um nó sem nenhuma aresta | Todo nó precisa de pelo menos uma aresta: em `edges`, `from:` o id dele, `to:` o id de outro nó e o `edge_type` da relação (`TRACES_TO`, `SUPPORTS`, `DEPENDS_ON`...). Sem relação, tire o nó. O `--where` mostra a correção com o id |
| `integrity.dangling-to` · `-from` · `-trigger` · `-on` | A aresta (ou o gatilho dela) aponta para um id que não existe | Corrija o id, ou crie o nó |
| `integrity.duplicate-id` | Dois nós com o mesmo id | Renomeie um deles |
| `integrity.dangling-external-local` | A ponta local de uma entrada de `external_edges` não existe neste arquivo | Corrija o id |
| `integrity.dangling-external` | A ponta externa não existe no corpus | Corrija o caminho ou o id depois de `#`. Ou o grafo alvo ainda não foi para o git (`git add`) |
| `yaml.forbidden-key-on` | Aresta com a chave `on` | Troque por `trigger` |
| `parse.duplicate-key` | Chave repetida no mesmo mapa | Tire a duplicata |
| `parse.not-single-document` | O arquivo tem mais de um documento YAML (`---`) | Um grafo por arquivo |
| `parse.yaml-error` | O YAML não parseia (ou passa do teto de aninhamento ou de aliases). No perfil do contrato, também cobre o tab fora de aspas, de bloco e de comentário, a tag `!` sem nome e o `!!timestamp` que não é data | Corrija a sintaxe na linha que o erro aponta. Troque o tab por espaços e ponha a data entre aspas |
| `parse.empty-document` · `parse.root-not-mapping` | Arquivo vazio, ou a raiz não é um mapa | O grafo começa por `meta:`, `nodes:` e `edges:` |

A lista completa, com a forma de cada código, está em
[`spec/conformance/README.pt-BR.md`](../../../spec/conformance/README.pt-BR.md#códigos).

## Avisos SHOULD comuns

| Código | Como resolver |
|---|---|
| `yaml.unquoted-date` | Ponha as datas entre aspas: `"2026-10-12"` |
| `yaml.unsafe-integer` | Um número inteiro passa de ±(2^53−1), e um leitor JavaScript perde o valor exato. Grave-o como texto, entre aspas. No `.kg.json`, reprova |
| `yaml.lone-surrogate` | O texto tem um surrogate solto (U+D800 a U+DFFF sem o par). Corrija o texto. No `.kg.json`, reprova |
| `yaml.depth-over-128` | O arquivo aninha mais de 128 coleções. Achate a estrutura. No `.kg.json`, reprova |
| `form.range.node.label` | Encurte o `label` para até 280 caracteres e mova o resto para `narrative` |
| `form.pattern.node.provenance.method` | Use `<classe>: <detalhe>`, com a classe em `medição`, `leitura`, `juízes`, `derivado` ou `testemunho`. Reprova no v5 |
| `form.required.node.verified_against` | Acrescente `verified_against`: diga o que você conferiu na data do `verified_at` |
| `form.required.node.verified_at` | Nó PROD sem `verified_at`, ou com `verified_scope` sem a data. Carimbe a última conferência |
| `form.enum.node.verified_scope` | Use `fato`, `mecanismo` ou `nenhum` |
| `integrity.untraced-decision` | Dê origem à decisão: `trace`, `provenance` ou uma aresta `TRACES_TO` |
| `integrity.refutes-unreconciled` | O nó recebe `REFUTES` e segue valendo: o grafo afirma e refuta a mesma coisa. Se a refutação procede, mude o status do alvo para `refuted` ou `superseded`. Se não procede, tire a aresta ou mude o status de quem refuta. Hoje é aviso, e vai reprovar numa versão futura do contrato |
| `integrity.verified-before-fact` | `verified_at` anterior a `valid_from`. Se o fato tem vigência futura (uma norma lida antes de entrar em vigor), o aviso é esperado e pode ficar na linha de base do gate. Se não, as datas estão trocadas: `valid_from` é quando o fato passou a valer, e `verified_at`, quando você o conferiu |
| `integrity.testimony-in-prod` | Meça e troque a classe para `medição`, ou aceite o risco à vista |

## O gate

| Sintoma | Causa | O que fazer |
|---|---|---|
| `GATE QUEBRADO  linha de base ausente (.kg-ssot/gate): grave a primeira com --update` (em inglês: `GATE BROKEN  missing baseline`) | Não há `.kg-ssot/gate/` (nem o `.kg-ssot/gate.json` de antes da 4.16.0) | Rode `kg_gate.py --update` e faça o commit da base |
| `· identidade contract_sha256: a base é de …` (em inglês: `· identity contract_sha256: the baseline is from …`) | A tag nova mudou os schemas, mas nenhum veredito mudou | Nada a fazer. Grave a identidade nova com `kg_gate.py --update` quando quiser |
| Conflito de merge em `.kg-ssot/gate.json` | A base de antes da 4.16.0 é um arquivo só | Suba para a 4.16.0 ou posterior e rode `kg_gate.py --update`: a base vira a pasta, com um registro por grafo |
| Conflito em `.kg-ssot/gate/contract.json`, ou modify/delete em `gate.json`, no primeiro merge depois da migração | Uma branch migrou para a pasta enquanto a outra ainda mexia no `gate.json` | Fique com a pasta, rode `git rm .kg-ssot/gate.json` e `kg_gate.py --update`. Migre as branches vivas antes de mergear para evitar o conflito |
| Um grafo novo não aparece na medição | O gate só mede arquivo rastreado | Rode `git add` no grafo |
| `✗ PIOROU` (em inglês: `✗ WORSE`) num grafo que você não tocou | O contrato mudou de tag, e o grafo passou a reprovar | Grave a base nova com `--update`. Uma piora pede `--accept-regression "<motivo>"` |
| As fixtures do vendor entraram no corpus | Você usou `--no-default-excludes` | Tire a opção, ou passe `--exclude` |

## O vendor

| Sintoma | Causa | O que fazer |
|---|---|---|
| `check` dá rc 1 sem você ter editado nada | Uma ferramenta que importou o kit gravou um `.pyc` no vendor | Apague o `__pycache__` e rode tudo com `python3 -I -B` |
| `update` se recusa a substituir o vendor | O destino não tem carimbo, ou o vendor diverge dele | Sem carimbo, o destino não é um vendor, e o `--force` não resolve: escolha outro `--dest`, ou tire a pasta do caminho você mesmo. Se diverge, rode `check` para ver o que mudou. Use `--force` só se a edição local pode sumir |
| `update` falha quando roda de dentro do vendor | Falta `--source` | Passe `--source https://github.com/marciocar/kg-ssot` |

## Ambiente

`pip install` recusado com `externally-managed-environment`: crie um venv (`python3 -m venv .venv`) e use o
Python dele. Detalhes no [capítulo 6](06-adocao-e-ci.md#nota-de-ambiente).
