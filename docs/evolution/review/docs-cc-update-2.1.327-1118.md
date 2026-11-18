---
branch: docs/cc-update-2.1.327-1118
pr: pendente
date: 2026-11-18
reviewed_diff_sha256: 45c7ce46508712b72eec6bdc2bb0a279860ad582efeef981422700d8b0428b0a
reviewed_code_sha256: 3ba6c1783089ca07f1ac2a1d26a50a09ecd437aa4ee4bafa114e68c81b7a465b
findings_total: 10
findings_real: 10
tokens: 191039
duration_min: 13
findings_fixed: 10
verdict: FIXED
elenxo: true
reviewer: "subagente general-purpose opus independente (não-fork, effort high), mandato REFUTAR, critérios pré-registrados CU1 a CU7"
nota: "tokens = só o juiz (medidos pelo harness). Os 10 achados são 4 vereditos EXAGERA sobre nós e 6 omissões. Os 4 nós foram reescritos com a superação de cada um (C_SUPERACAO_20261118_*); das omissões, 3 viraram nó com a medida do juiz, 1 virou risco nomeado na pergunta da subida do SDK e 2 foram para NÃO-VERIFICADOS na SYNTHESIS"
---

# Passada adversarial: `docs/cc-update-2.1.327-1118`

## O que muda

- Rodada 25 do radar do Claude Code (2.1.322 → 2.1.327): grafo `radar-E3-2026-11-18-r25.kg.yaml` (23 nós),
  `data/2.1.323.txt` a `data/2.1.327.txt`, `data/judge-verdicts.json`, `SYNTHESIS.md` e a baseline do E3 em
  `docs/onion/radar-baselines.yaml`.

## Achados

1. EXAGERA: o `ask` de hook recusado em bypass no `-p` já valia na 2.1.322 e na 2.1.325. O nó foi reescrito
   como invariante, sem atribuir a causa ao item 2.1.326 l.313.
2. EXAGERA: o freio de cerca de 20 mensagens entre sessões era de volume, não de autoria. O nó foi reescrito com
   os vetos por alvo e os dois leitores da origem.
3. EXAGERA: a recusa do agente isolado mira o sufixo `; echo rc=$?` e já existia na 2.1.322. O nó e a pergunta
   foram reescritos (SAC-434).
4. EXAGERA: a pergunta do delta fechava com omissões e citava uma SYNTHESIS que ainda não existia. Fecha agora com
   as omissões medidas ou declaradas.
5. Omissão: a sonda do `agent_id` da guarda de espera em fundo. Medida verde pelo juiz e transformada em nó.
6. Omissão: a bancada do `permissions.deny` na 2.1.327 (340 casos, 0 divergentes). Virou nó.
7. Omissão: hook PreToolUse que sai 127 (2.1.326 l.251). Virou nó: falha aberto sem `onFailure: block`.
8. Omissão: recusas sem quem responda no revisor e no bridge depois da subida. Virou risco nomeado na pergunta da
   subida (SAC-432).
9. Omissão: subagente retomado por mensagem de irmão (2.1.327 l.145). Foi para NÃO-VERIFICADOS.
10. Omissão: pasta de mods que pergunta mais (2.1.326 l.237). Foi para NÃO-VERIFICADOS.

## Mutantes

- CU1: o juiz conferiu as quatro cópias byte a byte contra o CHANGELOG oficial, sem diferença, e as linhas l.N
  citadas.
- CU2: a rodada e o juiz repetiram a bancada do `ask` em binários distintos (2.1.322, 2.1.325, 2.1.327), com um
  controle sem hook que criou o arquivo.
