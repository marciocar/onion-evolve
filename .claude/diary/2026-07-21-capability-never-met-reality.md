---
date: 2026-07-21
instance: onion-evolve
type: observation
classification: collective
tags: [federation, declared-vs-verified, fixtures, capability, dogfood, contracts]
affects: [meta, engineering, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "NÃO desenhar transporte novo (a2a-live gated, federation-transport SDAAL, single-source+mesh) enquanto a capacidade de federação formal não encontrar UM caso real ou for marcada honestamente como não-exercida. E adotar a distinção como rotina: 'passa nos fixtures' é prova de FORMA; 'foi exercido contra um caso real' é prova de FUNÇÃO. Registrar as duas separadamente — no grafo, no inventário, no que for. Quando só a primeira existe, dizer isso em voz alta em vez de listar a capacidade como entregue."
review_after: 2026-10-19
conflict_class: dynamic
significance: "O passivo pago revelou a maior distância entre declarado e verificado do core — não num fato, mas numa CAPACIDADE inteira que passa em todos os testes e nunca tocou a realidade."
---

## Signal
**`declarado ≠ verificado` também acontece na camada de CAPACIDADE, não só na de fato — e é mais difícil de
ver, porque a capacidade passa nos testes.** A Federação formal tem 5 comandos e 3 scripts que passam nos
fixtures e **nunca encontraram um caso real**. Passar em fixture é prova de **forma**; ser exercido contra
o mundo é prova de **função**. Listar a primeira como se fosse a segunda é o modo de falha.

## Evidence
- **Verificado em primeira mão hoje** (não herdado do nó do grafo): o único diretório `contracts/` do repo é
  `.claude/validation/fixtures/contracts`, contendo `good-contract.md` — um **fixture**.
  `docs/evolution/federation/` tem `CHANGELOG.md`, `members.yaml`, `onboarding-remote-member.md` e `outbox`
  — **nenhum contrato registrado**.
- `federation-contract-validate.sh` existe e funciona. Em **mais de cinco semanas**, nenhum
  `federation-check` ou rollback foi jamais exercido contra um caso real.
- O nó `REC2_NO_CONTRACT_EVER_REGISTERED` (peso 28.5 no radar) **REFUTA explicitamente** a leitura de que a
  Federação formal está "entregue e viva".
- **Os três itens de federação mais pesados do radar estão ABERTOS e dependem disso:** handshake gated
  a2a-live (37.5), federation-transport SDAAL com adapters (33.0), single-source identidade + mesh de
  comunicação (32.0). Desenhar transporte novo sobre uma capacidade que nunca provou o transporte antigo é
  construir sobre não-verificado.
- **O contraste que dá a régua:** o que FOI exercido contra a realidade nesta mesma casa deixou marca
  inequívoca — a adoção de um adotante real achou e consertou um bug (#303); a leva de modelagem achou nó
  órfão, contradição de status e aresta mal-modelada. Capacidade exercida produz achados. **Cinco semanas
  sem um único achado de federação não é maturidade — é ausência de uso.**
- O custo de fechar é baixo: **os quatro adotantes locais existem** e estão clonados.

## Next crumb
Ver `next_recommended`. A decisão é binária e é do maestro: **exercer contra um caso real** ou **marcar
honestamente como capacidade não-exercida**. O que não serve é seguir tratando como entregue — porque aí o
inventário mente com a autoridade de um teste verde, e os três desenhos abertos herdam a mentira.
Ver [[mechanism-beats-prose]] e [[inverted-provenance-ratchet]].
