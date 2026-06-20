---
title: 'Fluxo A meia-estrada: --update não auto-emite relatório + "you have mail" só notifica fluxo B'
date: 2026-06-19
from: sessão-core (dogfooding — update do rhilo-metagamify ao vivo)
to: onion-evolve (core)
type: field-signal / framework-gap
severity: medium
flow: A (downstream / distribuição) — gap de entrega + notificação no lado consumidor
status: aberto (proposta abaixo; ação = sessão-core futura)
relates: docs/applying/adoption-lifecycle.md (card 6) · docs/evolution/README.md (linguagem ubíqua, fluxos A/B)
---

# Sinal — o fluxo A (core→consumidor) está meia-estrada: falta entrega + notificação

## Contexto (como emergiu)

Ao fazer o `/meta:adopt --update` do `rhilo-metagamify` ao vivo (sessão do Core dirigindo, source-driven),
dois atritos reais apareceram — ambos do **lado consumidor do fluxo A**:

## Gap 1 — `--update` não auto-emite o relatório no alvo

A cópia rodou do **[Core]** (source-driven; o consumidor `role: adopted` não pode ser a fonte). Mas o
**relatório do que foi feito** (arquivos aplicados, novidades, do que o alvo é capaz agora, próximos passos
= revisar/commit/push) **só saiu no chat do [Core]** — o maestro teve que **re-digitar/repassar à mão** para
a sessão do alvo. Tive que **escrever o relatório manualmente** em
`rhilo-metagamify/.claude/sessions/onion-update-<pin>/REPORT.md` (gitignored) para a sessão do alvo
"receber e fazer de lá".

→ É o **card 6** ("Onion autônomo → **relatório**") que deveria ser **comportamento padrão**: o `--update`
(e a adoção) **auto-emite** o relatório no alvo, num caminho convencionado, ao final.

## Gap 2 — "you have mail" notifica só o fluxo B

O hook `co-evolution-inbox-check.sh` (vendorizado, presente e registrado no metagamify) escaneia **só**
`docs/evolution/inbox/` — o canal de **fluxo B** (consumidor → core). O relatório de update é **fluxo A**
(core → consumidor) e vive fora desse caminho → **não dispara "you have mail"** no alvo. Resultado: entregas
de fluxo A (relatório de `--update`, anúncio novo no `CHANGELOG`) **não têm notificação no lado do consumidor**.
A notificação hoje é **meia-estrada** (só B).

⚠️ **Não** resolver jogando o relatório no `inbox/` de fluxo B do alvo — lá é o *outbox dele pro Core*;
apareceria como se o consumidor estivesse sinalizando o Core. O fluxo A precisa do **próprio** canal/notificação.

## Proposta (decisão do core — não executar sem dono)

1. **`--update`/adoção auto-emitem o relatório** no alvo (caminho convencionado, ex.
   `.claude/sessions/onion-update-<pin>/REPORT.md` ou um `inbound/`), com: arquivos aplicados, novidades,
   capacidades novas, próximos passos.
2. **"You have mail" bidirecional:** o hook (ou um irmão) também anuncia **entregas de fluxo A** no lado
   consumidor (relatório de update pendente / `CHANGELOG` novo desde o pin), **separado** do inbox de fluxo B.
3. Documentar no `adoption-lifecycle.md` (gradua o **card 6**: autônomo→relatório vira real) e na linguagem
   ubíqua (fluxo A ganha notificação).

## Próximo passo

Backlog do core. Casa com o card 6 (🟠 a-desenhar) do concept-map e com a barra de qualidade da adoção.
Achado por dogfooding — "evoluir aqui com a experiência".
