---
branch: docs/wrap-and-spike-status
pr: pendente
date: 2026-10-25
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (onion-evolve-bd), passada própria sobre o diff
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `docs/wrap-and-spike-status`

## O que muda

Só comentário e frontmatter. Nenhuma linha de código muda.

- `.claude/utils/guardrails/onion-untrusted-wrap.sh`: o cabeçalho deixa de dizer "PROTÓTIPO isolado. NÃO é o
  core". Agora diz que o script entrou no core em 2026-07-19 (13275e56) e que, desde 2026-10-15 (e97fe410), o
  a2a-accept.sh o exige.
- `.claude/validation/guardrails/onion-effect-gate.sh`: o mesmo ajuste. O cabeçalho cita quem manda classificar
  por ele: o /meta:adopt, o /docs:reverse-consolidate e o fragmento untrusted-content-provenance.
- `SPIKE-PROTOCOL.md` do spike a2a-cross-user: o `status:` guarda o que valia em 2026-10-14 e acrescenta o que
  rodou depois:
  - a ida A1 em produção (`E_A1_IDA_ENTRE_USUARIOS_DO_SO_EM_PRODUCAO_1021`);
  - a volta A7-C1 com o veredito AGIU (`E_A7C1_R1_R2_VOLTA_OK_E_AGIU_POR_BASH_COMPOSTO_1022`);
  - o A8, que não rodou.

## Achados

1. REAL, corrigido: a 1ª versão corrigia só o wrap, mas o effect-gate tinha o mesmo cabeçalho falso. O grep pela
   frase achou o segundo arquivo.

## Mutantes

- Nenhum: a mudança não toca comportamento. Os ids citados no `status:` existem no grafo do spike, conferido por
  grep no `a2a-cross-user-spike-2026-10.kg.yaml`.

## Limites declarados

- O pré-registro não muda: os critérios do §6 e a tabela do §7 ficam como estavam. Só o campo de estado é
  atualizado, e ele aponta o grafo como lugar do resultado.
