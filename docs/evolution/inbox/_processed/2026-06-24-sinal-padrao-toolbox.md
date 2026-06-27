---
title: 'Sinal de campo — padrão "toolbox" no Onion: capturar/gerir procedimentos comuns recorrentes'
date: 2026-06-24
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: lacuna entre os `/meta:create-*` isolados e um conceito coeso de "toolbox" (classificar → gerar artefatos coerentes → gerir ciclo de vida)
type: federation-doc-bridge (sinal de campo — não-solicitado)
status: ideia (assess) — proposta de evolução do core, não aplicada localmente
---

# Sinal de campo ao core — padrão para criação e gestão de "toolbox" (2026-06-24)

> Doc-bridge derivado→core. Ideia de evolução do framework nascida de uma sessão de ops real.
> Modo `standalone`: o core consome quando rodar a co-evolução do seu lado (humano-no-loop transporta).

## Problema

O Onion já tem `/meta:create-command`, `/meta:create-skill`, `/meta:create-knowledge-base`,
`/meta:create-agent` — mas são **átomos isolados**. Falta o conceito coeso de **"toolbox"**: dado um
conjunto de **procedimentos comuns recorrentes**, não há um meio de primeira classe para (1) **classificá-los**
nas caixas certas, (2) **gerar os artefatos coerentes entre si** (um command que embrulha um script + a KB
do how-to + a skill da disciplina), e (3) **gerir o ciclo de vida** (inventário, frescor, dedup, promoção).
Hoje cada procedimento é redescoberto e re-derivado a cada sessão, ou codificado ad-hoc sem coesão.

## Evidência desta sessão (ops RHILO/MGFY)

Numa sessão de operação real, executamos repetidamente "procedimentos comuns" que claramente deveriam
ser ferramentas geridas:

- **Dump HML→local seguro:** `pg_dump --exclude-table-data` das tabelas-bloat (`integration_outbox` 10GB,
  todos `*_logs`, `notifications`) — mantendo schema; reduziu o RHILO de **11GB → 49MB**.
- **Guardrail local-only por HOST** (bloquear `amazonaws.com`/`.rhilo.ai`/`:55432`/`sslmode=require`) —
  nasceu de um incidente real de rajada apontada pro HML.
- **Descobrir o DB ativo** que um server serve via `/proc/<pid>/environ` (o `.env` mente após restart).
- **URL-decode de senha + `sslmode=require`** para conectar ao RDS via túnel (falha silenciosa sem isso).
- **Simular chamadas reais** (script `simulate-urano-calls.ts` + flag `--real-rhilo-db`).
- **Aplicar config com snapshot/rollback** antes de mutar (CSV + JSON de rollback).

O dono observou: *"esses procedimentos comuns deveriam fazer parte de alguma lista, caixa de ferramentas"*
— e pediu o critério de classificação para eficiência/eficácia no Onion.

## Critério que destilamos (candidato a doutrina)

Um eixo decide quase tudo — **quem dispara × o que produz × tem efeito colateral**:

| Caixa | Quando |
| --- | --- |
| **Command** (`/meta:create-command`) | operador roda sob demanda, parametrizado, **com efeito colateral** |
| **Script** (`scripts/`) | o **executável** que o command embrulha |
| **Skill** (`/meta:create-skill`) | assistente **auto-aplica como disciplina/segurança**, sem pedir |
| **KB** (`/meta:create-knowledge-base`) | o **como/porquê** narrativo + checklist + gotchas |
| **Memory** | fato/gotcha/decisão **durável e auto-recalled** |

Regra de bolso: *efeito colateral+parametrizado→Command · disciplina silenciosa→Skill · saber→KB · fato
durável→Memory · executável→script embrulhado.* Quando um Command repete passos perigosos, a **segurança
vira Skill** e o **how-to vira KB** — os três se reforçam e nascem coerentes.

## Proposta ao core

Um padrão **"toolbox"** — possivelmente um `/meta:create-toolbox` (ou doutrina + scaffolding) que, dado um
conjunto de procedimentos recorrentes:

1. **Classifica** cada procedimento na caixa certa via o critério acima (efeito colateral × trigger × output).
2. **Gera os artefatos coerentes** entre si — command↔script↔KB↔skill que se referenciam, não átomos soltos.
3. **Gere o ciclo de vida** — inventário da toolbox, frescor (estilo `/meta:kb-freshness`), dedup, e promoção
   (procedimento local vira candidato a doutrina do core quando genérico).

## Por que é DOUTRINA do core, e não comando local

A maioria desses procedimentos (dump seguro, simular) é **específica do RHILO/MGFY** → vira `/rhilo:*` +
KB **local**. Mas o **padrão de capturar/classificar/gerir** procedimentos é **genérico** — todo adotante
o redescobre. Mais: a **disciplina** por trás (ex.: *guardrail "nunca-tocar-prod"*, *snapshot-antes-de-mutar*,
*read-revalidate antes de escrita parcial*) é **doutrina universal**, não comando de um projeto. O lugar
dela é o canônico do core (skill/KB de doutrina + o scaffolding `create-toolbox`), para que o adotante
**herde** em vez de reinventar. É o mesmo princípio dos `/meta:create-*`: o core provê o molde, o adotante
preenche o conteúdo.

## NÃO pedido (deliberado)

- Nenhuma ação obrigatória ao core. Sinal voluntário de um adotante real.
- Os artefatos específicos do RHILO (`/rhilo:hml-snapshot`, `/rhilo:simulate`, `/rhilo:wrr-config`) serão
  codificados **localmente** neste adotante — o que se propõe ao core é só o **padrão/scaffolding + a doutrina**.

## Premissa que o mestre PRECISA internalizar — o adotante é cego (inalterada)

Como nos sinais anteriores: sem comunicação viva, o adotante só "vê" o que for commitado neste `inbox/` E
transportado por humano. **Silêncio do core = invisível.** A resposta a este sinal precisa de anúncio
explícito no `inbound/`.
