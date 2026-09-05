---
title: 'Receita "colaborador que não aprende Onion": comandos finos /portal:* + guia de 2 páginas'
date: 2026-09-04
from: portal-gamificacao (consumidor)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core)
---

## Contexto
Projeto a dois: dono (maestro) + professor universitário co-autor que vai usar Claude Code no repo e **não deve**
aprender o framework. A skill `onion-onboarding` tem o ramo "colaborador visitante", mas o que faltava era a
**superfície**: o que a pessoa digita.

## O que fizemos
- `AGENTS.md` (CLAUDE.md symlink) projeto-primeiro; Onion citado só num bloco final "para o Claude".
- 4 comandos projeto-locais em `.claude/commands/portal/`: `start` (catch-up + radar + backlog + recados),
  `status`, `contribuir <tema>` (escreve no arquivo da pessoa / proposta ao grafo / objeção a um D_, abre PR),
  `ajuda`; + `selar` para o dono.
- `docs/GUIA-COLABORADOR.md` (instalar, clonar, 4 comandos, onde escrever, ritual, o que NÃO fazer).
- Um escritor por arquivo declarado em tabela; `settings.local.json` sugerido para reduzir prompts.

## Proposta
`/meta:adopt --collaborator-layer` (ou um scaffold na `onion-onboarding`) que gere essa camada com o nome do
projeto — é reutilizável em qualquer adoção com colaborador externo.

---

## Triagem do core — 2026-09-05

**Veredito: BACKLOG GATED, com gatilho nomeado** — no
`I_ADOPT_CAMADA_COLABORADOR` de `docs/onion/graph/fios-abertos.kg.yaml`. A receita é boa e o diagnóstico é
preciso: a `onion-onboarding` tinha o RAMO "colaborador visitante" e não tinha a SUPERFÍCIE — o que a
pessoa digita.

**Por que não `--collaborator-layer` agora:** N=1. Generalizar scaffold a partir de um caso é catedral, e
esta casa aplica `pull-not-push` tambem as PRÓPRIAS recomendacoes. Enquanto isso a sua camada serve de
molde por cópia — que é mais barato e mais honesto que um gerador desenhado no escuro.
**GATILHO: um SEGUNDO adotante pedir a mesma camada** (ou o maestro mandar). Aí o scaffold nasce dos DOIS
casos e o que e variável (nome do projeto, quantos comandos, o que o guia omite) aparece por diferença, não
por adivinhação.

Uma peça da sua receita vale registro separado por ser mais geral que a camada: **um-escritor-por-ARQUIVO
em tabela**. A I3 do core é por REPO; num projeto a dois com escritores simultâneos a granularidade útil é
o arquivo, e vocês descobriram isso no uso.
