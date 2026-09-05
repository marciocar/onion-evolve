---
title: '/meta:kg-inbox para em role: adopted sem oferecer o caminho do adotante'
date: 2026-09-04
from: portal-gamificacao (consumidor)
to: core (onion-evolve)
type: feature-request
flow: upstream (consumidor→core)
---

## O que aconteceu
`.claude/commands/meta/kg-inbox.md` passo 1: `role: adopted|hub → parar: o adotante tem a própria fila`.
Correto pela I3 (um escritor por repo) — mas o adotante **não recebe** um mecanismo de selagem local, só a
recusa. Num projeto colaborativo (dono + colaborador visitante que propõe nós ao grafo) a fila
`docs/evolution/kg-inbox/*.proposal.kg.yaml` precisa de alguém que sele.

## Contorno aplicado aqui
Comando projeto-local `.claude/commands/portal/selar.md`: lista propostas, radar advisory, apenda no grafo-alvo,
`git mv` para `_sealed/` ou `_rejected/` com motivo. Só o dono roda.

## Proposta
Parametrizar `/meta:kg-inbox` por role (no adotante, sela a fila local do próprio repo) ou vendorizar um
`/meta:kg-seal-local`. O padrão "proposta → selo do dono" é o mesmo; muda só quem é o dono.

---

## Triagem do core — 2026-09-05

**Veredito: FEATURE — curado na fonte, em duas metades** (este PR).
Você estava certo e o defeito era conceitual: a I3 (um escritor por repo) é fronteira de **REPO**, não de
**papel**. O `/meta:kg-inbox` confundia as duas e **parava** em `role: adopted`, deixando o adotante sem
mecanismo de selagem — foi por isso que vocês tiveram de forjar o `/portal:selar`.

1. **O comando ROTEIA por papel** (`Passo 1` reescrito): `source` sela a fila deste repo; `adopted|hub`
   sela a fila deste repo — a fila LOCAL do adotante. A forma é a mesma nos dois papéis, muda só quem e o
   dono. O que segue proibido em qualquer papel: proposta cujo `meta.target` aponta para FORA deste repo
   (absoluto ou `../`) → pare e reporte. E se a fila não existir, o comando manda criá-la antes de seguir
   (adoções anteriores a 2026-09-05 podem não tê-la).
2. **A fila NASCE na adoção**: bloco `(2a)` do starter do `/meta:adopt` cria
   `docs/evolution/kg-inbox/` com README, `_sealed/` e `_rejected/`, idempotente (não clobba fila em uso).
   Sem isso o comando roteado não tinha onde operar no dia 1.

Guardas: casos `(d)` — o bloco do starter é **executado** num sandbox e o efeito conferido, com 2ª passada
para provar idempotência — e `(e)`, sobre o roteamento e a fronteira de REPO. Cinco mutantes provados
(bloco removido; sem `_rejected/`; starter clobbando a fila; a recusa por papel de volta; a invariante do
`meta.target` removida). O seu `/portal:selar` continua válido como superfície local — o core agora
oferece o caminho canônico, e ele não te obriga a trocar.
