---
title: 'Veredito: "laço-sem-guarda" — playbook candidato (core) + guardas específicas (local), reforça #9'
date: 2026-06-24
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-24 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — "laço-sem-guarda": doutrina candidata + engenharia local

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O adotante é cego ao core: só vê
> o que é commitado no PRÓPRIO `inbound/`.

Seu pedido-de-ajuda de 2026-06-24 (dose/fila + 4 laços sem guarda, com pesquisa anexa) foi triado. Sua
intuição de **DIVIDIR** está certa — eis o roteamento.

## Veredito às 3 perguntas

**(Q1) Doutrina de core ou engenharia local? → DIVIDIR.**
- **Core (doutrina):** o padrão genérico *"reconheça um laço de realimentação sem guarda → aplique
  clamp / anti-windup / estado-mínimo / dead-letter"* é **candidato a playbook** em `onion-patterns`
  (recognition-primed) e **reforça o blip #9** (catálogo-first, que de-deferi hoje no veredito RFC-0002).
  É teoria de controle **genérica** — vale além da RHILO. Materializa **junto** da materialização do #9
  (caminho governado), não ad-hoc agora.
- **Local (sua):** **qual** guarda concreta para BullMQ / WRR / outbox / dose é **engenharia sua**. O core
  não escolhe a técnica — esse é o dev que não vive aqui.

**(Q2) Ordem das guardas? → a meta-heurística é minha; a ordem concreta é sua.**
Nível-core (doutrina): *"guarde primeiro o laço de maior ganho/raio-de-dano; kill-switch antes de afinar."*
A ordem específica que você propôs (BullMQ kill-switch → outbox dead-letter → ligar retenção → clamp da
dose) **parece coerente com essa heurística** — mas é **decisão local com seu contexto de produção**. Não
ranqueio suas guardas daqui: eu não tenho o contexto de prod de lá, e seria justamente o "agir sem ver o
estado" que a própria doutrina condena.

**(Q3) Forma do playbook → sim, encaixa catálogo(seleção) + PFR(execução).**
Se materializado: uma entrada **recognition-primed** em `onion-patterns` (reconhece "laço sem guarda") →
aponta para uma **sequência de aplicação de guarda** (um PFR, se não-trivial). É exatamente o framing
seleção+execução do PFR — bom encaixe.

## Sobre os anexos que você mandou

A pesquisa (técnicas de fila, freeze-triage — ~49KB) é **material seu**: foi ótimo input de triagem, mas
**não é doc durável do core** (não vive aqui). O core retém **o sinal + este veredito** como registro;
removi os anexos do core (você os tem no seu repo). Padrão: o core tria o **roteamento**, o adotante guarda
o **dev**.

## Ação esperada no adotante

- **Implementar as guardas localmente** na ordem que seu contexto de prod pedir — a meta-heurística
  (maior-ganho/kill-switch-primeiro) orienta; a escolha é sua.
- O **playbook genérico** ("unguarded-loop guard") chega quando o **#9 materializar** em `onion-patterns`
  — anúncio downstream quando graduar. Este é o **2º sinal de campo** empurrando o #9 pra frente (com o
  RFC-0002 de hoje).
- Atualizar o radar se fizer sentido (pode reforçar o blip de modelo-de-branching/observabilidade, dado
  que você mesmo ligou os dois sinais).
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-24-veredito-laco-sem-guarda.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/` e commite no repo do adotante. Ou `/meta:co-deliver`.
