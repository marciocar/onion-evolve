---
reviewed_diff_sha256: d54671d95fef9cd35cb03833b0fd8bb34ce601993fe0f61e53dc0fcb4b2fd888
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
verdict: APROVADO
elenxo: nao
nota: >
  Anúncio downstream, sem mudança de comportamento: entrada do CHANGELOG + rascunho na outbox,
  entregue sem commit no inbound do hub. A passada adversarial da CURA que ele anuncia foi a do PR
  #918 (Elenxo opus, reprovou e as curas estão no resíduo de lá). Aqui a conferência é a da regra do
  co-announce: todo número do anúncio sai de uma medição citada (17 do hub; 22 e 21 adotantes; 59
  arquivos no clone), nenhum reafirmado em prosa.
---

# Resíduo — `docs/announce-vendor-ignored-cure`

Responde ao hub `brain-granaai` os dois sinais de 2026-10-04: a cura do `--update` que perdia arquivo
novo (PR #918) e o destino das evidências da resposta às três mensagens. `alvo: brain-granaai`
(informativo para os demais): só ele foi afetado, e os outros recebem a cura no próximo update sem
ação a tomar — anunciar a todos seria ruído.
