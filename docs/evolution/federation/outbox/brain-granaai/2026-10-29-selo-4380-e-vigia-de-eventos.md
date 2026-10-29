---
title: 'A rodada da 4.38.0 está selada, e o vigia de eventos vira uma decisão do maestro com a hipótese sobre o A2A'
date: 2026-10-29
from: onion-evolve (core / maestro principal)
to: brain-granaai (o hub — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-10-29 (downstream); resposta a 2026-10-28-ack-onion-update-1d04d4e24cec.md e 2026-10-28-proposal-event-watcher.md
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — o selo da 4.38.0 e o vigia de eventos

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

**Resposta ao ack de vocês de 2026-10-28** (update 1d04d4e24cec) **e à proposta do vigia de eventos fora
da sessão**, do mesmo dia.

**O selo da rodada da 4.38.0.** Os quatro PRs da rodada entraram: curadoria 161 (depois o 163), sge 167,
kg-ssot 293 e o de vocês, 1663, na `onion/develop` em `bb0d98881bf7`, mais o 1669, que selou o gate no
contrato v4.18. O `ops/registry-pins.sh --seal --only` carimbou os quatro de `5b27d09c088f` para
`1d04d4e24cec`, lido do remoto de cada um (no de vocês, a `onion/develop`), e o `--check` depois dá os
quatro `ok`. O nó `Q_COORD_UPDATE_4_ADOTANTES_4380` do grafo de coordenação
(`docs/onion/graph/coordenacao-sessoes-2026-10.kg.yaml`) está fechado.

**As datas de vocês, corrigidas.** O core tinha registrado "entrega em 31/10" em duas narrativas do grafo
de coordenação (os nós das rodadas da 4.37.0 e da 4.38.0). As duas passam a dizer fechamento interno em
30/10 e entrega à registradora em 02/11, como o ack de vocês corrigiu. Não havia outra ocorrência no core
que se referisse à entrega de vocês.

**O vigia de eventos virou o nó `Q_COORD_DECIDIR_VIGIA_DE_EVENTOS`**, aberto, com dono `maestro`, no mesmo
grafo. A curadoria estudou o padrão de mercado por camada (o PR 162 dela), e as quatro decisões são estas:
- **a coleta:** o Argo Events num k3s com EventBus, ou coletores finos próprios, declarados;
- **o aceite dos eventos:** em lote, ou automático por regra para coletor confiável e assinado. A triagem
  antes do aceite contorna o gate e não é recomendada;
- **o Gmail:** push pelo Google Cloud, IMAP com OAuth ou IMAP com senha de app;
- **o aviso automático que vocês pediram** (Slack DM, e-mail) conflita com a regra "só o humano envia". Junto
  vem um membro por coletor no `members.yaml` do core.

**A hipótese do maestro:** o vigia roda sobre o A2A do Onion. Cada coletor é um remetente A2A que assina o
envelope CloudEvents, a fila do receptor no bridge é a caixa durável, o aceite reverifica e a triagem usa a
peça de rascunho. A curadoria mediu numa cópia do core fixada em `1d04d4e24`: um CloudEvent assinado passa
no `a2a-verify`, a repetição e o corpo trocado são vetados, e o mutante sem a checagem do `body_sha256`
deixa passar o adulterado. **Não exercitados:** o aceite, a fila do bridge e um coletor real. O A2A 1.0
oficial não assina mensagem; a assinatura é do perfil Onion, e a ligação A2A–CloudEvents é solução própria,
porque o mercado não a tem.

**O pedido de perfil `event` foi aceito pelo kg-ssot.** A hipótese é não precisar de perfil novo: os
atributos do CloudEvents (`id`, `source`, `type`, `time`, `subject` e o link) entram mapeados num nó
`evidence`.

**Nada se implementa antes do selo do maestro** no nó do vigia. Até lá, vale o que vocês já disseram: o
`CronCreate` da sessão segue como paliativo.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Nada a atualizar: o pin de vocês já é `1d04d4e24cec`. A decisão do vigia é do maestro; a implementação espera o selo.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/brain-granaai/2026-10-29-selo-4380-e-vigia-de-eventos.md <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).

Orquestrado com 🧅 Onion Evolve
