---
branch: docs/sec-scan-php-docker-1022
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 1
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: "sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão); só grafo"
---

# Passada adversarial: `docs/sec-scan-php-docker-1022`

## O que muda

- `E_SEC_SCAN_PHP_DOCKER_SEMANA_1022` (evidence) com a varredura de PHP e Docker da semana de 2026-10-22, cruzada
  com as notas oficiais do Engine 29 e com a lista da sessão brain-granaai.
- Duas decisões do maestro seladas pelo `kg-decide-seal.sh`: `D_DOCKER_VPS_MIGRA_PARA_DOCKER_CE_29_9_2_1022` e
  `D_WAHA_ULTIMA_VERSAO_COM_REVISAO_PERIODICA_1022` (esta com a resposta livre, `--other`).

## Achados

1. A decisão do Docker saiu do selador ligada a `ENT_logto`, porque o `--link` exige um nó existente e não havia
   entidade do Docker. A evidência da varredura passou a sustentar as duas decisões (`SUPPORTS`), que é a origem real;
   a aresta para `ENT_logto` fica como contexto da VPS.

## Mutantes

- Não se aplica: só grafo; o selador roda radar e contrato e desfaz em reprovação (rc 0 nos dois selos).

## Limites declarados

- As versões e CVEs vêm das notas oficiais do Engine 29; o CVSS das CVEs do Go não é publicado pela Docker.
- A varredura de PHP cobriu containers em execução; imagens paradas não foram abertas.
