---
title: "A perna da LEITURA do KG-SSOT — por que read(KG) não dispara na hora da decisão (Elenxo + replay de 9 casos)"
category: research
date: 2026-08-02
status: veredito-nao-construir-com-1-bugfix-derivado
method: "Elenxo orquestrado, 14 workers: 4 lentes de diagnóstico cegas entre si (sonnet/medium) → 3 curas em steelman (sonnet/medium) → 6 refutações adversariais em pipeline, 2 lentes por cura incluindo REPLAY (opus/high) → 1 síntese (opus/high). Achados decisivos re-verificados independentemente pelo maestro-agente."
run_id: wf_38afb1f2-ee7
kg: docs/evolution/research/kg-read-leg-2026-08/kg-read-leg-2026-08.kg.yaml
verified_at: 2026-08-02
source: "medição direta no HEAD 5c6e2cf + docs/knowledge-base/concepts/knowledge-graph-sdaal.md + corpus de 9 falhas documentadas"
---

# A perna da leitura — o que sobreviveu ao replay

> **Projeção do grafo.** SSOT: [`kg-read-leg-2026-08.kg.yaml`](./kg-read-leg-2026-08.kg.yaml) (radar exit 0).

## ⚖️ Veredito: **NÃO CONSTRUIR** nenhuma das três curas

| Caso | Perna | A — seção no `CLAUDE.md` | B — hook `UserPromptSubmit` | C — `kg-radar --grep` |
|---|---|:--:|:--:|:--:|
| C1 WAHA (hoje) | leitura | ✗ | ✗ | ✗ |
| C2 convite Arthur (hoje) | leitura | ✗ | ✗ | ✗ |
| C3 "o que tem aberto?" (hoje) | leitura | ✗ | ✗ | ✗ |
| C4–C6 autor ignora 3× (07-16) | leitura | ✗ | ✗ | ✗ |
| C7 redesenho do WRR | leitura | **✓** | **✓** (condicional) | ✗ |
| C8–C9 (70 agentes / 8 passadas) | **escrita** | ✗ | ✗ | ✗ |
| **TOTAL** | | **1/9** | **1/9** | **0/9** |

O único caso que A e B pegam é **o mesmo** (C7) — logo a **união das três é 1/9**, idêntica à melhor
isolada. Somar as três é somar **superfície, não cobertura**. E o acerto de C7 é frágil nos dois: o que
de fato disparou a consulta na realidade foi **um humano perguntando *"você está fazendo SSOT-first?"*** —
gate social, não instrumento.

As três são, respectivamente: **disciplina em prosa** (A), **disciplina em prosa injetada com mais
frequência** (B), e **ferramenta melhor para um ato que nunca é emitido** (C).

## 🔍 O que o replay refutou — inclusive a minha própria hipótese

**A hipótese-mãe (timing) caiu.** Eu apostei que a trava cobre a abertura da sessão e não o momento da
decisão. O corpus diz o contrário: **C4–C6 aconteceram *minutos* depois de o próprio agente AUTORAR o
grafo**, na mesma sessão, com arquivo e ids no contexto imediato. Distância temporal ≈ 0, saliência
máxima — e falhou **3×**.

> **Se distância 0 falhou três vezes, não há evidência de que distância 1 funcione. Presença ≠ consulta.**

Isso mata a premissa da cura B (*"proximidade do lembrete conserta"*) e enfraquece a de A.

**A descoberta é defeito real, mas não é a causa.** Em **0 de 9** casos alguém consultou e não achou —
**sete são "não consultou"**. A pinça que fecha: em C4–C6 descobrir custava **zero** e a leitura falhou;
em C7 a leitura aconteceu e o **instrumento atual bastou** (corrigiu 4 erros e revelou que metade do
redesenho já existia como nó). *Onde descobrir era grátis, falhou; onde leu, o velho serviu.*
`--grep` é **munição, não gatilho** — e o repo já tem **três nível-4 disponíveis-e-ignorados**.

**A cura A tem contra-prova empírica direta.** A seção *"Dogfood é o padrão master"* entrou no
`CLAUDE.md` em **2026-06-22** — prosa imperativa, mesmo arquivo sempre-carregado. O caso C1 falhou ~6
semanas depois **sob essa seção carregada**. Pior: em C1 o agente **aplicou** outra doutrina em prosa
(os 5 portões, de memória) e **pulou** o grafo. Ele já arbitra entre imperativos concorrentes — e o de
KG perdeu a disputa.

## 🐛 O defeito medido (verificado duas vezes, independentemente)

O glob de descoberta do passo-0 dos três comandos cabeados:

```
ls docs/onion/graph/*.kg.yaml docs/*/graph/*.kg.yaml *.kg.yaml
```

```
enxerga ......... 31 grafos únicos
existem ......... 49 rastreados no git (sem fixtures)
CEGO PARA ....... 18  (36%)
```

`docs/*/graph/` **não alcança** `docs/evolution/research/<tema>/`. Consequência: os grafos que
responderiam **C1** (`waha-adapter-2026-07`, nó `D_dogfood_before_sdaal`) e **C2** (`email-logto-2026-08`,
nós `C_premise_partially_false` / `E_no_invite_acceptance_page`) estão entre os cegos.

> **Mesmo se eu tivesse obedecido perfeitamente ao passo 0 do `/warm-up`, não teria achado.**

⚠️ **Armadilha de contagem:** o glob casa `docs/onion/graph/` em **dois** padrões e **duplica** a saída
(31×2 = 62). A primeira contagem desta própria investigação caiu nela — registrado porque o próximo a
medir vai cair também.

## ✅ O único acionável — e ele **não** é vendido como cura

Trocar o glob hardcoded por resolução **ao vivo**, nos 3 comandos:

```bash
git ls-files '*.kg.yaml' | grep -v '/fixtures/'
```

~1 linha × 3 arquivos. **Zero artefato persistido, zero tabela, zero índice** — portanto imune ao veredito
do spike de guardrails (*"hand-curar tabela DRIFTA"*): não há cópia para envelhecer. Papel **SENSOR ·
advisory**; momento de disparo **inalterado** (deliberadamente não ganha gatilho novo).

**5 portões:** P1 (pull datado) **falha parcial** — não existe pull *"não achei o grafo"*. P2/P3/P4/P5
passam. **Como P1 é parcial, entra como bug-fix, não como promoção de mecanismo.**

## 🗣️ Dissent (preservado, e é forte)

> Consertar o glob é fazer **exatamente o que acabamos de reprovar na cura C**: melhorar um instrumento
> que o corpus mostra que não é invocado. O fix não move o placar — os sete casos de leitura falharam por
> **não-invocação**, e um `git ls-files` correto dentro de um passo 0 que ninguém executa é um botão
> melhor num painel que ninguém aperta. **Risco real: permite declarar vitória sobre um corpus que não
> toca**, fechando o caso sem fechar o buraco.

**Defesa, declaradamente estreita:** não se promove mecanismo, remove-se uma **mentira mecânica**. Uma
trava que declara *"consulte TODOS os `.kg.yaml`"* enquanto enumera 63% deles é **declaração falsa em
produção** — e qualquer cura futura de leitura herda essa cegueira se ela não for removida antes.

## 🎯 O achado que a síntese devolve ao maestro

**A única lente que atravessou o replay intacta não teve candidata no ringue.**

As 4 travas que **pegaram** (REGRA 26/29/43/47) compartilham uma propriedade única: **resíduo material
auditado por terceiro** — script determinístico em CI, **desacoplado do ator que deveria obedecer**. As
três curas do dossiê não produzem resíduo nenhum.

| Gated | Gatilho concreto para reabrir |
|---|---|
| **Cura de RESÍDUO** — decisão de alto impacto sobre tema com grafo carrega `node: <id>` no artefato **durável** (commit/PR/doc), auditado por gate HARD **fora da sessão** (*a sessão não pode ser testemunha de si mesma*) | Derivar **fresca** contra este mesmo corpus; aceite = **replay ≥5/7** na perna de leitura. Restrições: **não** reusar a marca `kg:` (é da REGRA 43, semântica de caminho) nem alegar carona na REGRA 47 |
| **Hook que RODA o radar e INJETA o veredito** (ids + top-atenção) — sem cláusula de mtime, escopo = todos os `.kg.yaml`. **Não é a cura B** | O mesmo padrão fiado **à mão, fresco e descartável, 2–3×** em sessão real, registrando se o veredito injetado **mudou a resposta**. Sem esse dogfood é decreto sem lastro |
| **`kg-radar --grep`** | Um consumidor que dispare sozinho **ou** ≥1 pull datado de descoberta falha — hoje **N=0** |

**Ressalva final, sem eufemismo:** mesmo a cura de resíduo **audita depois** — a decisão errada de C1 já
foi dada. Ela transforma reincidência **invisível** em reincidência **detectável**, que é exatamente o que
curou a perna da escrita 4×. Não promete mais que isso. Para impedir C4–C6 — grafo recém-autorado, no
contexto, ignorado 3× em minutos — **o corpus não oferece candidato barato**, e a KB já disse por quê:

> *"A reincidência É o dado. Não é falha de disciplina do consumidor — é falha de **design do loop**."*
> — [`knowledge-graph-sdaal.md:431`](../../../knowledge-base/concepts/knowledge-graph-sdaal.md)
