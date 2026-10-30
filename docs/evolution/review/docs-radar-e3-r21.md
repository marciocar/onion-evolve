---
branch: docs/radar-e3-r21
pr: pendente
date: 2026-10-30
reviewed_diff_sha256: 5f94b88f39e3915441e473f084ec0feb245c837d85183a527b3c3235e26f6753
reviewed_code_sha256: 5e7f030804a7a21349bf668f54665d2d4644cc4ed0f374b22763fde771714327
findings_total: 6
findings_real: 6
tokens: 194427
duration_min: 55
findings_fixed: 6
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente general-purpose opus independente (não-fork, effort high), mandato REFUTAR"
nota: "tokens = só o juiz (medidos pelo harness); os da rodada não ficaram expostos. Os 6 achados são 1 EXAGERA (a pergunta da subida do SDK) e 5 REPROVA (2 superações da r20 que faltavam, 3 omissões). A pergunta foi reescrita; as 2 superações viraram nós novos com SUPERSEDES; as 3 omissões foram absorvidas em nós existentes; cada superação virou nó C_SUPERACAO_20261030_*"
---

# Passada adversarial: `docs/radar-e3-r21`

## O que muda

- Rodada 21 do radar do Claude Code. O PR traz:
  - o grafo `radar-E3-2026-10-30-r21.kg.yaml`, com 25 nós;
  - `data/2.1.314.txt` e `data/judge-verdicts.json`;
  - a `SYNTHESIS.md`;
  - a baseline do E3 em `docs/onion/radar-baselines.yaml`.

## Achados

1. EXAGERA: a pergunta da subida do SDK do bridge dava a linha 36 (`--setting-sources`) como razão além da paridade. Lido
   como a conta do serviço, o /chat não tem settings excluído para vazar. A pergunta foi reescrita e o nó baixou para
   impacto 1.
2. REPROVA: o nó do nome de comando da r20 dizia que a correção não chegava ao revisor (2.1.311), e hoje o revisor está na
   2.1.314. Virou nó novo, com SUPERSEDES.
3. REPROVA: o nó do `core.hooksPath` absoluto da r20 não foi re-medido. Hoje o valor é relativo, e nenhuma worktree de
   agente nasceu sob a 2.1.314. Virou nó novo, com SUPERSEDES; se o valor ainda é regravado fica NÃO-VERIFICADO.
4. Omissão: na linha 25, a superfície medida da disputa do index lock é a bancada (`_archive_staged`). Absorvida no nó.
5. Omissão: na linha 35, o PostToolUse que casa Bash não roda no Monitor. Re-medido ao vivo e absorvido no nó do Monitor e
   na pergunta.
6. Omissão: na linha 62, o /chat é host stream-json no CLI 2.1.310. Absorvida como razão candidata na pergunta.

## Mutantes

- **Sonda ao vivo, pela rodada e pelo juiz:** o mesmo comando inofensivo (um `.env` num diretório inexistente) pelo Bash e
  pelo Monitor. Os dois foram barrados pelo env-guard.
- **Sonda do juiz direto no hook:** com `tool_name` Monitor o hook sai 0, com Bash sai 2. Logo o harness entrega o comando
  do Monitor como Bash.
- **CU1:** o juiz fez `cmp` da cópia contra o CHANGELOG baixado, sem diferença.
- **`cited_directive` no host com 2.1.314:** rc 0, 6/0/0.
- **`judge-verdict-check.sh`:** 27 vereditos, 6 negativos, todos com critério e superação, 0 recusados.

## Limites declarados

- **Nada foi subido.** O SDK do bridge fica para a SAC-262 (subir o SDK do bridge para 0.3.314), que é deploy do maestro
  num repo alheio.
- **Só os tokens do juiz foram medidos.** Os da rodada não.
- **Efeitos não reproduzidos:** as linhas 25 e 62 e a regravação do `core.hooksPath` estão nos NÃO-VERIFICADOS da
  SYNTHESIS.
