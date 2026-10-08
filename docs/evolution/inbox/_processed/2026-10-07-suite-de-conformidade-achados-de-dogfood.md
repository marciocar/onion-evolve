---
title: "A suíte de conformidade do .kg.yaml mediu o core por dentro: o radar reprova YAML válido, duas guardas ignoram a convenção de fixture, e mais 3 achados de dogfood"
date: 2026-10-07
type: signal
from: onion-kg-ssot (adopted, pin d82ca211bea0)
to: core (onion-evolve)
flow: upstream
severity: medium
decision_owner: core (maestro sela)
---

# O que o uso real da maquinaria mostrou ao construir a suíte

A semente da suíte de conformidade do `.kg.yaml` foi mergeada aqui (PR #12, nó
`A_CONFORMANCE_SUITE_SEED`): 87 casos em `latest/`, 14 em `proposals/` e um runner neutro de harness.
O maestro lembrou durante o trabalho: **"é dogfood e não interpretação de comandos e skills"**. Os
achados abaixo saíram de usar a maquinaria do core de verdade, e cada um foi **medido no core vivo**
(`33d4067a`) antes deste sinal. Quem decide a cura é o core, pela lente do Onion: medir, registrar como
nó, passar pelo Elenxo, mecanismo antes de conselho, teto declarado.

## 1. O `kg-radar.sh` reprova na LEGIBILIDADE um YAML válido (severidade média)

**Medido:** o grafo mínimo com as listas **sem indentação** sob a chave (o estilo padrão do
`yaml.safe_dump` do PyYAML) dá `rc=1` no radar do core vivo, na seção LEGIBILIDADE ("extraiu 0 nós"). O
mesmo grafo com as listas indentadas dá `rc=0`. Os dois são o mesmo documento YAML.

**Reproduzir** (o caso é público aqui, ids sintéticos):
`bash .claude/validation/kg-radar.sh <onion-kg-ssot>/spec/conformance/fixtures/latest/parse/document/valid-sequence-zero-indent.kg.yaml --integrity`

**Por que importa:** é a primeira divergência entre leitores que a suíte mediu
(`E_SUITE_RADAR_REJECTS_ZERO_INDENT`). Qualquer gerador que use o dump padrão de uma lib YAML produz
grafos que o gate do core recusa. A cura pode ser no radar (aceitar sequência sem indentação) ou no
contrato (o perfil YAML fixar o estilo); é decisão do core e do contrato.

## 2. As guardas da REGRA 78 (`.kg.yaml` versionado é YAML VÁLIDO, com catraca) e da REGRA 82 (Os dois leitores do corpus CONCORDAM sobre quem é nó) não consultam o predicado de fixture (severidade média)

**Medido no core vivo:** `kg-yaml-validity-check.sh` (linhas 82 e 111) e `kg-census-parity-check.sh`
(linhas 94 e 167) varrem `git ls-files '*.kg.yaml'` direto. O `kg-fixture-paths.sh` existe justamente
para que "seis consumidores" não repetissem a lista à mão, e a REGRA 52 o usa. Estas duas não.

**Efeito aqui:** um caso de conformidade deliberadamente não parseável, dentro de `fixtures/`, dava HARD
na REGRA 78 (`.kg.yaml` versionado é YAML VÁLIDO, com catraca). A baseline não serve: a catraca só a
deixa encolher contra `origin/main` (e foi bom ver isso funcionar). O contorno foi dar ao caso a
extensão `.yaml`. A REGRA 82 (Os dois leitores do corpus CONCORDAM sobre quem é nó) dá SOFT nos casos
que o radar não lê de propósito.

**Cura sugerida para medir:** as duas guardas passarem a usar `kg_graphs` do `kg-fixture-paths.sh`.

## 3. O `kg-backlog-project.sh` só vê grafos rastreados, e a skill manda regenerar antes do commit (severidade baixa)

**Medido:** o gerador enumera com `git ls-files` (linhas 61-62 no core vivo). O passo 5 da skill
`onion-research` manda regenerar o `docs/backlog.md` junto com o grafo novo, antes do PR. Feito nessa
ordem, o grafo recém-escrito ainda não está rastreado e fica fora da projeção. Aqui deu 22 abertos em 4
grafos; depois do commit, 30 em 5.

**Cura sugerida:** ou a skill manda regenerar depois do `git add`, ou o gerador inclui os
`*.kg.yaml` adicionados ao índice ou não rastreados.

## 4. O task-manager não tem executável (severidade média)

**Medido:** `.claude/utils/task-manager/` tem só `.md` e o `env-check.sh`. Não existe implementação de
`createTask`, `createSubtask`, `addComment` nem `updateStatus`. Cada sessão relê o adapter em prosa e
reimplementa as chamadas à mão. Aqui virou um cliente Zoho próprio, declarado no worklog. Ele funcionou:
subtasks com `parental_info`, status por `completion_percentage` e pelo id de Closed, comentários. Mas
é exatamente a "interpretação de comandos" que o maestro apontou: o resultado parece certo e não prova
nada da maquinaria.

## 5. `createTask` não atribui dono (severidade baixa, pendente do sinal anterior)

**Medido:** a seção `createTask(input)` do `adapters/zoho.md` (linha 147 em diante) não menciona
`owners_and_work`. As 16 tasks nasceram como "Unassigned User", e as 6 subtasks desta sessão só têm
dono porque o cliente próprio mandou `owners_and_work` no POST. O adapter documenta como atribuir
(linha 231), mas não na criação.

## O que este sinal NÃO afirma

- Não mediu outros leitores (o drive, o port JS, um extrator). A matriz leitor × caso é o E4 daqui.
- Não propõe o código da cura: as sugestões são pontos de partida para o core medir.
