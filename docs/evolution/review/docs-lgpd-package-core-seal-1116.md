---
branch: docs/lgpd-package-core-seal-1116
pr: pendente
date: 2026-11-16
reviewed_diff_sha256: 484619a73d3dda290561117f68d72648cd354b736e1a3c29f3b5b7b567c67d13
reviewed_code_sha256: 077546469c52203c39a657f20438d77d8032795c9a28832017bcd8b82c982891
findings_total: 0
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "Grafo novo de 3 nós, no molde dos selos de destino do Kali e do Viktor: kg-radar --integrity --schema rc 0 e kg-contract-check rc 0. Antes de selar, o core leu o texto da Lei 13.709/2018 na página do Planalto e conferiu cada base legal que o estudo da curadoria cita (arts. 5 VII, 15, 16, 18, 19, 37, 39, 42, 46, 47 e 48). Voz única do core, declarada: não houve revisor separado."
nota: "Sela a LISTA mínima de seis elementos, não a implementação nem a pessoa jurídica. O prazo em dias da comunicação de incidente NÃO é selado: a resolução da autoridade não foi lida na fonte primária; fica como nó aberto que restringe o selo. Não é parecer jurídico."
---

# Selo do core sobre o pacote LGPD mínimo do operador

## O que muda

Grafo novo `docs/onion/graph/lgpd-package-core-seal-2026-11.kg.yaml`. A decisão `D_SEAL_LGPD_MINIMUM_PACKAGE_1116` sela os seis elementos pesquisados pela curadoria como piso bloqueante antes do primeiro inquilino externo no serviço da VPS: contrato de operador, registro das operações por inquilino, plano de incidente, saída completa por inquilino, retenção e backup por inquilino, segredos fora do contêiner.

## Achados

Nenhum na forma. Na substância, uma ressalva entra selada junto: o prazo em dias do incidente não está verificado na fonte primária (`E_LGPD_INCIDENT_DEADLINE_UNVERIFIED_1116`, aberto).

## Limites declarados

- A lei foi lida por ferramenta que transcreve trechos da página, não por cópia integral do arquivo.
- A Resolução CD/ANPD 15 de 2024 não foi lida na primária; o que se sabe dela vem de terceiros.
- Fora do selo: implementação de cada elemento, pessoa jurídica do operador e qualquer parecer jurídico.
