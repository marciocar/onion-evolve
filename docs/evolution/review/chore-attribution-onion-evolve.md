---
reviewed_diff_sha256: 8263a4d5fbbd47fb77ac7b5c12491574613191eb4c4947576b88e16cfb3bfd54
findings_total: 3
findings_real: 3
tokens: 0
duration_min: 20
verdict: CORRIGIDO
elenxo: nao
nota: >
  Sem passada do Elenxo: mudança de configuração e de texto, sem lógica nova. A revisão foi a das
  guardas, e ela achou três coisas reais, todas corrigidas antes do PR: o 🧅 gravado como par
  substituto UTF-16 (settings.json UTF-8 inválido); a REGRA 70 barrando o fallback mudado só na
  projeção (a fonte é o session_floor da escada); e o caso em-dia da backlog_projection, que falhava
  porque o sandbox da bancada lia cópias não rastreadas de grafos na árvore viva.
---

# Resíduo — `chore/attribution-onion-evolve`

Assinatura `Orquestrado com 🧅 Onion Evolve` e Sonnet 5.5 como piso da escada de modelos. Grafo
tocado: nenhum. Os três achados estão na nota acima.
