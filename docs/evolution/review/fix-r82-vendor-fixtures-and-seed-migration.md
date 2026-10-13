---
title: "Revisão — REGRA 82 já estava curada no core (o ruído é de pin antigo) e a semente antiga ganha migração no --update"
date: 2026-10-13
branch: fix/r82-vendor-fixtures-and-seed-migration
reviewer: "passada adversarial curta do próprio autor, como refutador das duas perguntas do pedido (a exclusão escondeu grafo real? a migração toca grafo do adotante?), com execução: a guarda velha e a nova contra o vendor 4.4.0, a migração contra a semente REAL do adotante (cópia de leitura, antes da conversão à mão dele) e seis mutantes via ops/mutate-and-restore.sh"
reviewed_diff_sha256: d3138eaedf316c7a2d7053d2df3af5b642d67583b7b7227ff87f374333f04078
reviewed_code_sha256: 8ce97fdfc1ff3caa378d06841b59f1f084ed3c6c30b72c51a03534029824a374
findings_total: 4
findings_real: 4
verdict: APROVADO
tokens: 0
duration_min: 95
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Medição antes da cura

- **REGRA 82 (paridade entre os leitores):** adotante sintético com `vendor/kg-ssot` 4.4.0 (247 `.kg.yaml`
  de conformidade). Com a guarda no pin do adotante (`ba0d2d423c17`, 2026-09-24): **11 SOFT
  RADAR-ILEGIVEL**, todos em `vendor/kg-ssot/spec/conformance/fixtures/`, os mesmos 11 do sinal. Com a
  guarda de `origin/main`: **0**. O core (que vendoriza o mesmo 4.4.0): **0** avisos da REGRA 82 no lint.
  A cura já existia desde `fa69e8ed` (2026-10-08): a varredura usa o predicado único
  `kg-fixture-paths.sh` (o mesmo das REGRAS 52 e 78). **Nada a mudar na guarda**; o adotante se cura
  com `/meta:adopt --update`. Entrou só o caso (b3) com o caminho exato do sinal.
- **Semente antiga:** a forma de dois documentos (`---`, cabeçalho com 8 chaves, `---`, grafo) é idêntica
  nas 5 versões do semeador de `370b992c` a `dbcf21b1^`. No adotante eram 3 de 4 grafos em dois
  documentos; só um era a semente.

## Achados da passada (4, todos curados neste PR)

1. **O pipe para o python era engolido pelo heredoc.** A 1ª redação passava a lista de grafos por stdin,
   e o heredoc do script É o stdin do python: "nada a migrar" sobre a semente velha, rc=0. Curado
   (lista por variável de ambiente), com o motivo no código.
2. **A conversão só de forma nunca passava no contrato 4.4.** O 2º documento escondia o MUST
   `form.required.node.provenance`, o mesmo que o adotante registrou com `--accept-regression`. Curado:
   os nós do semeador recebem a provenance que o semeador atual declara para eles.
3. **Fonte falsa por fallback (refutador da pergunta 2).** A 1ª tabela de provenance caía para o id
   quando o `verified_against` não batia. Na semente REAL do adotante a `Q_WHAT_IS_THIS_REPO_DOMAIN` já
   estava respondida, e ganharia "ausência de grafo de domínio" como fonte. Curado: chave exata
   (id, verified_against); nó editado fica sem provenance, o contrato reprova e a migração recusa
   nomeando os nós. Mutante `provenance-por-id-so` morde o (c2).
4. **NAO MEDIDO em toda adoção nova.** O passo roda no Procedimento comum à Fase 3 e ao `--update`, e
   cobrar PyYAML/vendor antes de saber se há candidato faria toda adoção avisar à toa. Curado com um
   pré-filtro textual (nenhuma linha `---` → rc=0). Caso (e) + mutante `sem-prefiltro`.

## Refutador, as duas perguntas

- **A exclusão escondeu grafo real?** Não: a guarda não mudou. `vendor/` NÃO é excluído inteiro, só os
  diretórios de fixture do predicado. O (b3) prova as duas metades no mesmo repo: o caso sob
  `vendor/.../fixtures` fica em silêncio e o MESMO conteúdo em `docs/` continua julgado.
- **A migração toca grafo do adotante?** Só se for o caminho fixo do semeador E tiver o marcador
  (`---` + `graph: onion-adoption`, só as 8 chaves no cabeçalho, 2 separadores, `meta.id:
  onion-adoption-*`). Antes de gravar, ela prova que o conteúdo parseado é igual (a única adição é a
  provenance da tabela), que o radar vê os mesmos nós, que a integridade passa e que o contrato não
  tem MUST. Na semente REAL do adotante ela **recusa e não toca** (3 nós dele sem provenance) e avisa
  sobre os 2 grafos de domínio dele. Esse é o comportamento certo: o dono decide.

## Mutantes (ops/mutate-and-restore.sh, LC_ALL=C)

| mutante | caso | resultado |
|---|---|---|
| guarda 82 sem o `continue` do predicado | (b2), (b3) | morde |
| sem `add_provenance` | (a) | morde |
| sem a checagem de caminho da semente | (c) (a cópia da forma da semente fora do caminho) | morde |
| provenance por id só | (c2) | morde |
| sem o pré-filtro | (e) | morde |
| `nd <= 1` → `nd < 1` sozinho | (b) | **sobrevive**: são duas camadas (pré-filtro + parser) |
| as duas camadas juntas (aninhado) | (b) | morde |

## Limites DECLARADOS

- O caso (b3) não exercita o lint inteiro, só o helper. É o mesmo SUT que o dispatcher chama.
- A migração não converte grafos do adotante. Os 2 do adotante do sinal seguem com ele.
- Sem refutador independente nesta rodada. As duas perguntas foram respondidas por execução, não por
  leitura.

## Leva pós-CI (2026-10-13)

O CI reprovou `kg-fixture-paths: (c) consumidores`: o script invocava o predicado pela variável `KFP`, e a
guarda reconhece o uso só pela forma canônica `bash "${_KFP}"`. Renomeada a variável para `_KFP`. A primeira
tentativa deixou um `${KFP:-/dev/null}` de fora, e a família `migrate_seed_graph` reprovou 4 casos ("nada a
migrar" sobre a semente velha); curado na mesma leva. `kg_fixture_paths` + `migrate_seed_graph`: 12/0.
