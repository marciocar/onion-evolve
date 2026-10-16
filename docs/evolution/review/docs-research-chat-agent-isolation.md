---
branch: docs/research-chat-agent-isolation
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
tokens: 96064
duration_min: 1
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose opus, mandato REFUTAR
nota: "PR de registro: grafo da pesquisa (2 runs) + selo da decisão do maestro de 2026-10-16 + SYNTHESIS; 3 achados do refutador, todos curados."
---

# Passada adversarial: `docs/research-chat-agent-isolation`

## O que muda

Registro da pesquisa `chat-agent-isolation-2026-10` (rodadas `wf_505962e3-7c9` e `wf_8847e3af-370`): o grafo de
124 nós, a decisão do maestro de 2026-10-16 («Degrau 0 já + 3 provas») selada pelo `kg-decide-seal.sh` como nó
NOVO (`D_MAESTRO_DEGRAU0_E_TRES_PROVAS_1016`, TRACES_TO a decisão-mãe, que segue `open`), o teto do `meta:`
subido de 123 para 124 com motivo, a `SYNTHESIS.md` com o contrato de custo e o `docs/backlog.md` regenerado.

## Achados

1. Inventário de contas da VPS (com nome de adotante e de pessoas) num nó do grafo público. CURADO: trocado por
   "6 contas humanas e de serviço".
2. A decisão-mãe ainda dizia que hosting e CVE-2026-39861 não tinham sido lidos. CURADO: o `verified_against`
   aponta a lacuna fechada pela rodada 2, a recomendação vigente e o selo parcial.
3. A SYNTHESIS dizia não acrescentar nada ao grafo, mas traz custo e balanço. CURADO: a frase diz "afirmação de
   domínio" e nomeia o journal dos runs como fonte do custo.

## Mutantes

Não se aplica: o PR não muda código nem guarda; o gate é o radar `--integrity --schema` (exit 0) e o
`kg-contract-check.sh` (rc 0), rodados de novo depois das curas.

## Limites declarados

As 3 provas pedidas pelo Elenxo NÃO estão neste PR: entram como evidência num 2º PR, depois das medições.
Decisão tomada sem o maestro: o selo como nó novo (não fechar a decisão-mãe), com o teto subindo 1.
