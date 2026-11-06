---
branch: docs/orq-review-1106
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: ebe4d717ae112ded0116a6786ff27cf5c838e9d761a9ea9950bb9d7c80e7a5b0
reviewed_code_sha256: 4aa1b2a1f5df0af00807e3c2139943ed0ee1406a150a64cc94f115da847b09fd
findings_total: 4
findings_real: 3
findings_blocking: 0
tokens: 0
duration_min: 20
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente)
nota: "tokens 0 = não medido. Diff de registro: dois grafos e o diário, sem código."
---

# Passada adversarial: `docs/orq-review-1106`

## O que muda

- **`docs/onion/graph/comms-stable-2026-11.kg.yaml`:** dois compromissos de peer, com dono, data e issue no Linear: a dissecação dos channels pela curadoria (o degrau 1 depende dela) e a forma não normativa do `x_event` pelo kg-ssot (sustenta o degrau 3).
- **`docs/onion/graph/coordenacao-sessoes-2026-10.kg.yaml`:** quatro pendências da repassada (três do maestro e uma do kg-ssot), com o teto de 40 para 42 e o motivo na linha do TETO.
- **`DIARIO.md` da orquestração:** a janela de 06/11 de dia, com as estratégias 33 a 35.

## Achados

1. **Real, curado:** os 4 nós novos da coordenação nasceram órfãos (grau 0) e o radar reprovava a integridade. Ganharam TRACES_TO para `D_COORD_ORQUESTRACAO_PERMANENTE_1104` (a repassada é ato da orquestração permanente) e, o do `x_change`, arestas externas para o registro de mudança e a forma do `x_event` no plano da comunicação.
2. **Real, curado:** o label do nó do sandbox citava o caminho absoluto do binário do bwrap; a REGRA 99 (caminho de máquina) reprovava. Virou «o binário do bwrap».
3. **Real, curado:** o pedido mandava subir o teto da coordenação de 40 para 41, mas o grafo tinha 38 nós e entram 4: o teto declarado é 42, contado no arquivo.
4. **Não real:** o pedido mandava subir o teto do plano da comunicação de 16 para 18; o grafo mergeado tinha 14 nós e fica com 16, dentro do teto. O teto não subiu, para não declarar folga sem motivo.

## Mutantes

Nenhum: o diff não tem código.

## Limites declarados

- A passada não é independente.
- Os nós com `evidence_class: testimony` repetem o relato das sessões à repassada; o core não re-mediu o sysctl, a versão vendorizada do adotante de consultoria nem a configuração do espelho do kg-ssot.
- `D_KG_EVENT_PROFILE_1030` mora no repo do kg-ssot e é citado em texto, sem aresta.
