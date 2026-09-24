---
branch: feat/r85-post-merge-e-pesquisa-zoho-glpi
pr: 872
date: '2026-09-24'
reviewed_diff_sha256: c4a7d0a8966e1a7a0695e1d9cf76eee2d2e88c89f7e7dc42fcd5ae1dceeb76c5
findings_total: 6
findings_real: 6
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Leva de DECISÃO SELADA pelo maestro mais salvamento de artefato. Sem refutador independente, e o
  limite está dito. O que importa verificar aqui não é "a mudança é boa" — o maestro decidiu isso —, é
  se a mudança AFROUXOU DEMAIS: mover uma cobrança de lugar pode virar buraco silencioso. Foi essa a
  pergunta que dirigiu a passada, e ela tem resposta mecânica (a família de 5 casos, com o caso (e)
  verificando que o novo lugar EXISTE). Campos de custo em ZERO: não houve run de modelo.
---

# Resíduo — a porta cobrada pós-merge, e a pesquisa salva

## A pergunta que dirigiu a passada

Não *"vale mover a cobrança?"* — isso o maestro selou. A pergunta é **"mover pode virar buraco?"**,
e ela tem três formas concretas, todas testadas:

1. Se `ANDOU-PARA-TRAS` cai para SOFT, **`SEM-BASELINE` e `PIN-DESCONHECIDO` caem junto?** Seria
   passar a tolerar **registro quebrado**, que não é questão de momento nenhum. → casos (b) e (c).
2. **A guarda que não pôde julgar** continua bloqueando? → caso (d).
3. **O novo lugar existe de fato?** Uma cobrança que sai do PR e não chega a lugar nenhum é pior que
   a cobrança insatisfazível que ela substituiu. → caso **(e)**, que verifica o workflow.

## Achados

| # | achado | destino |
|---|---|---|
| 1 | A REGRA 85 (Porta pública espelha o core, com catraca) era **estruturalmente insatisfazível** no PR: a cura só existe depois do merge. Medido no próprio `door-staleness-baseline.txt` — 5+ ocorrências de *"o gate fica VERMELHO até o push"*, e uma leva pagando **duas materializações** | CURADO: `ANDOU-PARA-TRAS` → SOFT com rótulo, cobrança bloqueante no workflow `onion-door-staleness` (push para main) |
| 2 | **Risco da própria cura**: afrouxar em bloco tornaria tolerável registro quebrado | CONTIDO: `SEM-BASELINE`, `PIN-DESCONHECIDO` e `ERRO` seguem HARD; 4 casos de bancada provam a fronteira |
| 3 | O workflow novo precisa de `fetch-depth: 0`, senão o clone raso produz `PIN-DESCONHECIDO` **falso** — falha de ambiente vestida de veredito, a classe que esta sessão curou três vezes | PREVISTO no workflow, com o porquê escrito |
| 4 | A pesquisa Zoho/GLPI estava **sem commit e sem SYNTHESIS** — 7,18M tokens a um `git clean` de distância | SALVA, com o contrato de custo no frontmatter e a REGRA 29 (Gate de PROVENIÊNCIA INVERTIDO, com catraca) atendida por trace composto |

## O que a pesquisa salva declara, e não esconde

- A premissa *"a API é a mesma em qualquer hospedagem, então o adapter não muda"* **não sobreviveu**
  aos votos. É hipótese a medir contra a instância real — subir, restaurar, chamar, **contar campos**.
- O eixo **mercado devolveu zero**, violando `follow-the-money`. Registrado como **defeito do
  fan-out**, não como conclusão sobre o mundo.
- `valeu-a-pena` = **~312k tokens/nó** contra 68-74k do censo. A explicação é o achado: **corpus
  vazio não transfere nada**, então cada nó nasceu de coleta externa.

## Verificado

- `lint-artifacts.sh` → **0 HARD**, 15 SOFT (dois são a porta, agora como aviso — que é o efeito pretendido)
- `door_staleness_severity` → **5/5**
- `rules-registry.sh` → paridade confirmada por diff
- radar nos dois grafos tocados → exit 0
- `yaml.safe_load` no workflow novo → válido, gatilho `push[main]` + `workflow_dispatch`

## Fora do escopo, declarado

O **efeito** da mudança só se mede no próximo merge: é ali que o `onion-door-staleness` roda pela
primeira vez. Se ele não disparar, ou disparar sem nomear a porta, isso é defeito desta leva e volta
como achado — **o caso (e) prova que o workflow existe e invoca a guarda, não que o GitHub o executou.**

## Os `confirmed` dos grafos editados (REGRA 87) — e a guarda achou defeito de verdade

A REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele) me obrigou a ler os nós de maior
impacto dos dois grafos que este PR toca. **Não foi formalidade: dois deles derrubaram o que eu havia
escrito na SYNTHESIS**, porque eu a redigi pelo `summary` do run em vez das objeções do Elenxo.

**`triagem-inbox-2026-09.kg.yaml`** — o `confirmed` de topo é
**`E_REGRA_85_E_INSATISFAZIVEL_ANTES_DO_MERGE`** (impact 4), e ele é exatamente a **premissa desta
leva**: a cura que a guarda cobra só existe depois do merge. A decisão selada é a conclusão dele.

**`zoho-glpi-adapters-2026-09.kg.yaml`** — três `confirmed` impact 5, e **dois são objeções que
contradizem a minha síntese**:

| # | achado | o que derrubou |
|---|---|---|
| 5 | **`E_OBJECAO_1_READONLY_NEM_SUFICIENTE_NEM_SEGURO`** — read-only **não é suficiente**: o fórum oficial diz, verbatim, que `actiontime` é *"just one accumulated total, which isn't enough"* e que é **o único campo exportável via REST**; o plugin de timetracking *"doesn't seem to work reliably on GLPI 10.x"*; um **moderador reconhece a lacuna** e diz que o suporte na API nova é *"still a work in progress"*; o workaround real é **dashboard + CSV, não API**. E **não é seguro**: a própria página v2 diz que a legacy *"allows more functionality"*, então cobertura empurra para uma superfície **com escrita** | Eu havia escrito que o GraphQL read-only **qualifica** o GLPI como fonte de atividade. O desenho segue certo; **não está provado que o GLPI entrega o dado** que se quer apurar |
| 6 | **`E_OBJECAO_2_ZOHO_V3_CORTE_DEZ_2025`** — a página lida é **mista** (v2 e v3 juntas) e há superfície **v3 dedicada a status** (`taskstatushistory`) que o achado ignorou; uma fonte tier 4 afirma que as APIs pré-V3 **desapareceram em 31/12/2025**, com 404/410 desde 01/01/2026 — e hoje é **nove meses depois** | Meu `updateStatus` por composição pode estar descrito **sobre a v2 morta**. A primária que fecharia isso está **citada e não lida** |

**Curado:** a SYNTHESIS foi reescrita. A seção "Resposta direta" agora abre declarando que é **menos
confortável** do que a primeira leitura sugeria, os dois achados na tabela levam o selo de estreitado /
sob suspeita, e entrou uma seção **"o que isto muda na ordem de trabalho"**: não se escreve adapter
nenhum antes de duas medições — o GLPI na instância real (existe atividade por período e por pessoa,
ou só o acumulado?) e a primária do Zoho (a v2 responde ou é 404?).

**A classe é a mesma do achado 6 do PR #871**, e é a segunda vez no mesmo dia: **agir pelo `summary`
de uma pesquisa em vez das objeções que ela produziu**. A diferença é que agora a guarda pegou — e é
por isso que a REGRA 87 existe.
