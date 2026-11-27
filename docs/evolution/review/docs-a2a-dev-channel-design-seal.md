---
branch: docs/a2a-dev-channel-design-seal
pr: pendente
date: 2026-11-27
reviewed_diff_sha256: e02792500d54170b2ee3a5c54b7d9ee83e803c82def5099ae07db0c7b19d607a
reviewed_code_sha256: 68198cfe2aa9df8f8d0191672f726931b10d2f92251cedeb4a353500f8dbecea
findings_total: 3
findings_real: 3
findings_blocking: 2
tokens: 79568
duration_min: 1
findings_fixed: 2
verdict: REJECTED_AND_FIXED
elenxo: false
reviewer: "subagente general-purpose isolado (sonnet), só leitura, sem o contexto da conversa, com mandato de refutar"
nota: "PR só de selo: duas decisões do maestro coletadas pelo /meta:decide depois do 2º Delphi (dev-brain-3x3-1127) e gravadas pelo kg-decide-seal.sh."
---

# Passada adversarial: `docs/a2a-dev-channel-design-seal`

## O que muda

Entram dois nós de decisão no grafo `a2a-backbone-product-2026-11`:
- `D_DEV_BRAIN_CHANNEL_DESIGN_1127`: o desenho do canal sessão a sessão entre os devs e a brain do hub, com revogação em falha fechada;
- `D_DEV_BRAIN_ROUNDTRIP_BEFORE_WAHA_1127`: a ida e volta mínima vem antes dos itens restantes do WAHA na fila da messaging.

O teto do meta sobe de 67 para 69 nós, com justificativa (REGRA 58).

## Achados

O revisor isolado reprovou os dois rótulos, porque afirmavam como decisão o que a pergunta gravada não sustentava. No primeiro, a lista dos canais, a regra da fila local e o tasks/get. No segundo, «logo depois da guarda de vazamento» e «1 dev piloto».

A cura reduziu cada rótulo ao que foi perguntado e escolhido. O primeiro cita o Delphi que levou o desenho ao maestro, onde está o conteúdo.

O terceiro achado não bloqueia: o selador não grava campos próprios de pergunta e escolha. Elas ficam em `provenance.locator` e na narrativa, como nos três nós anteriores.

Radar `--integrity --schema` rc 0 e contrato rc 0, com 69 nós.

## Mutantes

Não se aplica: o PR não muda código nem guarda.

## Limites declarados

O conteúdo integral do desenho (os 12 itens do MVP) vive no estado do Delphi, fora do git, e nos briefs mandados às sessões donas. Este grafo guarda a decisão e a referência ao Delphi. O selador não ter campos próprios de pergunta e escolha é limite da peça e fica para a evolução dela.
