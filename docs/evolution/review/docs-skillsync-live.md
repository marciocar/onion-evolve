---
branch: docs/skillsync-live
pr: 641
date: 2026-08-20
reviewed_diff_sha256: e985c4a73ad148e236707b6e01a459b26025a7a5cc0a501afefc5b5dd5483ac7
findings_total: 3
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 10
verdict: CONFORME-11-DE-11-COM-IDEMPOTENCIA-PROVADA
reviewer: passada adversarial manual (2 ataques re-medindo o vivo); sem subagentes
REVISOU: true
---

# Resíduo — `docs/skillsync-live`

**Origem:** o fechamento da integração #1 — 3 rodadas de dogfood até a cadeia real
(yaml → enabled no painel → rota admin → cron-mecanismo).

## Os 2 ataques (limpos)

- **(a) as skills têm CONTEÚDO, não só nome?** amostra de 3 com instructions em milhares de
  chars — o corpo do SKILL.md viajou, não só o frontmatter.
- **(b) idempotência**: após 3 runs (manual + marcio + root), skills = 11, não 33 — o sync
  faz upsert por identidade, o cron diário não duplica.

## O registro que vale (não é achado)

A cadeia levou 3 correções, todas viraram aresta com genealogia: dormant no v0.8.7 → sem
scheduler nem no rc1 → o gate final era um DEFAULT (github.enabled: off) que só o painel
liga. Nenhuma das 3 estava em doc algum — só o binário sabia. A conta desta jornada:
exploração externa deu o mapa em horas; o campo cobrou 3 vereditos que nenhuma fonte tinha.

## Ressalva declarada

O JWT do skill-sync-run.sh é cunhado com o segredo da casa para o admin `marciocar` — se a
conta trocar de _id, o script quebra fechado (o UID está hardcoded com comentário). E o run
do cron depende do api estar de pé às 05:15; falha vai ao syslog via logger, sem alarme
dedicado (o mesmo teto declarado dos outros crons da casa).
