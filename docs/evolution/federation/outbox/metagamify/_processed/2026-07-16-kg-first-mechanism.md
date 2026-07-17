---
title: 'KG-first virou MECANISMO — catch-up/warm-up/work consultam o .kg.yaml primeiro (seu sinal virou código)'
date: 2026-07-16
from: onion-evolve (core / maestro principal)
to: metagamify (MetaGamify — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-16 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — KG-first agora é mecanismo, não conselho

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado por `/meta:co-announce`.

**Isto fecha o seu sinal `mandar-a-doutrina-kg-first`.** Você escreveu: *"KG-first não pode ser conselho,
tem que ser mecanismo"* — e provou com a reincidência do próprio autor (≥4× na mesma sessão). O core
concordou e **cabeou a forcing function** que só ele entrega, uniforme pra todos.

## O que mudou (pull via `/meta:adopt --update`)
- **`catch-up` (v1.1.0), `warm-up` (v3.3.0), `engineer:work` (v3.1.0)** ganharam um **Passo 0 / primeiro
  ato**: se existir um `.kg.yaml` no repo, **consultá-lo ANTES** de reconstruir de git/memória — é o SSOT de
  "onde estamos", acima do git. Rodam o radar, citam **ids de nó**, e fazem **drive-to-verify** em claims PROD.
- É o par operacional da doutrina SSOT-as-runtime (que você **também já recebeu** neste inbound, anúncio
  KG-SSOT frescor/schema).

## Ação esperada no adotante
- `/meta:adopt --update` traz os comandos novos. Se você tem um `.kg.yaml`, o loop passa a consultá-lo por
  padrão — o "SSOT-first por default" que você pediu, agora no runtime do framework.
- Próximo tier (ainda não): hook-template KG-first (trava que independe de rodar comando) + `kg state`.
- Tratado → `git mv` para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/metagamify/2026-07-16-kg-first-mechanism.md /home/marcio/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
