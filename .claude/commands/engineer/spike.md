---
name: spike
description: |
  Spike ou PoC antes de construir: uma pergunta fechada, critério de morte escrito antes da amostra, tempo-caixa,
  o que prova e o que não toca, como desfazer, resultado e próximo degrau. O spike nasce como nó Q_ no grafo do
  projeto, ganha evidence com o resultado e fecha numa decision.
allowed-tools: Read Write Edit Grep Glob Bash(git *) Bash(bash .claude/validation/kg-radar.sh*)
category: engineer
tags: [spike, poc, experiment, timebox, knowledge-graph]
version: "1.0.0"
updated: "2026-11-22"
related_commands:
  - /engineer:plan
  - /product:estimate
  - /meta:peek
  - /onion-research
---

# 🧪 /engineer:spike — responder uma pergunta antes de construir

<arguments>
#$ARGUMENTS
</arguments>

Um spike responde **uma pergunta fechada** («isto é possível? como?») dentro de um **tempo-caixa**, e é
**descartável**: o artefato morre e a lição fica no grafo. Uma PoC é o mesmo objeto com outra pergunta («funciona
ponta a ponta no nosso contexto?»): o molde é o mesmo e muda só o tamanho da caixa. Nenhum dos dois vira MVP sem
passar pelo gate seguinte.

**Por que `engineer:` e não `meta:`:** o spike vem **antes** do `/engineer:plan` em qualquer projeto que usa o
Onion, não na evolução do próprio framework. Por isso ele viaja com a vertical de engenharia. O mesmo comando
atende a pergunta técnica («é possível?») e a hipótese de valor («vale a pena?»); a segunda acrescenta o
avaliador cego.

## O que este comando reusa (não recopia)

- **A escada de promoção** ([`onion-promotion-ladder.md`](../../../docs/knowledge-base/concepts/onion-promotion-ladder.md),
  linha «PoC / spike»): a camada, o grau de certeza e a regra de nunca promover pulando o gate.
- **Spike de hipótese de produto** ([`onion-drive-doctrine.md` §3.1](../../../docs/knowledge-base/concepts/onion-drive-doctrine.md)):
  quando a pergunta é de **valor** («isto vale a pena?»), valem o critério com **denominador fixo** e o
  **avaliador cego**. Este comando aplica as duas regras e não as reescreve. Em uma linha cada, para quem
  instalou só a vertical de engenharia: o denominador do critério (o «de quantos») não muda depois da medida; e
  um agente separado, que não vê a hipótese, marca cada resultado manter ou descartar, porque sobreviver à
  checagem premia a proposta trivial.
- **`/product:estimate`** propõe spike quando a incerteza é alta. É dele que o spike costuma nascer.
- **`/meta:peek`** e **`/onion-research`**: se a pergunta é «como o mercado faz?», ela não é spike. Espie ou pesquise.

## Procedimento

1. **KG primeiro.** Ache o grafo do projeto (`git ls-files '*.kg.yaml'`) e o nó da funcionalidade que o spike
   destrava. Sem grafo no repo, a ficha vai para `.claude/sessions/<feature>/spike-<slug>.md`, com os mesmos
   campos.
2. **Feche a pergunta.** Uma só, com resposta sim/não ou «como». Se saírem duas, são dois spikes. Se a resposta
   depende de opinião de mercado, vá para o `/meta:peek`.
3. **Preencha a ficha** (abaixo) e grave a pergunta como nó `Q_` com os campos `x_spike_*`.
   **Faça o commit ANTES de colher a amostra.** A ordem fica verificável no `git log`: critério antes do
   resultado. Trocar o critério ou o denominador depois de medir é mover a régua. Se o merge for por squash, a
   prova da ordem fica nos commits do PR: cite o sha do commit do critério na `evidence`. Ensaio da FORMA da
   ficha antes do commit vale; colher a amostra que o critério julga, não.
4. **Rode dentro da caixa**, numa pasta descartável fora do produto (`x_spike_workdir`). Não toque no que a
   ficha diz que não toca.
5. **Estourou o tempo?** «Não respondeu no tempo» também é resultado. Registre-o e decida: matar ou abrir um
   spike novo, com pergunta menor. Nunca estique a caixa em silêncio.
6. **Registre o resultado** como nó `evidence` (o que mediu, com o comando), a escolha como nó `decision` (o
   próximo degrau) e feche a pergunta (`status: done`). Spike com agente ou LLM declara o custo pelo contrato da
   casa: `run_id` · `tokens` · `agents` · `duration_min`.
7. **Valide o grafo:** `bash .claude/validation/kg-radar.sh <grafo> --integrity --schema` tem de sair **exit 0**.
   O nó `Q_` precisa de aresta para o nó que ele destrava já no commit 1: pergunta solta é nó órfão, e o radar
   a reprova. Depois do resultado, as arestas da `evidence` e da `decision` escondem a falta dessa aresta, e o
   radar não a cobra mais: confira-a você. O `label` fica em até 280 caracteres, e o resto vai para `narrative`: o contrato do grafo reprova o
   label longo (onde o verificador do contrato estiver instalado; o radar não mede o tamanho). As duas regras
   saíram do spike de prova deste molde.
8. **Descarte ou promova.** Critério de morte disparado leva só a `discard`: a pasta do spike morre e a lição
   fica no grafo. Se a lição pede outra tentativa, ela é um spike NOVO, com `Q_` novo e critério commitado antes;
   nunca uma 2ª amostra do mesmo spike. Sem o critério disparado: `poc` abre um spike novo com pergunta de PoC, e
   `slice` segue para o `/engineer:plan` com a lição citada pelo id do nó.

## A ficha do spike

```markdown
# Spike: <slug>

- **Pergunta fechada:** <uma só, com resposta sim/não ou "como">
- **Destrava:** <nó ou funcionalidade que depende da resposta>
- **Critério de morte** (escrito antes da amostra, com denominador fixo): <morre se ...>
- **Critério de sucesso:** <passa se ...>
- **Avaliador cego** (só em hipótese de valor): <agente separado que não vê a hipótese e marca manter ou descartar>
- **Tempo-caixa:** <horas, não dias> · **prazo:** <AAAA-MM-DD>
- **Prova:** <o que o resultado mostra>
- **Não toca:** <produção, dados reais, repos, serviços que ficam fora>
- **Pasta descartável:** <onde mora o código do spike, fora do produto>
- **Como desfazer:** <passos para apagar sem resto>

## Resultado (depois da amostra)

- **Respondeu?** sim | não | não no tempo
- **Evidência:** <o que foi medido, com o comando ou o trecho>
- **Custo:** run_id · tokens · agents · duration_min (quando houve agente ou LLM)
- **Próximo degrau:** discard | poc | slice, e por quê
```

## A forma no grafo

A pergunta nasce no commit 1. O resultado e a decisão chegam no commit 2, e a pergunta passa a `done`.
Campos `x_` são extensão aceita pelo contrato do grafo.

```yaml
nodes:
  - id: Q_SPIKE_<SLUG>_<MMDD>          # commit 1, antes da amostra
    node_type: question
    status: open                       # vira done no commit 2
    label: "<a pergunta fechada>"
    x_spike_kill: "<morre se ...; denominador fixo>"
    x_spike_success: "<passa se ...>"
    x_spike_timebox: "4h"
    x_spike_deadline: "AAAA-MM-DD"
    x_spike_proves: "<o que prova>"
    x_spike_untouched: "<o que não toca>"
    x_spike_undo: "<como desfazer>"
    x_spike_workdir: "<pasta descartável, fora do produto>"
  - id: E_SPIKE_<SLUG>_<MMDD>          # commit 2
    node_type: evidence
    status: confirmed
    label: "<o resultado, com o número>"
    trace: "<o comando que mediu>"
    x_spike_answered: "yes"            # yes | no | timeout
    x_spike_cost: "run_id=<...> tokens=<...> agents=<...> duration_min=<...>"
  - id: D_SPIKE_<SLUG>_<MMDD>          # commit 2
    node_type: decision
    status: confirmed
    label: "<o próximo degrau e por quê>"
    x_spike_next: slice                # discard | poc | slice; critério de morte disparado = discard
edges:
  - from: <nó que o spike destrava>    # commit 1: sem esta aresta a pergunta é nó órfão
    to: Q_SPIKE_<SLUG>_<MMDD>
    edge_type: DEPENDS_ON
  - from: E_SPIKE_<SLUG>_<MMDD>
    to: Q_SPIKE_<SLUG>_<MMDD>
    edge_type: TRACES_TO
  - from: E_SPIKE_<SLUG>_<MMDD>
    to: D_SPIKE_<SLUG>_<MMDD>
    edge_type: SUPPORTS
  - from: D_SPIKE_<SLUG>_<MMDD>
    to: Q_SPIKE_<SLUG>_<MMDD>
    edge_type: TRACES_TO
```

O bloco mostra só os campos do spike. Os campos de todo nó (`layer`, `plane`, `impact`, `confidence`,
`verified_at`, `verified_against`, `provenance`) seguem o contrato do grafo. No core, o primeiro spike deste molde está no grafo
`spike-standard-2026-11`, validado pelo radar e pelo contrato.

## O que este comando NÃO faz

- **Não pesquisa mercado.** Pergunta de mercado vai para o `/meta:peek` ou o `/onion-research`.
- **Não promove.** O spike verde não é MVP. A promoção passa pelo `/engineer:plan` e pelo gate da escada.
- **Não mede a ordem por você.** A regra «critério antes da amostra» fica no `git log`, e hoje nada a reprova.
  Os valores dos campos `x_spike_*` também não são conferidos por juiz nenhum. O medidor da ordem, do prazo
  vencido e dos campos fica para quando houver spikes registrados para medir.
- **Não guarda o código do spike** no produto. A pasta é descartável; o que fica é o grafo.
