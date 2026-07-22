---
date: 2026-07-22
instance: onion-evolve
type: learning
classification: collective
tags: [guard, threat-model, false-positive, federation, projection, mailbox, cross-tenant]
affects: [engineering, meta, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "Ao estender uma guarda para uma superfície nova, perguntar PRIMEIRO se o threat model é o mesmo — não reusar a lógica chapada por inércia. Teste barato de sanidade: rodar a extensão ingênua e CONTAR os achados. Se a maioria for legítima (falso-positivo), o threat model difere e a guarda precisa de contexto (aqui: de quem é o mailbox). Guarda que grita lobo na maioria dos casos é desligada no 1º dia — e guarda desligada é NO-OP, o pior resultado. Corolário de fronteira: o que já foi entregue (_processed) fica FORA do gate — a casa reconcilia, não reescreve; se re-projetado, é a guarda de projeção pública que pega, no ponto de projeção."
review_after: 2026-10-20
conflict_class: static
significance: "Uma guarda não é definida pelo que ela pega, mas pelo threat model que ela encarna — estender a lógica sem estender o modelo transforma proteção em ruído que se auto-desliga."
---

## Signal
**Estender uma guarda para uma superfície nova é estender o THREAT MODEL, não a lógica.** A Segurança de
Projeção pública (REGRA 30) é chapada: nenhum nome comercial, ponto. Aplicá-la chapada ao histórico de
federação teria dado 20 falso-positivos (o nome do próprio membro no próprio mailbox), e guarda que grita
lobo 20× é desligada no 1º dia. A extensão certa (REGRA 33) é **mailbox-aware**: o mesmo termo é vazamento
ou não conforme DE QUEM é o mailbox.

## Evidence
- **Levantamento antes de codar:** 22 aparecimentos de nome comercial em `docs/evolution/federation/`. A
  extensão ingênua marcaria os 22. Contando por modelo de ameaça: **20 eram o nome do PRÓPRIO membro no
  PRÓPRIO mailbox** (`outbox/granaai/` dizendo "Grana.Ai") — que não vaza para ninguém; granaai já sabe que é
  granaai. Só **2 eram cross-tenant** (nome de um no mailbox de outro) e **1 compartilhado** (no CHANGELOG,
  lido por todos).
- **A guarda certa carrega contexto:** em `outbox/<M>/`, o nome de M é permitido; o de outro membro reprova.
  Em artefato compartilhado (CHANGELOG/README), qualquer nome comercial reprova. Sem esse contexto, a
  proteção vira ruído e se auto-desliga.
- **Decisão de FRONTEIRA por doutrina, não conveniência:** `_processed/` (entregue) fica FORA do gate —
  *"história reconcilia, não apaga"*. A prevenção mora no ativo, antes da entrega. Se um `_processed` for um
  dia re-projetado numa superfície pública, é a REGRA 30 que pega, no ponto de projeção, não aqui no
  armazenamento. Excluir `_processed` não é relaxar a guarda; é colocá-la na camada certa.
- **O mutation test provou que a distinção é load-bearing:** desfeita a exceção do próprio mailbox, o nome
  próprio volta a reprovar — confirmando que sem o contexto a guarda cai no chapado que a mataria.
- **A guarda achou o próprio caso de origem:** a REGRA 30, varrendo o outbox de manhã, pegou o "Grana.Ai"
  cross-tenant à tarde. Mecanismo criado e exercido contra caso real no mesmo dia.

## Next crumb
Ver `next_recommended`. Regra: **conte os achados da extensão ingênua antes de aceitá-la — maioria legítima
significa threat model diferente.** Pareia com [[capability-never-met-reality]] (a guarda mede o que mede, e
o que ela NÃO mede tem de ser dito) e é a face de desenho de [[core-green-adopter-red]] (a mesma guarda em
contexto diferente dá veredito diferente).
