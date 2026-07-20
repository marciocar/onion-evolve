---
title: 'Duas guardas candidatas ao kg-radar — idioma dos ids e colisão de campo dentro do label (ambas me pegaram hoje)'
date: 2026-07-19
from: sessão da estrela discuss/onion-pessoal-app (companheiro de vida, na VPS)
to: onion-evolve (core / sessão de doutrinas de KG)
type: doctrine-candidate (co-evolução, fluxo upstream)
status: novo — triagem pendente (/meta:co-evolve)
re: kg-radar.sh (gramática e guardas) · knowledge-graph-sdaal.md · language-standards / code-standards
---

# Sinal: duas lacunas do KG que só aparecem quando alguém escreve muito grafo num dia

> **Por que este sinal vale:** as duas foram descobertas **do jeito certo — errando em campo**, não teorizando.
> Escrevi ~30 nós de KG hoje (estrela + frontend do app) e bati nas duas. Uma delas eu **pushei quebrada**.
> Nenhuma é erro exclusivo meu: são pontos onde a gramática permite o engano em silêncio. O maestro foi
> direto ao ponto: *"isso tem que estar na doutrina desde o source"* — não consertado local, prevenido na origem.

## Guarda A — o label pode corromper o próprio nó (MECANIZÁVEL, e a mais grave)

**O que aconteceu.** Escrevi um label descrevendo a própria gramática:

```yaml
    label: "... 66 nós, TODOS layer:audit, ZERO domain ..."
```

O parser do `kg-radar.sh` é **line-based** e não tem noção de *"dentro de string"*: a linha casou
`^[[:space:]]*...layer:` e o **conteúdo virou configuração**. Resultado:

```
✗ Q_FRONTEND_MAP: layer inválido: [domain; (2) TRACES_TO nós→artefatos reais; ...]
```

Radar exit 1, grafo quebrado, **e eu já tinha pushado**. O commit seguinte foi só o fix.

**Por que importa mais do que parece:** o KG que mais fala sobre o schema é justamente o **KG que documenta o
KG** — os grafos do core, as KBs, os sinais de doutrina. É a classe de conteúdo com maior chance de se
auto-corromper, e é a mais valiosa. Já vi o `kg-radar.sh` se proteger disso em outro ponto (o comentário na
linha ~92 sobre `trace:` diz explicitamente que um match solto casaria com label que cita `trace:`) — ou seja,
**a armadilha já é conhecida para um campo, mas não para os outros**.

**Proposta:** estender essa mesma defesa aos demais campos. Duas opções (o core escolhe):
1. **Guarda de detecção** (barata): ao ler um `label:`, avisar/reprovar se o valor contém
   `\b(layer|node_type|plane|status|impact|confidence|trace|edge_type):` — porque o parser **vai** ler errado.
   Mensagem honesta: *"este label contém um token que este parser interpreta como campo"*.
2. **Ancorar todos os campos** como já foi feito com `trace:` (só casar em posição de campo), o que remove a
   classe inteira em vez de avisar sobre ela. Mais correto, um pouco mais de trabalho.

Nós preferimos a (2) com a (1) como rede — mas quem manda na gramática é o core.

## Guarda B — idioma dos ids não está escrito em lugar nenhum (CONVENÇÃO, mecanização parcial)

**O que aconteceu.** Meus ids derivaram para português — `S_PRONTO`, `E_RESPOSTA`, `EV_ENVIAR` — e num caso
**misturei dentro do mesmo identificador**: `EV_GATE_REPROVA`. Indefensável, e passei batido até o maestro ver.

**A regra existe, mas não onde se escreve grafo.** `language-standards`/`code-standards` dizem *"código,
variáveis, funções, nomes: inglês; prosa: pt-BR"*, e os grafos do próprio core obedecem
(`E_STAR_CAUGHT_ITSELF`, `D_ORIGIN_SOT`, `Q_MEMORY_COEXIST`). Mas **a doutrina do KG e o schema não dizem
nada** sobre isso — quem está escrevendo um `.kg.yaml` não tem o lembrete no lugar onde erra.

**O custo real não é estético.** Quebrou o **contrato entre artefatos**: o `atom-map.md` dizia `E_REPLY`/
`E_PHOTO` enquanto o `.kg.yaml` dizia `E_RESPOSTA`/`E_FOTO` — dois artefatos do mesmo contrato discordando do
nome do mesmo átomo, exatamente o que o par doc↔grafo existe para evitar.

**Proposta:** uma linha normativa na seção de schema do `knowledge-graph-sdaal.md` (**ids em inglês; labels em
pt-BR**) — é onde a pessoa está olhando quando erra. Mecanizar é parcial: detectar idioma é frágil, mas uma
lista pequena de tokens pt-BR frequentes em ids (`ERRO`, `ENVIAR`, `RESPOSTA`, `PRONTO`, `FOTO`, `TURNO`…)
pegaria a maioria dos casos como **aviso**, não reprovação. Honestidade sobre o limite: isto é convenção
com rede, não gate.

## Contexto de onde isso saiu

Fechamos hoje o PFR `/meta:kg map` do frontend do app (F0 inventário → F1 atom-map → F2 camada `domain` →
F3 radar `--domain` verde 5/5 → F4 `SourceTag` + invariante de fonte-única grep-verificável, exit 0). O mapa
achou três violações reais, uma delas uma **UI que mentia** sobre a própria memória e que **11 provas verdes
não pegaram**. A doutrina do map funcionou exatamente como prometido — por isso vale endurecer as bordas por
onde ela deixa passar.

**Pedido:** avaliar as duas guardas. A **A** nos custou um push quebrado e é mecanizável hoje; a **B** é
uma linha de doutrina no lugar certo.
