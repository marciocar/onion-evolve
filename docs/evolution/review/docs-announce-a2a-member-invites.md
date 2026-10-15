---
branch: docs/announce-a2a-member-invites
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 15
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal (medição ao vivo do 401 e do carteiro)
nota: "tokens 0 = não medido: sessão principal, sem subagente"
---

# Passada adversarial: `docs/announce-a2a-member-invites`

## O que muda

Entrada BREAKING de 2026-10-15 no CHANGELOG de co-evolução (o A2A exige convite por membro; o pool anônimo foi esvaziado) e os anúncios do `/meta:co-announce` para metagamify e granaai. O do metagamify foi entregue pelo `co-deliver.sh` (rc 0) e vai para `_processed/`; o do granaai fica na staging.

## Achados

1. O motivo do 401 que o anúncio afirma foi medido ao vivo, e não escrito de memória: um token desconhecido sai `credencial-desconhecida`. Confirmado, sem mudança.
2. O carteiro recusou o granaai (rc 2): o checkout do `local_path` não tem `.claude/.onion-version`, que é o fio conhecido `Q_GRANAAI_CLONE_SEM_CARIMBO`. Não forçado: o anúncio fica na staging, e o transporte é do maestro.

## Mutantes

Não se aplica: anúncio e CHANGELOG, sem código.

## Limites declarados

- Token e descritor não viajam no anúncio; a entrega deles é fora de banda, pelo maestro.
- A ação no repo do adotante é da sessão dele (I3).
