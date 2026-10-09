---
title: 'Resíduo — adoção do contrato KG-SSOT v4.2 (SAC-97)'
date: 2026-10-09
branch: feat/kg-ssot-contract-v42
reviewed_diff_sha256: d807ac6f7a4f8cf69a3f6913a111461eca41846bac0d0ca729cffaf31d3b5b3f
reviewed_code_sha256: 1ad5c6343e9dbd47c42fe1ef47c54ce7782e2b8ecf81692aac981f05924451c9
findings_total: 3
findings_real: 3
findings_fixed: 2
tokens: 0
duration_min: 95
verdict: CORRIGIDO
elenxo: nao
nota: >-
  A passada é do autor. O contrato é vendorizado por pin, e o juízo dele é do onion-kg-ssot, que publicou
  a tag. Aqui se prova a integração: vendor íntegro, gate rc 0 com a base nova por nó, a locality escrita
  no corpus com prova de que nada mais mudou, as 6 famílias de bancada afetadas verdes com LC_ALL=C e
  oito mutantes, cada um reprovando um caso.
---

# O que o v4.2 mudou e o que precisou mudar aqui

A tag `contract-v4.2.0` (commit 07d125c1cb50, 276 arquivos) absorve a v4.1.1 e não muda nenhum veredito
MUST. O relógio não zera. Ela traz três coisas, e cada uma tem um destino neste PR.

## 1. Dívida SHOULD por nó

Rodei `kg_gate.py --update --granularity node` com os mesmos `--exclude` do CI. Na passada que troca a
granularidade, a comparação é feita na da base, que é por grafo. Nada piorou, e por isso não houve
`--accept-regression`. A base guarda `"granularity": "node"`, e o passo do CI não passa a opção; o
comentário do workflow diz isso. MUST: 138 grafos, 19 na dívida herdada, antes e depois.

| Código | Grafos (antes) | Ocorrências (depois) |
|---|---:|---:|
| `form.pattern.node.provenance.method` | 6 | 39 |
| `form.range.node.label` | 111 | 2224 |
| `form.required.node.verified_against` | 16 | 141 |
| `form.required.node.verified_at` | 6 | 17 |
| `integrity.testimony-in-prod` | 36 | 121 |
| `integrity.untraced-decision` | 14 | 36 |
| `yaml.unquoted-date` (código de arquivo, 1 por grafo) | 129 | 129 |

## 2. `label anterior: …` na narrative

O `--apply-judged` do `kg-migrate-v3.py` já faz isso desde a O3 (caso `kg-migrate-v3 (k)`). Não houve mudança.

## 3. `provenance.locality`

A regra de onde a fonte mora é `locality_of`, em `.claude/utils/kg/kg-migrate-v3.py`. Ela é determinística
e erra para o lado de calar:
- o source é partido em segmentos, e cada segmento é julgado pelo 1º token;
- URL ou domínio vira `web`;
- caminho absoluto ou journal `wf_…` vira `host`;
- caminho cujo 1º componente existe na raiz do repo vira `repo`;
- sha vira `repo` só se `git cat-file -e` o encontra neste repo;
- relato de sessão ou do maestro vira `pessoa`;
- fonte mista vale a menos reverificável (repo < web < host < pessoa);
- sem certeza, a chave não é escrita.

**Geradores:**
- `kg-migrate-v3`: modo `--locality`, e os três modos que escrevem provenance passam a escrever a locality junto.
- `census-seal`: `repo`.
- `seed-adoption-graph`: `repo`. O gate provado ou adiado é `host`, porque a execução e o `core.hooksPath` só
  existem na máquina.
- `cc-delta-census`: `web`.
- `onion-research.js`: o `write(KG)` ensina as 4 classes e manda omitir na dúvida.
- `kg-contract-check`: ganhou a dica de cura do aviso novo.

**Corpus. Decisão: escrevi.** São 3517 provenances em 137 dos 138 grafos do gate: repo 1992, web 1381, host 129,
pessoa 15. Outras 233 ficaram sem a chave, por falta de certeza: citação bibliográfica, CHANGELOG descrito em
prosa, fonte de outro repo (`gustavo-pulga@sha`) e sha que o git daqui não conhece.

O tamanho cabe por três razões:
- **Uma linha por nó, e só ela.** O diff tem 3517 inserções e zero outras linhas. Cada grafo foi relido em YAML
  e é igual ao de antes, somado à chave; a ferramenta recusa gravar se isso não vale.
- **É regenerável.** Rodar `--locality` de novo resolve qualquer conflito com os PRs paralelos.
- **É o que dá valor à chave.** Os 129 `host` são exatamente o que uma porta pública precisa barrar.

Prova: 2ª passada com `--check` sai rc 0; `kg-radar --integrity` sai exit 0 nos 138 grafos; o gate sai rc 0 e
não acusa `form.enum.node.provenance.locality`.

# Achados

1. **Real, curado: a 1ª medição do corpus contava as fixtures do vendor.** Eu medi com
   `git ls-files '*.kg.yaml'`, que inclui `vendor/kg-ssot/spec/conformance/fixtures/`. Os 158 `source: "medição
   sintética"` dessas fixtures inflavam o "sem certeza". Cura: o corpus é o do gate, com os excludes do CI mais
   os defaults (`*/fixtures/*`, `docs/materials/*`), e dá os mesmos 138 grafos que o `kg_gate` mede. A
   ferramenta recebe a lista explícita e nunca toca o vendor; o `kg_vendor.py check` segue íntegro.
2. **Real, curado: sha precedido de `commit ` ou seguido de `^:` caía em "sem certeza".** A 1ª regra conferia o
   sha só no 1º token, e `commit a74ff166 · …` tem o token `commit`. Eram 43 provenances. Cura: o padrão do sha é
   casado no segmento inteiro (`git:`, `commit <sha>`, `<sha>^:<caminho>`), e o git confere. O mutante "sha sem
   o git conferir" reprova `kg-migrate-v3 (l)`.
3. **Real, explicado e não curado (não é defeito de código): o brief pedia `testimony-in-prod` em 107→103 nós, e
   o gate mede 121.** Medi por commit com `kg_validate --where`. No corpus inteiro do gate, o código tinha 125
   nós na adoção do v4.1 (05194c07) e tem 121 hoje: os mesmos −4. Os 107→103 do lote 6 foram contados só nos 91
   grafos que as ondas 2 e 3 tocaram, como a narrative de `E_ONDAS_O3_2_3_APLICADAS` diz. O ganho existe e é o
   que o v4.2 tornou visível; o número absoluto do brief não é o do gate.

# Mutantes (todos com LC_ALL=C, a cura revertida e o caso exigido em ✗)

| Mutante | Caso que reprova |
|---|---|
| mista pela MAIS reverificável (`min` no lugar de `max`) | `kg-migrate-v3 (l)` |
| sha aceito sem o git conferir | `kg-migrate-v3 (l)` |
| sem certeza vira `repo` | `kg-migrate-v3 (l)` e mais 2 |
| dica de `form.enum.node.provenance.locality` fora do checador | `kg-contract-check (h)` |
| linha da locality fora do `CONTRACT_V3` do `onion-research.js` | `research-workflow (r)` |
| uma linha `locality:` fora do molde da semente | `seed-graph (v42)` |
| linha da locality fora do `census-seal.py` | `census-seal (v3)` |
| linha da locality fora do `cc-delta-census.sh` | `cc-delta-census (e)` |

As famílias pedidas estão verdes: `kg_contract_check` 8/8, `kg_migrate_v3` 13/13, `research_workflow` 22/22,
e `census_seal`, `seed_adoption_graph` e `cc_delta_census` 23/23 juntas.

# KG

O nó `E_CONTRATO_V42_ADOTADO` foi criado em `contrato-kg-absorcao-2026-10`. Ele `SUPPORTS`
`D_GATE_CHAMA_O_VALIDADOR_DO_CONTRATO` e `Q_MIGRAR_CORPUS_PARA_CONTRATO_V3`. O teto sobe de 20 para 21, com a
justificativa no meta. O lote 6 foi selado com `--seal`, e o lote 7 foi aberto com `--close-lot`, pendente do
selo do maestro.

# Os `confirmed` dos grafos editados

O PR edita 137 grafos, mas não muda nenhuma afirmação: acrescenta só uma chave dentro da provenance, que diz
onde a fonte mora. Nenhum label, status, plane ou aresta foi tocado, e a releitura YAML prova isso grafo a grafo.
Conferi os três `confirmed` de maior impacto que a REGRA 87 nomeia, todos em
`interface-state-of-art.kg.yaml`:
- `E_DOGFOOD_STRUCTURE`: fonte `docs/discussions/interface-state-of-art/NOTE-05-dogfood-telemetria.md` → `repo`;
- `E_INTERACTIVE_ONLY`: mesma fonte → `repo`;
- `ENT_AUTH_LAYERS`: fonte `docs/knowledge-base/concepts/authorization-layers-intake-vs-execution.md` → `repo`.

Nenhum deles responde ao que este PR propõe nem o refuta, porque o PR não propõe nada sobre o conteúdo desses
grafos. A locality de cada um bate com a fonte que ele declara.

# Tetos

- A regra de locality julga o 1º token de cada segmento, e o resto do segmento é tratado como comentário. Um
  `docs/x.md em outro repo` viraria `repo`. Não medi nenhum caso assim no corpus, mas a regra não o exclui.
- O `repo` confere que o caminho começa num componente que existe na raiz, não que o arquivo exato existe:
  arquivo apagado segue reverificável pelo histórico do git, e é por isso que a regra é essa.
- As 233 sem certeza não são dívida do contrato (a chave é opcional). Uma onda julgada pode tratá-las se a
  porta pedir.
