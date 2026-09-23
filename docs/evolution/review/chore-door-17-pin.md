---
reviewed_diff_sha256: "3bef446aa254b8b4f2412b6c0793ee29c0fe364864bff2278d12ff2805d331ac"
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >
  Sem passada adversarial, e a razão é declarada: o diff é o avanço mecânico do pin da porta mais
  os três artefatos GERADOS que derivam dele (mapa, console, grafo). Não há lógica nova a refutar —
  a única afirmação de fato é "a porta está publicada no remoto", e ela foi verificada por
  `git ls-remote` em vez da nota que o script imprime. Refutador sobre projeção determinística
  seria cerimônia, e cerimônia é o que esta casa chama de campo sem consumidor.
---

# Resíduo — pin da 17ª materialização

**O que mudou:** `onion_version` de `b4fec1e472d7` para `0e5d6a7ddf58`, a catraca de
`onion-standalone` de 404 para 408, e a regeneração de `federation-map.md`,
`federation-console.html` e `graph.md`.

**O que foi verificado, e como:** `git ls-remote https://github.com/marciocar/onion-core.git HEAD`
devolveu `5d83730797ab` — o SHA que a publicação declara. Verificar pelo remoto e não pela saída do
script é o que separa pin de carimbo.

**A catraca subiu, e isso é honesto:** `onion-standalone` está parada desde 2026-07-19 e a `main`
andou 4 commits na superfície que viaja. Passivo real, não afrouxamento — o número só cai por
re-materialização daquela porta, que exige decisão do maestro.

**O erro que esta ordem evita:** duas vezes hoje eu commitei o pin sem os três derivados e o CI
acusou HARD (**REGRA 38 (Mapa da federação sincronizado com members.yaml)** e **REGRA 24 (Console da
federação sincronizado com o SSOT)**). Agora eles entram no mesmo commit.
