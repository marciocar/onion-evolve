---
title: 'co-evolve.md e co-relay.md: a prosa só conhece `adopted` — o `hub` fica sem mapa (o script já aceita)'
date: 2026-09-25
from: hub-formacao-enterprise (hub, pin f32e2f931c73)   # slug NEUTRO do registro — o `from:` original trazia o nome comercial do cliente, achado por passada adversarial: a REGRA 36 deriva termos do members.yaml e o slug neutro, por ser neutro, RETIRA o nome comercial da lista de termos varridos; então este sítio ficava invisível à guarda ([[vendor-scrub-blind-spot]])
to: core (onion-evolve)
type: bug
severity: low
flow: upstream
---

# A prosa de co-evolução não conhece o papel `hub`

## O que acontece

Primeira sessão da Avansat após a adoção (`role: hub`). Ao rodar `/meta:co-evolve`:

- **Passo 1** mapeia só dois papéis: `role: source → CORE` e `role: adopted → CONSUMIDOR`
  (`.claude/commands/meta/co-evolve.md`, l. 24–31). Um stamp `role: hub` não cai em nenhum dos dois;
  a sessão teve de **inferir** que, perante o core, o hub se comporta como consumidor.
- **`/meta:co-relay` Passo 1** diz: "`role: adopted` → ADOTANTE → segue. `role: source` / stamp ausente
  → parar". Lida ao pé da letra, a prosa **manda um hub parar**.

Enquanto isso, o **script** já foi corrigido: `.claude/utils/co-evolution/co-relay.sh` (l. 85–96) aceita
`adopted|hub|standalone`, com comentário registrando que a omissão "custou um sinal entregue à mão
(2026-09-17)". O `co-deliver.sh` também valida `(adopted|hub)`. **O mecanismo evoluiu; a prosa que o
descreve, não** — e é a prosa que a sessão lê primeiro.

Conferido no core em `06bc547c268c` (HEAD de `main`, 2026-09-25): `grep -i hub` em
`co-evolve.md` e `co-relay.md` retorna vazio. O drift persiste na fonte, não só no pin da Avansat.

## Por que importa

O hub tem **duas faces** na co-evolução, e o `co-evolve` não descreve nenhuma delas:

1. **Para cima (hub → core):** consumidor — lê `inbound/`, relaya sinal via `co-relay`.
2. **Para baixo (hub → projetos dele):** autoridade de adoção (Camada 2) — roda `/meta:adopt` e
   `--update` nos próprios projetos. Falta dizer se o hub **anuncia** downstream aos projetos dele
   (tem `members.yaml`? usa `co-announce`/`co-deliver`?) ou se isso segue exclusivo do core.

## Pedido

1. `co-evolve.md` Passo 1/3: acrescentar `role: hub` (e `standalone`, que o script já aceita) com as
   duas faces acima.
2. `co-relay.md` Passo 1: alinhar a guarda da prosa à do script (`adopted|hub|standalone`).
3. Mecanismo, não conselho: um check de lint que compare o `case` de papéis aceitos no script com os
   papéis citados na prosa do comando — é o mesmo tipo de drift script×doc que o 2026-09-17 já pagou uma vez.
