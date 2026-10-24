---
branch: research/radar-e3-r18
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: 716a6eab61525b2e34e7ddfd0dfa8e0ba8613bae6de34268e655f5eaba0fdad4
reviewed_code_sha256: d18471a085b4d0c05866c5e8d23761ddd602daaa6f1cd41391aae7a363f0ec11
findings_total: 11
findings_real: 11
tokens: 165097
duration_min: 40
findings_fixed: 11
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente general-purpose opus independente (não-fork), mandato REFUTAR"
nota: "tokens = só o juiz (medidos pelo harness); os da rodada não ficaram expostos. Os 11 achados são 3 vereditos negativos e 8 omissões. Os negativos foram reescritos com 3 superações; das omissões, 1 virou nó (a superação faltante), 4 foram absorvidas em nós reescritos, 1 corrigiu uma contagem e 2 ficaram como NÃO-VERIFICADOS declarados na SYNTHESIS"
---

# Passada adversarial: `research/radar-e3-r18`

## O que muda

- Rodada r18 do radar E3: grafo `radar-E3-2026-10-24-r18.kg.yaml` (16 nós), `data/2.1.310.txt`,
  `data/judge-verdicts.json`, `SYNTHESIS.md` e a baseline do E3 em `docs/onion/radar-baselines.yaml`.

## Achados

1. EXAGERA: a pergunta da subida para a 2.1.310 justificava o impacto pela linha 14 (elicitação), que não tem
   superfície, e omitia a linha 6. Reescrita, com `C_SUPERACAO_20261024_A_SUBIDA_SE_JUSTIFICA_PELA_COMPACTACAO`.
2. EXAGERA: o nó da SAC-239 dava por cumprida a metade do revisor, que tem o pin e nunca rodou (7 execuções, o job
   sempre `skipped`, modo off). Reescrito, com `C_SUPERACAO_20261024_REVISOR_COM_PIN_E_SEM_EXECUCAO` e com a
   pergunta de fecho comentada na SAC-239.
3. EXAGERA: a superação da pergunta da r17 tinha a ponta errada. Passou a sair da evidência que a responde
   (`C_SUPERACAO_20261024_A_PERGUNTA_DA_R17_FOI_RESPONDIDA`).
4. Omissão de superação: o nó da r17 sobre menções afirmava o revisor no CLI 2.1.308. Virou nó novo com SUPERSEDES.
5. Omissão da linha 6 (compactação com texto denso): absorvida pelos achados 1 e pelo nó de compactação.
6. Omissão da linha 4 (gateway do launcher do /chat de convidado, só em ensaio): absorvida pelo nó de Monitor e gateway.
7. Omissão das linhas 17 e 22 (Remote Control): absorvida pelo nó de itens sem superfície.
8. Omissão da linha 8 (pergunta com timeout): absorvida pelo mesmo nó; o host já tem a correção.
9. Omissão da linha 9 no bundle de plugins: absorvida pelo nó de hooks (o gerador emite `bash`).
10. Contagem dos settings de adotantes: a rodada truncou a listagem em 20; recontada, 37 legíveis, nenhum só aspas.
11. Linhas 7, 15 e 16, 18 a 21 e 23: declaradas em NÃO-VERIFICADOS.

## Mutantes

- CU1: o juiz fez `diff` e `cmp` da cópia contra o CHANGELOG baixado, os dois vazios.
- Hooks só-aspas: a contagem por python devolve 0 nos 25 hooks do core; um comando que começasse por aspas seria
  contado pela mesma expressão (`startswith('"')`).
- `bwrap`: o bind só-leitura da raiz sai rc 1 sob a restrição do AppArmor (`kernel.apparmor_restrict_unprivileged_userns = 1`).

## Limites declarados

- Nada foi subido: SDK do bridge e pin do revisor ficam para a SAC-243, por ordem desta rodada.
- Os tokens da rodada não foram medidos; só os do juiz.
