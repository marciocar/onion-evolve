---
title: "Radar E3 · rodada 7 — uma versão, e o furo que ela curou no harness estava nos nossos vetos"
date: 2026-10-05
axis: E3-claude-code-delta
baseline_anterior: 2026-10-03 (2.1.288)
baseline_desta_rodada: 2026-10-05 (2.1.289)
kg: docs/evolution/research/radar-E3-2026-10-05-r7/radar-E3-2026-10-05-r7.kg.yaml
run_id: "sem run_id de Workflow — rodada conduzida na sessão principal com 1 juiz subagente (opus, worktree isolada). Declarar a ausência é o contrato."
tokens: 115149   # medidos, do juiz; o custo da sessão principal não é atribuível por run
agents: 1
duration_min: 5
---

# O que esta rodada mediu

**Uma versão**: a `2.1.289` (3 de outubro), 27 itens, contígua com a baseline — conferida pelo juiz
em três fontes (página do changelog, `CHANGELOG.md` do GitHub, `dist-tags` do npm). O bloco está em
`data/2.1.289.txt`, idêntico aos 27 itens da página.

## O que da versão toca a casa — medido

- **Quatro furos em regras deny/ask** (prefixo de variável com valor expandido, atribuição nua antes
  do comando, parte aninhada sob aprovação de mod, Read deny via symlink). O core **não instala**
  deny/ask — mas o `@claude-code-specialist`, que viaja no plugin `onion-engineering`, **recomenda**
  deny rules a adotantes na forma exata do furo. Quem seguiu ficou exposto até a 2.1.288.
- **`claude plugin validate` pulava o plugin** quando a pasta também tinha manifesto de marketplace.
  Nenhuma pasta de plugin daqui (nem do repo público) tem os dois juntos: os "Validation passed"
  anteriores foram validação de verdade.
- **Mods falhavam abertos depois de upgrade** (não carregavam na 1ª sessão) e a aprovação de um mod
  passava por cima de deny/ask — evidência nova para a pergunta da r6 sobre mover guarda para mod.
- `agent.spawn` para teammates e id único entre eventos de hook de plugin — pergunta aberta, com a
  ressalva de que é API de mods, não dos hooks de shell desta casa.

## O achado de maior consequência não é da versão

A 1ª redacao dizia que "a classe que o harness curou não existe no veto próprio". **O juiz
reprovou, e eu reproduzi:** os vetos de merge e push desta casa têm a mesma classe — a lista de
formas barradas é menor que a língua do shell. Escapam, entre outras, `git push origin +main`
(force-push), `git push origin "main"`, `TZ=… bash -c "gh pr merge"`, `timeout 60 gh pr merge`,
`gh -R o/r pr merge`. **O host não protege a `main`** (403, plano sem o recurso): o hook é a única
barreira.

→ Nó `Q_CURAR_OS_VETOS_DE_MERGE_E_PUSH`, **aberto com o gatilho já disparado**. A cura de classe é
julgar a intenção normalizada e falhar fechado no que não se analisa — trabalho de forja, maestro-gated.

## O que o juiz derrubou

2 de 5 nós e o `supersedes_none`, todos por **generalizar além do medido**, nenhum por fato errado:
a classe "fechada" (era só as seis formas testadas), a contiguidade "respondida" (a pergunta da r6
era sobre o mecanismo, que segue sem existir), e contagens de composição que não fechavam (6/2 → 5/3).

## Não verificado

Se a aprovação de um mod passa por cima do **exit 2** de um PreToolUse — é nesse exit 2 que o
CLAUDE.md apoia o acoplamento ao Claude Code. Sem mod instalado para testar; fica no nó aberto.
