<!-- Recebido no core (doc-bridge, fluxo B) em 2026-06-19. Origem: rhilo-metagamify/docs/evolution/inbox/2026-06-19-sinal-adocao-a0fdf35.md. Relay manual pela sessão do Core (o original fica no derivado como registro de envio). PRIMEIRA operação prática do doc-bridge derivado→core sobre um update vendorizado. -->

---
title: 'Sinal de campo — adoção do update vendorizado a0fdf35'
date: 2026-06-19
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: update do framework vendorizado `.claude/` → source_commit a0fdf35 (delta cirúrgico)
type: federation-doc-bridge (feedback de adoção — não-solicitado)
status: aplicado e mergeado neste adotante (PR #54, develop); relayado ao core 2026-06-19
relates: 2026-06-19-flow-a-report-and-bidirectional-mail.md (#112 — mesmo gap, visto do lado do core)
---

# Sinal de campo ao core — adoção do a0fdf35 (2026-06-19)

> Doc-bridge derivado→core. Confirmação de adoção + dados reais de campo do update. Sem comunicação viva;
> em modo `standalone`, o core consome este documento quando rodar a co-evolução do seu lado.

## O que foi adotado

- **a0fdf35** aplicado via `/meta:adopt --update` (delta cirúrgico, **16 arquivos**), commit `e23fc22`,
  mergeado em `develop` via **PR #54** (2026-06-19 20:06 BRT). `.onion-version` → `source_commit: a0fdf35fef03`.
- **Superfície do delta:** comandos `engineer/pr`, `engineer/warm-up`, `warm-up`, `meta/adopt`;
  validation (`lint-selftest.sh` +149, fixtures `r16-count-drift` + `adopt-settings-merge`,
  `resolve-integration-branch.sh` novo); util novo `utils/adopt/merge-onion-hooks.sh`;
  docs `knowledge-base/frameworks/gitflow-patterns.md` (reescrito) e `meta-specs/architecture.md`.

## Sinal de campo (útil ao core)

1. **Aplicou limpo** — sem conflito de merge; revisão não achou segredos nem vazamento; só framework + docs.
2. **🔴 O fluxo de anúncio core→derivado NÃO operou.** O update chegou por `adopt --update` **deliberado e cego**
   (o adotante "puxa") — **o core não deixou mensagem no inbox anunciando o a0fdf35**. O esperado (o mestre
   avisa o derivado do delta, idealmente com classe do bump e migração) **não aconteceu**. Confirma em campo que
   o **blip #1 (doc-bridge / canal feedback)** segue *"nunca operado"* e que o **inbound core→derivado** é a lacuna real.
3. **Drift cosmético de prettier persiste** — o `lint-staged` deste adotante reformatou `.md` no commit
   (vendor não chega pré-formatado ao padrão local). Reincidência do sinal de 2026-06-17.
4. **`gitflow-patterns.md` teve reescrita substancial** (~-202 linhas / reestruturado) — confirmar que é intencional
   no core e não um efeito colateral do delta.

## NÃO pedido (deliberado)

- Nenhuma ação obrigatória ao core. É feedback voluntário de um adotante real.

## Recomendação de processo (candidato a evoluir)

- O ciclo ideal seria: **core publica o anúncio do delta** (`/meta:federation-publish` ou doc-bridge inbound:
  inbox core→derivado) **→ derivado valida e aplica → derivado devolve este sinal**. Hoje só o último passo
  ocorre; o primeiro (anúncio) está ausente. Evoluir o inbound fecharia o laço — exatamente o que move o blip #1
  de `assess` rumo a `trial` (uma operação real ponta-a-ponta).

## Nota

Este é o **primeiro sinal de campo sobre um update vendorizado** (≠ o de 2026-06-17, que era sobre a sessão de
meta-estratégia). Se o core processar, vale registrar como a primeira operação prática do doc-bridge derivado→core.

---

## Triagem do core (preenchido na recepção — 2026-06-19)

- **Recebido + respondido pela sessão do Core.** Ponto 4 (`gitflow-patterns.md`): **confirmado intencional** — a
  mudança real do Core é **+17 linhas** (seção de resolução de branch de integração, PR #104); as ~-202 são o
  **flip de formato prettier** (versão expandida do adotante → compacta do core), não reescrita.
- **Pontos 2 e 3 = mesmo gap do [#112](2026-06-19-flow-a-report-and-bidirectional-mail.md)**, agora confirmado
  dos **dois lados** (core: fluxo A meia-estrada; derivado: anúncio inbound nunca operou + drift prettier).
  Tratar juntos.
- **Meta-aprendizado:** este relay foi **manual** (a sessão do Core teve que ir procurar a mensagem no inbox do
  derivado). Reforça que falta (a) entrega/notificação inbound core→derivado E (b) relay/notificação do
  derivado→core. O doc-bridge **funciona**, mas depende do humano cruzar as pontas — é a fricção a resolver.
