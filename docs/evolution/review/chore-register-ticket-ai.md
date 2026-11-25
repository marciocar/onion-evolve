---
branch: chore/register-ticket-ai
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: 739e98b310eb5c89eeacc3ca96308d0903b4b52d7a1e8a76283f3c848640c2c5
reviewed_code_sha256: 349ba9fd55efd4ee74f29a8013be45b4119cbedbf30b582678f6b45fca0bae4a
findings_total: 5
findings_real: 3
findings_blocking: 2
tokens: 0
duration_min: 3
findings_fixed: 3
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "register-reviewer (sonnet, isolado)"
nota: "tokens não chegaram ao condutor (0 = não medido). Revisão isolada encomendada pela sessão do core, que não viu o raciocínio do condutor; curas aplicadas pelo core e medidas pelos próprios gates (members-validate.sh e registry-pins.sh)."
---

# Passada adversarial: `chore/register-ticket-ai`

## O que muda

Uma entrada nova no `docs/evolution/federation/members.yaml`: `ticket-ai`, o TicketAi (SaaS de tickets da Grana.ai),
adotado em modo legacy no PR ticket-ai#1 (25/11), como T2 (`role: consumer`) sob o hub `brain-granaai`, com a sessão
dona `ticket-ai` e a integração na `main` (o Lovable sincroniza a `main`).

## Achados

1. **Bloqueio — esquema inválido (curado).** A 1ª versão usava `role: adopted` (fora do vocabulário), `parent:
   brain-granaai` com papel que não pode pendurar em hub, e faltavam `personality_summary`, `personality_last_sync`,
   `specializations` e `trust.can_correct_to`. O `members-validate.sh` saía rc 1 com 6 erros. Cura: `role: consumer`
   (T2 sob o hub) e os quatro campos. Medido: `members.yaml válido (42 membros)`.
2. **Bloqueio — a catraca não habilitava o merge (curado em parte).** `ops/pr-merge-verified.sh` recusa adotante sem
   `owner_session`. Cura: `owner_session: ticket-ai`. Fica a 2ª trava (limite abaixo).
3. **Real — pin divergente (curado pelo item 1).** `ops/registry-pins.sh --check --only ticket-ai --no-remote` dava
   DIVERGE pelo papel; depois da cura: `79452017f23d` = vivo, `ok`.
4. Não real — varredura de vendor: `ticket-ai`/`ticketai` não aparece no framework; o `name` ficou curto (`ticket-ai`)
   para não virar termo longo. A varredura real (vendor-scrub) não foi rodada pelo revisor: só grep.
5. Não real — exposição: o core é público e a entrada cita o remote privado; há precedente (`granaai`, `brain-granaai`),
   risco baixo.

## Mutantes

Não se aplica: a mudança é um registro de dado, sem código. Os gates que a julgam (`members-validate.sh`,
`registry-pins.sh`) têm bancada própria.

## Limites declarados

- O merge de PRs do ticket-ai pelo core (`--foreign-repo`) ainda recusa: o dono do remote (`marcio-granaai`) não é o
  dono do core. Vale quando o repo for transferido para `marciocar/ticket-ai` (decisão do maestro de 25/11); o
  `remote:` desta entrada muda junto.
