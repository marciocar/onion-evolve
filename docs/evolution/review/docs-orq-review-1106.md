---
branch: docs/orq-review-1106
pr: 1511
date: 2026-11-06
reviewed_diff_sha256: pendente
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
- **Entrega do kg-ssot no mesmo dia:** `Q_CS_KGSSOT_FORMA_X_EVENT_1107` fecha como done (PR #346 do kg-ssot, por testemunho), a issue SAC-297 vai a Done, e o pin do onion-kg-ssot no `members.yaml` passa para `fb2a7d72c98c` pelo `ops/registry-pins.sh --seal`, lido do remoto.
- **`DIARIO.md` da orquestração:** a janela de 06/11 de dia, com as estratégias 33 a 35.

## Achados

1. **Real, curado:** os 4 nós novos da coordenação nasceram órfãos (grau 0) e o radar reprovava a integridade. Ganharam TRACES_TO para `D_COORD_ORQUESTRACAO_PERMANENTE_1104` (a repassada é ato da orquestração permanente) e, o do `x_change`, arestas externas para o registro de mudança e a forma do `x_event` no plano da comunicação.
2. **Real, curado:** o label do nó do sandbox citava o caminho absoluto do binário do bwrap; a REGRA 99 (caminho de máquina) reprovava. Virou «o binário do bwrap».
3. **Real, curado:** o pedido mandava subir o teto da coordenação de 40 para 41, mas o grafo tinha 38 nós e entram 4: o teto declarado é 42, contado no arquivo.
4. **Não real:** o pedido mandava subir o teto do plano da comunicação de 16 para 18; o grafo mergeado tinha 14 nós e fica com 16, dentro do teto. O teto não subiu, para não declarar folga sem motivo.

## Os `confirmed` dos grafos editados

- `E_CS_PEDIDOS_DO_HUB_E_DO_MAESTRO_1106` (os pedidos do hub e do maestro): conferido. Os dois nós novos do plano detalham os degraus 1 e 3 que ele pede e não o contrariam. A forma do `x_event` fica fora do contrato, como o selo `D_KG_EVENT_PROFILE_1030` manda.

## Mutantes

Nenhum: o diff não tem código.

## Limites declarados

- A passada não é independente.
- Os nós com `evidence_class: testimony` repetem o relato das sessões à repassada; o core não re-mediu o sysctl, a versão vendorizada do adotante de consultoria nem a configuração do espelho do kg-ssot.
- `D_KG_EVENT_PROFILE_1030` mora no repo do kg-ssot e é citado em texto, sem aresta.
