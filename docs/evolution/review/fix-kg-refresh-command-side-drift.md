---
title: "Revisão — drive m3-federation (C_command_side_gap DRIFTED, C_not_backstage CONFIRMED)"
date: 2026-08-27
branch: fix/kg-refresh-command-side-drift
reviewer: "self-review (drive/verification) + medição executada contra o vivo + radar --integrity"
reviewed_diff_sha256: aa8f4ee069723a350d624732b15c05d4fcec96cf7b5d940f9cdaa370b02282c2
findings_total: 0
findings_real: 0
verdict: APROVADO
tokens: 7000
duration_min: 9
---

# Resíduo — REGRA 56 (passada /meta:drive, degrau AUDIT)

Refresh de KG **dirigido por medição** — não há lógica nova, só o veredito de 4 nós de
`verification` do topo da fila-pronta, medidos contra o vivo. O risco é (a) carimbar sem medir,
(b) flipar status de verdade sem base, (c) quebrar `--integrity`. Os três foram verificados.

## Medição executada (o que roda, não o que se quis dizer)
- **C_command_side_gap → DRIFTED.** `ls .claude/commands/meta/federation-member.md` = existe;
  `adopt.md:632` = "oferecer **rodar** /meta:federation-member register" (não mais "oferecer
  registrar" passivo). A manchete "NENHUMA mutação tem comando" caiu p/ OP-1. `grep -rE
  'federation-member.*(promote|update|revoke)' .claude/commands/meta` = zero → gap PERSISTE p/
  OP-2/3/4. status open→drifted, label refrescada, verified_at carimbado.
- **C_not_backstage → CONFIRMED.** `federation-console.sh:6` ainda declara "NAO e plataforma";
  `grep -cE '^\s*role:\s*consumer' members.yaml` = 0 (premissa N=8 de pé). open→confirmed + verified_at.
- **C_op_update / C_op_promote → medidos CONFIRMED (sem comando, gated) mas MANTIDOS open.**
  São trabalho aberto real (a operação não existe); flipar p/ confirmed sinalizaria fechamento
  falso. Decisão consciente (não é o mesmo que "não medi").

## Invariante respeitada
"O único caminho p/ um verified_at novo passa por medição executada." Só os 2 nós MEDIDOS-e-mudados
receberam carimbo; os gated ficaram open. Nenhum flip para superseded/refuted (esses são selo do
maestro) — `drifted` é a saída legítima do freshness, não um truth-flip.

## Verificação estrutural
`kg-radar --integrity --schema` → **exit 0** (30 nós, 37 arestas, sem contradição). Re-censo:
C_not_backstage saiu da fila (confirmed); C_command_side_gap segue visível (drifted = residual
OP-2/3/4 é trabalho aberto real).

## Achado colateral (registrado, não corrigido aqui)
O comando `/meta:drive` referencia `.claude/utils/session-beacon.sh` (P3 BEACON) que **não existe**
nesse caminho — ponteiro morto. Fora do escopo deste refresh; fica p/ fio próprio.

## Veredito
**APROVADO.** Refresh determinístico por medição, `--integrity` verde, nada flipado sem base.
Degrau AUDIT: conduzido até PR-verde; o merge (e o selo do drift) ficam p/ o maestro em lote.
