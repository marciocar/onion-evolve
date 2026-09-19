---
title: 'Resíduo — a medição que decidiu, e a regressão que a bancada pegou no meio'
date: 2026-09-19
branch: fix/read-leg-reaches-bash
reviewed_diff_sha256: 1c838b3ef81719c3c213e30f225e3b0fd734b84c38f54b76dbf317c7045e6bdc
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 12
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Não houve refutador de agentes; houve MEDIÇÃO (19.084 chamadas de ferramenta em 29 transcrições) e
  a BANCADA, que reprovou duas vezes durante a cura — uma delas uma regressão que teria trocado 95%
  do valor do hook pelo caso novo. `elenxo: nao` declarado para não passar por descuido.
---

# A medição que decidia entre os três desenhos

O nó `Q_COMO_A_PERNA_DE_LEITURA_ALCANCA_QUEM_ESCREVE` registrava três desenhos e dizia que o que
decidia entre eles era uma medição **que ninguém tinha feito**. Feita:

| Ferramenta | Chamadas tocando `.kg.yaml` | % |
|---|---:|---:|
| **Bash** | **2.341** | **95,3%** |
| Edit | 83 | 3,4% |
| **Read** | **17** | **0,7%** |
| Write | 16 | 0,7% |

Fonte: 29 transcrições (841 MB), **19.084** chamadas de ferramenta extraídas por `jq`, recorte por
ocorrência de `.kg.yaml` em `file_path`/`command`/`pattern`/`path`.

**O hook vigiava 0,7% da superfície que existe para vigiar.** Isso **reprova o desenho (b)** (mover
para `Edit|Write` cobriria 4,1%) e escolhe o **(a)**.

## Os três achados, todos curados

**1. O matcher não alcançava quem escreve.** `kg-read-leg.sh` era `PreToolUse(Read)` e lia
`tool_input.file_path` — campo que **não existe** numa chamada `Bash`. Agora lê também
`tool_input.command` e o matcher é `Read|Edit|Write|Bash`.

**2. ⚠️ A bancada pegou uma REGRESSÃO minha, e era a pior possível.** Meu filtro barato
`case "${payload}" in *.kg.yaml*)` matava o **caso principal**: o hook avisa sobre **qualquer**
arquivo que um nó aponte por `trace:` — `src/alvo.ts`, um workflow, um script. Os casos (a) e (b),
que existem desde o nascimento do hook, reprovaram.

> **Eu teria trocado 95% do valor original do hook pela cobertura do caso novo.**

A condição certa tem dois ramos: com `file_path`, segue como sempre; **sem** ele, só vale parsear se
o comando cita um `.kg.yaml`.

**3. Meia-renomeação matou o hook no caso novo.** Renomeei `rel` → `_rel` no laço e deixei um `$rel`
solto na mensagem final: sob `set -u`, `unbound variable` **exatamente** no caminho que a cura vinha
habilitar. A primeira prova de execução pegou.

## O custo da cura, medido e endereçado

`Bash` é **16.338 das 19.084** chamadas desta base (**86%**). O hook passa a rodar em quase tudo —
por isso a **saída muda vem antes de qualquer parse**, num `case` de shell sobre a string crua.
O caso (g) da bancada prende isso: *bash sem `.kg.yaml` → 0 bytes*.

## A segunda camada, e por que ela é SOFT

REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele) avisa quando um PR edita um grafo
e o resíduo **não cita** os `confirmed` de impacto ≥4 daquele arquivo.

Ela entra **junto** com o (a), não no lugar: o teto da medição é que ela conta **chamadas**, não
**sessões que deviam ter lido**. Um aviso perdido entre 16 mil chamadas de shell tem chance real de
passar despercebido; este fala no PR, onde a proposta já está escrita e ainda dá tempo de voltar.

**SOFT, com a razão declarada e não por timidez:** foi desenhada **horas** depois do incidente que
endereça, e o registro do próprio achado diz que mexer às pressas num mecanismo logo após um
incidente é como o incidente. **Gatilho para promover a HARD: alguém reincidir na classe COM este
aviso na tela** — aí o aviso provou ser insuficiente, e não antes.

## Bancada

- `kg_read_leg`: **7 → 11** casos — fala por bash · **CALA em bash comum** · `Read` retrocompatível ·
  dois `.kg.yaml` no mesmo comando casam os dois.
- `kg_edit_confirmed`: família **nova**, 3 casos, com **controle negativo** (resíduo que cita o nó →
  cala) e SEM-OBJETO (PR sem grafo → silêncio).
- Suíte completa no pre-commit: **1366 passaram, 0 falharam**.

## Prova que chegou sozinha

Durante os testes, **o hook disparou no meu próprio comando** — pelo caminho novo, num `grep` de um
`.kg.yaml`. Não foi fixture: foi o mecanismo funcionando na sessão que o estava consertando.

## O que NÃO foi medido, declarado

A medição conta **chamadas**, não sessões-que-deviam-ter-lido: um `bash` que roda o radar conta igual
a um que edita o grafo. O número diz **onde o hook precisa estar** — não quantas vezes ele teria
mudado um resultado. É exatamente por isso que a segunda camada entrou.
