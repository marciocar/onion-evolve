---
branch: docs/radar-e3-r28b
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: 8086049a1b37d05c1a72aa3c522eb0fa2923e5abd484b013ae23ff7c6a361a10
reviewed_code_sha256: 5d6de18bbc5836e56f9a88b9f844a010298b9ddc310a027c172653f04072e0c3
findings_total: 9
findings_real: 9
findings_blocking: 0
tokens: 315324
duration_min: 18
findings_fixed: 9
verdict: FIXED
elenxo: true
reviewer: "subagente general-purpose opus independente (não-fork, sem nome), mandato REFUTAR, effort high"
nota: "tokens = o juiz e a sonda do agent_id da rodada original. Os 9 achados são os 6 EXAGERA (aplicados com as 6 superações) e as 3 omissões medidas (duas do deny em bypass, reunidas num nó só na versão pública, e a deriva do cited-directive). Esta é a versão pública da rodada 28: a primeira (PR #1762) foi fechada sem merge porque publicava detalhes de um furo de segurança de terceiro. Nenhum código de produção mudou: o diff é o grafo, os dados da rodada, a SYNTHESIS e o selo do eixo E3."
---

# Passada adversarial: `docs/radar-e3-r28b`

## O que muda

A rodada 28 do radar do Claude Code (2.1.331 e 2.1.332), a sonda do `PreSkillShellCommand` em `data/` e o selo da baseline do eixo E3. É a versão pública da rodada: as sondas do deny e os detalhes do achado do deny em bypass ficam no registro privado do core (25/11), fora do repositório público.

## Achados

Os vereditos estão em `docs/evolution/research/radar-E3-2026-11-25-r28/data/judge-verdicts.json`. O resultado foi 9 SUSTENTA, 6 EXAGERA e 0 REPROVA. O `judge-verdict-check.sh` saiu rc 0, com 6 superações e 0 recusados.

- **Os 6 EXAGERA** foram reescritos nos nós. Cada um tem a superação correspondente (`C_SUPERACAO_20261125_*`):
  - deny lento sem o modo de permissão declarado no label;
  - deny da diretiva medido numa forma só;
  - 4 hooks sem timeout;
  - contagem de diretivas;
  - campo `agent_id` do colega de time;
  - SAC-432 não comentada. Agora está comentada e com o título corrigido.
- **Omissões 1 e 2, de impacto alto:** o deny da casa não segura em bypassPermissions sob certas formas de comando Bash, medido em 2.1.330–2.1.332. Os hooks PreToolUse seguem barrando merge e push para a main. Detalhes e reprodução ficam fora do repositório público (registro privado do core, 25/11). A rodada confirmou de forma independente. Viraram o nó `E_DENY_NAO_SEGURA_EM_BYPASS_1125` e a ação SAC-551. Um push acidental de sonda criou um branch sem conteúdo novo, já apagado.
- **Omissão 3: a deriva do cited-directive** segue igual na 2.1.332. Virou nó.

## Mutantes

Não se aplica: nenhuma guarda nem código de produção mudou. A sonda em `data/` é instrumento de medida da rodada, e não guarda. As guardas propostas (SAC-551, SAC-552) nascem com bancada e mutante na leva delas.

## Limites declarados

- O Code Mode segue desligado neste host, e a sessão interativa não foi medida no caso do deny lento.
- O que ficou sem medida está em NÃO-VERIFICADOS na SYNTHESIS.
- A reprodução do achado do deny não está no repositório: quem re-mede precisa do registro privado do core.
- Redação pública passada por um refutador opus independente, com mandato de achar vazamento: ele apontou pontes de inferência entre o item do deny lento e o achado em bypass (aresta, vereditos, «diretiva curta», «limiares», «comando inteiro»), o id de sessão no veredito do colega de time e um trecho de código do binário; todos curados. A sonda do `PreSkillShellCommand` fica porque só mede o evento novo (none, block, allow) com um marcador inofensivo, sem deny nem forma de contorno.
