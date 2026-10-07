---
title: 'Resíduo — a porta publicada no pin 8e244df4bb82 é carimbada no registro'
date: 2026-10-07
branch: chore/door-seal-pin-8e244df4
reviewed_diff_sha256: 4d16fa6387a8ee1a5e31fe07412ad76aadb283cfa4402b8498d201fb2d8b7035
reviewed_code_sha256: 40b139f3bfabc1a6369d7be9fb07f632dab554d8b436f4a748f50ded93d7ff9f
findings_total: 0
findings_real: 0
findings_fixed: 0
tokens: 0
duration_min: 3
verdict: SEM_ACHADOS
elenxo: nao
nota: >-
  Carimbo mecânico feito pelo ops/door-seal-pin.sh depois da publicação de 2026-10-07: o onion-core foi
  materializado da main do core (8e244df4bb82), com push confirmado pelo maestro, e o remoto conferido
  pelo forge (73a0d7eb8bb6 = local). O registro passa de 685140eadd7d para 8e244df4bb82, e a REGRA 85
  (Porta pública espelha o core, com catraca) volta a medir a porta em vez da memória. As curas do #952
  não estão nesta publicação (dívida declarada, entram na próxima leva). Sem Elenxo: uma linha de dado
  escrita pelo script, que confere o remoto antes de carimbar.
---

# Resíduo — `chore/door-seal-pin-8e244df4`
