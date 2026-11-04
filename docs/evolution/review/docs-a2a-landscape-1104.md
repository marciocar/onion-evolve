---
branch: docs/a2a-landscape-1104
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: pendente
findings_total: 30
findings_real: 4
tokens: 9114365
duration_min: 17
findings_fixed: 4
verdict: REPROVADO_E_CURADO
elenxo: nao
reviewer: "verificação adversarial do /onion-research (3 votos por claim, 2 refutam; run wf_e7411d7e-52e) e verificador separado do grafo (radar e contrato rc 0)"
nota: "as 4 claims refutadas viraram nós C_SUPERACAO_20261104_*; a sessão do core conferiu a SYNTHESIS contra o retorno do run"
---

# Passada adversarial: `docs/a2a-landscape-1104`

## O que muda

O grafo `a2a-landscape-2026-11` (33 nós) e a SYNTHESIS: o panorama do A2A em novembro de 2026, pedido pelo maestro,
com o perfil Onion A2A comparado à spec e o Logto como emissor candidato.

## Achados

Foram 30 claims verificadas: 26 confirmadas e 4 refutadas. Cada refutação veio com superação, e virou nó:
1. o push é opcional, e não obrigatório;
2. os fluxos OAuth implicit e password foram depreciados, e não removidos;
3. a lacuna do Onion é de consulta (`GetTask`), e não de `input_required`;
4. o suporte do AISIX à 0.3 e à 1.0 é só autodeclarado pelo fornecedor.

Os confirmados de maior impacto que a SYNTHESIS projeta foram conferidos contra o retorno do run:
- `E_SPEC_101_DEFINES_GETTASK`: GetTask é RPC da spec;
- `E_SPEC_101_SECURITY_SCHEMES_OAUTH_FLOWS`: os esquemas de segurança do Agent Card;
- `E_RELEASE_V1_0_0_2026_03_12`: a 1.0 estável;
- `E_LLMS_REF_THREE_BINDINGS_AND_TASK_RPCS`: os três bindings;
- `E_AAIF_HOSTS_A2A_2026_08_17`: o projeto passa para a AAIF.

A SYNTHESIS declara 50 claims e 31 fontes cortadas pelo orçamento, e o eixo de cookbooks e SDKs sem achado.

## Mutantes

Nenhum: não há código.
