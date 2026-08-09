# status-factor.awk — O FATOR DE STATUS, EM SÍTIO ÚNICO.
#
# POR QUE ESTE ARQUIVO EXISTE: esta função vivia COPIADA em kg-radar.sh e kg-view.sh (mais as duas
# cópias vendorizadas em plugins/). As duas divergiram: quando `drifted` e `unverifiable` entraram no
# enum em 2026-08-06, o radar ganhou os slots e a LENTE não — e passou a devolver -1, clampado a 0,
# ou seja PESO ZERO nos nós que acabaram de provar que o mundo andou. E o `--assert-parity` não via,
# porque comparava CONTAGEM e nunca PESO: duas lentes podiam concordar em quantos nós existem e
# discordar em qual é o mais urgente — que é a única pergunta que o painel responde.
#
# Quem consome INLINEIA este arquivo num programa awk (o mesmo padrão do SCOPE_PREDICATE em
# kg-verification-coverage.sh). Ausência do arquivo é FAIL-LOUD no consumidor, nunca default
# silencioso: fonte ausente jamais vira aprovação (P0 da REGRA 30).
function statusFactor(s) {
  if (s == "open" || s == "confirmed") return 1.0
  # DRIFTED — o nó foi MEDIDO contra o vivo e a realidade DIVERGIU. Fator > 1.0 de propósito:
  # um nó que acabou de provar que o mundo andou é MAIS urgente que um confirmado de mesmo peso,
  # porque alguém precisa reconciliar. Ele SOBE no radar, não desce.
  #
  # POR QUE ESTE SLOT PRECISOU EXISTIR (verificado em sandbox, 2026-08-06, com o status como
  # ÚNICA variável): sem ele, selar um drift só tinha dois caminhos, e ambos são fail-open —
  #   · gravar `drifted`  → exit 1, "status inválido": o gate RECUSA o selo;
  #   · gravar `refuted`  → statusFactor 0.0 ⇒ atenção 10,0 vira 0 e o nó SOME do radar.
  # O segundo é pior que o vazamento que ele curaria: apaga o sinal em vez de perdê-lo. O
  # terceiro caminho, praticado por falta de slot, foi apensar nós à mão (o grafo de identidade
  # fez isso em 2026-08-04: 16 nós novos porque o campo não existia).
  # Achado pelo Elenxo sobre as decisões de norte — a Fase "selo mecânico" teria nascido como
  # fábrica de fail-open se o schema viesse depois. SCHEMA PRIMEIRO.
  if (s == "drifted") return 1.3
  # UNVERIFIABLE — mediu-se e NÃO deu para verificar (método não derivável, medição exigiria
  # mutação, alvo fora do repo). Continua tão urgente quanto `open`: é pergunta aberta sobre
  # MENSURABILIDADE, não resposta. Nunca 0 — silenciar o que não se sabe medir é o oposto do
  # declarado!=verificado.
  if (s == "unverifiable") return 1.0
  if (s == "refuted") return 0.0
  if (s == "superseded") return 0.2
  if (s == "done") return 0.1
  return -1  # inválido
}
