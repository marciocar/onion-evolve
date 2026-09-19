---
title: 'Resíduo — a medição que decidiu, e a regressão que a bancada pegou no meio'
date: 2026-09-19
branch: fix/read-leg-reaches-bash
reviewed_diff_sha256: 5850da8a0a559e5a84c35ea7bd297f8159ceb753a4e5bf0bf0766f668c5476d6
findings_total: 10
findings_real: 7
findings_fixed: 7
tokens: 187766
duration_min: 18
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  A passada adversarial REPROVOU com três bloqueantes. O pior não estava no hook: um `sed` global
  meu vazou pelo `lint-artifacts.sh` inteiro, corrompendo duas mensagens HARD que o usuário lê e
  vinte comentários. O nó que este PR cura é `E_PERNA_DE_LEITURA_E_CEGA_A_BASH`.
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


---

# A passada adversarial REPROVOU, e o pior achado não estava no hook

## F1 (bloqueante) — um `sed` global vazou pelo arquivo inteiro

Renomeei `arquivos` → `files_hit` com `sed s/.../g` sobre o `lint-artifacts.sh` **inteiro**. A palavra
portuguesa **arquivos** aparecia em **18 linhas** sem relação alguma com esta cura — e todas viraram
`files_hit`, incluindo:

- **duas mensagens de violação HARD que o usuário lê** (`:273`, `:281` — *"a varredura enxergou 0
  files_hit em ..."*);
- **comentários que justificam uma âncora de regex NOMEANDO a palavra literal** — viraram instrução
  **errada** para quem mexer ali depois.

> Esta casa já tem a lição escrita **duas vezes**: conferir rename com `grep -w <nome-velho>` = ZERO,
> e **conferir o diff pelo lado do que SAI**. Eu rodei a conferência na direção errada — verifiquei
> que a palavra antiga sumiu, e **o sumiço era o sintoma**, não a prova.

Curado: reverti o vazamento e renomeei **só dentro da função**, com prefixo `_r87_` que não colide
com prosa em pt-BR. Verificado pelo lado certo: **0 linhas com `arquivos` removidas**.

## F2 (bloqueante) — a REGRA 87 era insatisfazível, e reprovava o próprio PR

A 1ª redação exigia que o resíduo citasse **todos** os `confirmed` de impacto ≥4 do grafo tocado.
Medido nos 98 grafos versionados: **mediana 9**, **43 grafos com mais de 10**, o pior com **236**.
Ela reprovava este PR por 38 nós. **Um SOFT permanentemente vermelho não é sinal — é fundo**, e é a
mesma patologia que o PR alega curar no hook.

Redesenhada para a pergunta satisfazível: *citou **algum** dos três de maior impacto?* Citar zero dos
mais pesados de um grafo recém-editado é o sinal real — e foi o caso do incidente.

**A guarda redesenhada continuou me reprovando, e com razão**: eu não citava
`E_PERNA_DE_LEITURA_E_CEGA_A_BASH`, que é **literalmente o nó que este PR cura**. Agora cita.

## F3 (grave) — 6 de 8 mutantes sobreviviam à bancada

Incluindo **apagar o prefiltro inteiro** — a única justificativa para rodar em 86% das chamadas.
Medido pelo refutador: **8,7 ms → 36,3 ms** por execução e um `python3` por chamada, com a bancada em
14/14. Curado com casos que matam cada mutante.

## O que ele atacou e NÃO derrubou

- **Os números reproduzem**: Bash 95,3%, Edit 83, Write 16, Read 17 — exatos.
- **A dupla-contagem existe (24% dos blocos têm id repetido por *resume*) e NÃO muda a conclusão**:
  sob dedup, Bash = **95,5%**. O que era impreciso era o enquadramento absoluto, não a razão.
- **O caminho mudo não chama python** — `strace` confirma só `bash`, `cat`, `dirname`.
- **Fail-open correto** em JSON malformado, não-JSON, vazio, binário e `python3` fora do PATH.
- **Contrato de saída íntegro** com 5 caminhos, aspas, espaço, UTF-8 e tentativa de injeção.
- **O `awk` resiste** a status-antes-de-impact e a bloco literal com indentação realista.

## A lição

> **Conferir um rename pela ausência da palavra antiga é conferir a direção errada.** O zero que eu
> vi era o sintoma do dano, não a prova da cura. A pergunta certa não é *"sumiu?"* — é *"o que saiu,
> e eu queria que saísse?"*
