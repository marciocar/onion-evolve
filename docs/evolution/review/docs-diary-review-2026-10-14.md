---
branch: docs/diary-review-2026-10-14
date: 2026-10-14
reviewed_diff_sha256: 15c751c313c5d9caafaa8b0321cc1d75e58a08322880ef29b9d8a44859553a4e
reviewed_code_sha256: d38dde541e39171ea38f14adc8a695f8936bf45fa36da5bb26f827419e9d7542
findings_total: 16
findings_real: 16
findings_fixed: 15
tokens: 0
duration_min: 45
verdict: REPROVADO_E_CURADO
reviewer: protocolo review do /meta:diary (subagente do core, re-teste por conflict_class contra o vivo)
---

# Passada — `docs/diary-review-2026-10-14`

Re-teste das **29 migalhas** com `review_after` < 2026-10-14, a mesma contagem do hook ⏰. Segui o
protocolo `review` do `/meta:diary` sem re-carimbar nada sem re-teste. Cada migalha foi medida contra o
vivo pela sua `conflict_class` (as 29 têm a classe): `dynamic` → rodei o artefato; `static` → confrontei a
melhor fonte atual; `conditional` → chequei só o `valid_when`. A maior parte das execuções foi das
famílias da bancada: `lint-selftest.sh --families …`, em dois lotes, 138/138 e 75/75 ✓, todas reagindo.
Também rodei `kg-radar.sh` sobre o grafo de um adotante, uma sonda de DNS e HTTP do site, o estado do
socket SSH e um modo de falha do `bootstrap-new-project.sh`.

## Contagem por veredito

| Veredito | n | Tratamento |
|---|---|---|
| Válida | 16 | `review_after` → 2027-01-12 + 1 linha `## Re-testada em 2026-10-14:` com a medição |
| Parcial | 11 | Evidence (e, onde estava errado, Signal/Next crumb) reescritos com o estado atual + `review_after` → 2027-01-12 |
| Inválida | 2 | `superseded: true` no frontmatter + nota do porquê (nada apagado) |

Achados reais = 13 migalhas que não estavam mais certas (11 parciais + 2 inválidas), todas curadas nesta
branch, + 2 defeitos de maquinaria (abaixo), NÃO curados aqui por estarem fora do escopo autorizado.

## Inválidas (nomeadas)

- `2026-07-05-vps-lineage-odyssey`: o `valid_when` (a srv1475924 hospeda core, bridge e site) caiu.
  Tudo está na KVM 8 (DNS → 179.197.65.94, `onion-vps-bridge.service` local, `vps-bridge` com
  `status: retired`). Quem a supera é `2026-07-08-site-consolidation-kvm8`.
- `2026-07-15-kg-audit-layer-generalizes-to-content`: o `valid_when` caiu. A KB
  `knowledge-graph-sdaal.md` documenta o content-audit (l.140-147). O re-teste de 07-16 já a dava como
  resolvida, mas sem gravar `superseded: true`.

## Parciais (o que mudou no vivo)

`federation-usage-modes-decision` (2 das 3 pendências fechadas na RFC-0003) ·
`declared-vs-verified-family` (a família tem 7 membros) · `intelligent-breadcrumbs-research` (enabler
entregue; LLM-como-VM superada em 10-05) · `site-consolidation-kvm8` (a unit agora é
`onion-vps-bridge.service`) · `layer1-role-scoped-plugins` (marketplace PÚBLICO, 5 plugins, bundle nasce
na publicação) · `adopt-vendor-branch-merge` (pendência do legado curada) ·
`federation-redesign-rfc0004-shipped` (F2.2 fechada; emenda de 10-14 aberta) · `first-live-a2a-handshake`
e `first-regulated-a2a-handshake` (formato de julho vetado desde `f9d9f939`) ·
`knowledge-centric-reframe-and-north-star` (NS1 decidida em 08-06; `Q_COLD_ADOPTER` aberto) ·
`create-vertical-f2-fino-delega` (F3 fechada em 07-30).

## Sem re-teste completo (declarado)

Todas as 29 tiveram re-teste. Três têm um item que ficou NÃO medido, e cada migalha diz qual:
- `ssh-alt-port-2222`: o lado do notebook do maestro (a rede ainda filtra a 22?) só se mede de lá.
- `first-regulated-a2a-handshake`: o estado da branch remetente no repo regulado da granaai, que não li por git.
- `sovereign-lazy-triggers-research` e `intelligent-breadcrumbs-research`: os números externos (Routines,
  LongMemEval-V2, MemConflict) não foram re-medidos. O STALE foi re-confirmado por busca externa.

## Defeitos de maquinaria achados (NÃO curados — fora do escopo desta branch)

1. `diary-index.sh` não lê `superseded:`: depois de regenerar, o índice segue marcando as 2 inválidas
   como ⏰ stale ("2 stale").
2. `count_overdue_diary()` em `.claude/hooks/co-evolution-inbox-check.sh` também ignora `superseded:`,
   então o hook vai contar ⏰ 2 para sempre. Este é o 1º uso de `superseded: true` no diário, por isso
   ninguém tinha visto. A cura natural: as duas leituras pularem `superseded: true`.

Os vereditos acima são **propostas**. O protocolo exige confirmação do maestro na absorção, e esta
passada rodou como subagente, sem esse gate.

## Vereditos confirmados pelo maestro (2026-10-14)

O protocolo exige a confirmação na absorção (passo 3 do `review`). A sessão principal perguntou pelo
`AskUserQuestion` e o maestro escolheu **absorver os 29** (16 válidas, 11 parciais, 2 superadas).

## Cura: a migalha superada não vence mais

O re-teste produziu as duas primeiras `superseded: true` do diário, e nem o `diary-index.sh` nem o
`count_overdue_diary()` do hook SessionStart liam o campo: o ⏰ as contaria para sempre. Os dois passam a
pular a migalha com `superseded: true` no frontmatter. Caso (i) da família `diary_crumbs`: uma superada e
uma vencida comum → índice "1 stale" e hook 1. Mutante (as duas leituras antigas): o caso reprova com
"2 stale" e hook 2. Depois da cura, o diário real dá 0 vencidas no índice e no hook.

## Rodada 1 do CI: a guarda de âncora morta só olhava `.claude/validation/`

O caso (i) extrai `count_overdue_diary` do hook SessionStart por `sed -n '/^count_overdue_diary()/…'`, e a guarda
(0) da família `selftest_lanes` só procurava o símbolo em `.claude/validation/*.sh`: acusou âncora morta de um
símbolo vivo. Real, curado: o pote inclui `.claude/hooks/*.sh`. As duas famílias passam; mutante (âncora
inexistente) segue reprovando.
