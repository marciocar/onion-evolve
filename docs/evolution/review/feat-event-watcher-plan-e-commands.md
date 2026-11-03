---
branch: feat/event-watcher-plan-e-commands
pr: pendente
date: 2026-11-03
reviewed_diff_sha256: c30e0f567d7c75583feb97e7e65ce65c0e97b1dc58eb64ad5483cc5f6051cc1e
reviewed_code_sha256: 80354978edc696d03764cf7d7791d23a716e748ef5075449ff8557aff2f8fed0
findings_total: 78
findings_real: 73
tokens: 0
duration_min: 300
findings_fixed: 71
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "curadoria (dona do PLAN-E): 8 passadas adversariais do Elenxo em agente separado e 4 conferências curtas, mais os julgamentos de semântica; branch APROVADA pela curadoria em 78ee060a6"
nota: "tokens 0 = não medido do lado da revisão (correu na sessão da curadoria, que declarou o custo por passada, de 80 mil a 230 mil tokens); o construtor foi um agente do core."
---

# Passada adversarial: `feat/event-watcher-plan-e-commands`

## O que muda

Os três comandos de medida da escada do vigia de eventos, pelo PLAN-E da curadoria (`event-watcher-2026-10`,
`C_EVENT_WATCHER_PLAN_E` e o Adendo 1 `C_EVENT_WATCHER_PLAN_E_ADDENDUM_1`, curadoria 8a8fe17):
- `ops/a2a-queue-live.sh count --by-day --stage 1|2`;
- o log de sombra do aceite (`a2a-metrics.py shadow-append` / `shadow-stats`, nascendo no `a2a-accept.sh` e no
  `archive --force-unaccepted`);
- o registro de rascunhos (`draft-append` / `draft-stats`, no `a2a-rt-mcp.py` e no `a2a-rt-send.sh`).

As quatro famílias (`a2a_queue_live`, `a2a_accept`, `a2a_rt`, `federation_a2a`) passam 484 de 484, com um mutante
provado por caso novo.

## Achados

Oito passadas, todas REPROVADO_CURÁVEL até a última, com os achados encolhendo a cada uma. Os de maior peso:
- gatilhos de volta calando por padrão e o rc 1 colidindo com exceção;
- a lacuna fechada por qualquer linha;
- o mode_change no futuro descartado em silêncio;
- um remetente apagando o evento de outro;
- a concordância antiga religando o gatilho depois da volta à sombra (pela CLI oficial);
- o escritor e o leitor discordando no mesmo segundo;
- o `--supersedes` sem conferência.

Os julgamentos de semântica são da dona do PLAN-E e estão no Adendo 1 (o log de medida não trava a entrada; o registro de
envio falha fechado; toda recusa do escritor a um produtor oficial vira lacuna).

## Declarados, não curados

- **B2:** a metade `mode_before` do filtro da linha da regra não tem teste próprio; só importa num empate no mesmo
  segundo, que já é ambíguo.
- **B3:** uma lacuna `rule_line_missing` aberta em auto não fecha depois da volta à sombra; segura o rc 2 por até 7 dias
  (conservador).
- **Sem produtor ainda:** a linha da regra em auto, a lista fechada, a chave de corte e o teto de taxa; os gatilhos que
  dependem deles saem null com `trigger_unavailable_reason`.
- **Heartbeat do bridge:** pendência do core antes de qualquer passagem ao degrau 2 (`zero_vs_down: indistinguishable`).

## Mutantes

Um por caso novo, nas quatro famílias (q30 a q53, sh1 a sh67, g1 a g16b).

## Conferências finais (9ª rodada, 2026-11-03)

- **Supersedes sem decisão humana** (b614a3b85): o `--supersedes` é conferido sempre, e o leitor ignora o que aponta
  outro evento. Casos sh73, sh74 e sh75, com mutante. Conferido pela curadoria: passa.
- **Colisão de line_id** (78ee060a6): o id duplicado vira malformado, sai rc 2 com os gatilhos null, e não fecha
  lacuna. Casos sh76 e sh77, com mutante. Conferido pela curadoria: passa, e a branch está aprovada.
- **Baixos declarados**, não curados:
  - o bloco `if dup:` não tem caso próprio; o sh76 o pega porque as duas cópias tiram o log de 50 eventos;
  - um ciclo de supersedes escrito à mão faz o evento sumir calado, o que cai no modelo de ameaça (log editado à
    mão);
  - B2, B3 e B4, que estão no cabeçalho do `a2a-metrics.py`.

## Re-revisão do fechamento (CI)

Depois da aprovação, mudou só a bancada. Os auxiliares `_g`, `_r` e `_rule` do bloco do `a2a_accept` ganharam
prefixo (`_shgapln`, `_shresln`, `_aa_rule`), porque colidiam com nomes usados fora da família e o seletor do
nível PR caía no modo completo, reprovando o `selector-per-file (i)`. Nenhuma asserção ou âncora de mutante mudou.
O REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse) pediu ainda marcar duas citações
de `ops/` como `(core-only)` e trocar uma por descrição genérica, só em comentário e mensagem. Conferido pela sessão
do core: `a2a_accept` e `selector_per_file` passam 208 de 208.
