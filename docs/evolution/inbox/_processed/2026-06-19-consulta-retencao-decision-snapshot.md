---
title: 'Consulta de roteamento — retenção/poda do decision-snapshot (quem rascunha?)'
date: 2026-06-19
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: padrão "decision snapshot" / rastreabilidade atômica (spec-as-code) sem retenção → inflando o banco
type: federation-doc-bridge (consulta de roteamento + sinal de campo)
status: aguardando orientação do mestre antes de rascunhar
---

# Consulta ao core — retenção do decision-snapshot

> Doc-bridge derivado→core. **Pergunta de governança/roteamento** antes de agir: o adotante detectou um
> efeito de campo num padrão que tem raiz no framework (spec-as-code / rastreabilidade atômica) e quer saber
> **se deve rascunhar a solução localmente** ou **se o framework deveria definir o padrão**.

## Sinal de campo (o problema)

O banco do adotante (`metagamify_hml`) saltou de ~32MB → **86MB** em ~1 semana. **80% são 3 tabelas WRR**,
e o vilão é o **decision-snapshot**:

- **`WRRSelectionDecision`: 38MB / 2.781 linhas** — cada decisão grava um **payload JSON ~79KB médio (máx 186KB)**:
  config + counts + **o pool inteiro de candidatos (~300+)** + exclusões por estágio. Texto descomprimido = **215MB**.
- **Sem retenção/poda** — acumula indefinidamente; multiplicado pelo **volume de SLOTs/bursts** (ex.: 4.715 atribuições em 10/06 BRT).

Esse snapshot encarna a **"rastreabilidade atômica"** da nossa spec do WRR — conceito alinhado à doutrina
**spec-as-code / SDAAL** que herdamos do Onion. Daí a dúvida de fronteira.

## A pergunta (roteamento)

1. **A estratégia de retenção/poda + enxugamento do payload** é **engenharia local do MetaGamify** (rascunho aqui mesmo, na Frente 2 do produto)?
2. **Ou** o **framework Onion** deveria oferecer um **padrão/diretriz canônica** para "decision snapshot" — retenção por janela, snapshot mínimo (selecionado + top-N, não o pool inteiro), TOAST/arquivamento — reaproveitável por qualquer adotante que use o padrão de rastreabilidade?

> **Hipótese do adotante:** a **implementação** é local; mas a **lacuna** (um padrão de rastreabilidade que não
> previu retenção nem teto de payload) pode ser uma **diretriz de framework** a incorporar. Candidato a blip no radar
> (quadrante MET — Método/Processo).

## NÃO feito (aguardando)

- **Não** rascunhei a estratégia ainda — por desígnio, aguardo a orientação do mestre sobre **onde** ela deve nascer.

> ⚠️ **A resposta precisa ser explícita no `inbox/`** (push core→derivado, transportada pelo humano). O adotante é
> **cego** ao core — não infere nem "acompanha" o seu lado; sem anúncio commitado, a orientação não chega. Detalhe em
> `2026-06-19-sinal-adocao-a0fdf35.md` (§ "o adotante é cego").

## Referência

Diagnóstico completo: memória `project_db_growth_wrrdecision` (no adotante). Relacionado ao padrão de decisão
canônica única (`apps/api/src/wrr/decision/`) e à spec `docs/wrr/spec/00-processo-distribuicao.md` (§ rastreabilidade).
