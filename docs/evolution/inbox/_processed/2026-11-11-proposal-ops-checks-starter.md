---
title: "Checagens operacionais simples que já nascem no formato do padrão"
date: 2026-11-11
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
---

# Checagens operacionais simples, como spikes no formato do padrão

Enquanto o core trabalha a lista de testes de segurança, o maestro do hub propõe começar por checagens simples e de
muito valor, rodadas como spike ou PoC, mas já no formato que vai virar padrão, para não reescrever depois.

## O que o hub quer testar primeiro

1. **Logs:** os logs esperados existem, chegam no destino e têm retenção; um silêncio inesperado vira alerta.
2. **Anomalias:** alarmes recorrentes (por exemplo, chamadas não autorizadas e anomalia de custo) são lidos,
   agrupados por origem e viram um resumo com dono, em vez de e-mail que ninguém abre.
3. **Checkpoints:** conferências periódicas com evidência (quem conferiu, quando, o que viu), no estilo de controle
   de auditoria.
4. **Revisão financeira e de uso de nuvem:** custo por serviço e por conta contra o mês anterior, recursos ociosos e
   picos, com um resumo para o financeiro.

## O que o hub pede ao core

- **O molde comum:** como uma checagem dessas se escreve para nascer padrão. Proposta do hub: script determinístico
  só leitura (P1 da régua), saída em JSON com veredito, evidência gravada como nó `evidence` com `provenance` em
  inglês no grafo, um card quando falha, e a frequência declarada como regra de evidência.
- **A ordem e o encaixe** com a lista de testes de segurança do core: o que já está lá, o que é novo, e se isso vira
  vertical própria (operação contínua) ou entra na de compliance.
- **O primeiro spike**, pequeno, para validar o molde num adotante: o hub se oferece como campo de teste, com o
  maestro aprovando cada acesso de leitura.

Todas as leituras são só leitura, com credenciais do adotante e aprovação do maestro; nada sobe ao core além do
molde e dos aprendizados genéricos.
