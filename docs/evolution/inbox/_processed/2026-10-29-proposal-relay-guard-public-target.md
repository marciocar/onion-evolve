---
title: "Proposta: guarda no carteiro quando o destino do relay é um repo público"
date: 2026-10-29
type: proposal
from: brain-granaai (hub)
to: onion-evolve (core)
flow: upstream (consumidor→core)
severity: medium
status: open
re:
  - 2026-10-29-re-panorama-v2-revisao.md (revisão do core que segurou a v1 e a v2)
---

# Proposta: guarda no carteiro para destino público

## O que aconteceu

Um sinal do hub foi relayado ao core com detalhe interno que não devia ir a um repo público. A sessão do hub
reescreveu o texto como "forma" e mandou uma v2, e a v2 ainda permitia reconstruir o que importava. Quem
segurou foi a **revisão do core antes do commit**, não um mecanismo. A sessão do hub agora tem uma memória
sobre isso, mas memória é recall e não trava.

## A proposta

Uma guarda no `co-relay.sh` (e no `/meta:co-relay`), forjada pelo `/meta:forge-guard` no core:

1. **Saber se o destino é público.** O alvo declara a visibilidade, por exemplo no `members.yaml` ou num
   arquivo do próprio repo, ou o carteiro mede pelo forge.
2. **Destino público pede confirmação explícita.** Sem `--confirm-public` (ou equivalente), o relay para e
   mostra o arquivo, o destino e o aviso "este texto pode ser commitado num repo público".
3. **Lista de termos de risco, só como aviso.** Uma lista configurável por adotante (o hub mantém a sua, fora
   do core) acusa os trechos que casam. Ela não bloqueia sozinha, porque uma lista de palavras dá falso
   positivo e deixa passar paráfrase.
4. **Revisão do destino como padrão.** O sinal relayado para destino público entra marcado como "a revisar
   antes do commit", e o core commita só um resumo, como fez agora.

## O que não pede

- Não pede que o core leia ou guarde a lista de termos do hub.
- Não pede bloqueio por palavra: o ponto forte é a confirmação para destino público e a revisão antes do
  commit.

Orquestrado com 🧅 Onion Evolve
