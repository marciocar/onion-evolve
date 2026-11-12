---
title: "Resultado do primeiro spike: checagem de chegada de logs (nível 0)"
date: 2026-11-12
type: report
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
re:
  - docs/evolution/inbound/2026-11-12-resposta-spike-checagem-operacional.md (no hub)
---

# Primeiro spike: chegada de logs, no molde selado

Feito como o core respondeu: checagem de logs primeiro, só leitura, sem credencial nova (perfil já existente,
aprovado pelo maestro), sem conteúdo de log no grafo.

## O que o hub construiu

- Script determinístico, sem modelo no caminho; lê só metadados do serviço de logs da nuvem (nome do grupo,
  retenção, bytes, hora do último evento).
- Saída JSON: `check`, `level: 0`, `mode: observe`, `measured_at_utc`, `scope`, `verdict` (`pass`/`warn`/`fail`;
  `unmeasured` com rc 2 quando não mede), contagens por veredito e a lista por grupo.
- Vereditos por grupo: `ok`, `no-retention`, `silent` (teve evento no último mês e nada nas últimas N horas) e
  `dormant` (sem evento há mais de um mês).
- Evidência como nó `evidence`, `method: measurement`, só com contagens; a lista por grupo fica fora do repo.

## Primeiro resultado (contagens)

147 grupos: 16 ok, 42 ativos sem retenção, 16 em silêncio há mais de 48 h, 73 dormentes; 109 sem retenção
definida. Veredito `fail`, sem ação (nível 0).

## Lições para o molde

1. **"Silêncio" precisa de uma lista de esperados.** Sem ela, grupo de baixo uso aparece como silêncio. Proposta:
   o adotante declara os esperados (nome ou padrão, janela máxima sem evento) num arquivo versionado, e só o que
   está nele pode subir de nível; o resto fica como observação.
2. **Retenção indefinida é achado de dois domínios:** custo (`cloud-cost`) e minimização (`conformance`). Vale o
   molde dizer onde um achado com dois donos é registrado uma vez só.
3. **Dormentes merecem um veredito próprio** (candidato a limpeza), não erro.
4. **Paginação e custo da chamada:** uma chamada por grupo para o último evento; com centenas de grupos, o molde
   deveria prever teto e amostragem declarados.

O hub segue em nível 0 até o core fixar a lista de esperados no molde.
