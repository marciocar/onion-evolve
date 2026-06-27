---
title: 'S2 resolvido: /meta:co-relay (transporte upstream entrega-sem-commit) + S1 toolbox triado'
date: 2026-06-27
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-27 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — S2 resolvido: /meta:co-relay

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Seu sinal S2 (mecânica do transporte manual) foi resolvido** (seu sinal de 2026-06-25, PR #178). O incidente que você reportou — a IA commitou cross-repo na **branch errada** do core e escalou ao maestro decisões de **Ato-1 determinístico** — está **dissolvido por construção**.
- **Como (reframe):** o core já tinha o padrão certo no `/meta:co-deliver` (downstream): **entrega-sem-commit** — larga o arquivo **untracked** no canal do alvo; quem commita é a sessão home do destino → **branch-agnóstico**. Faltava o **espelho upstream**. Criamos **`/meta:co-relay`** (adotante→core `inbox/`). **Sem commit cross-repo → não existe "branch errada" nem pergunta de push → nada a escalar.** O script worktree+commit que você propôs foi **rejeitado** (reintroduziria o incidente).
- **Bug latente que você teria pego:** a guarda de papel **lê o STAMP `.claude/.onion-version`**, NÃO `onion-version.sh` — esse hardcoda `role: source` e, vendorizado no seu repo, mentiria 'source'. Provado em campo: rodamos o `--dry-run` do co-relay no SEU repo e ele prosseguiu (leu `adopted` do stamp). `co-deliver`/`co-announce` também foram endurecidos p/ ler o stamp primeiro.
- **Doutrina fixada** (ADR onion-adr-manual-relay-subprotocol-2026-06): RACI do regime manual (Ato-1 transportar = IA Driver, determinístico; Ato-3 commitar/triar = humano na sessão home); vocabulário (**maestro = humano**; core = maestro principal); guarda canônica = stamp; "silêncio ≠ consentimento".
- **Seu sinal S1 (padrão "toolbox") foi triado → backlog/pesquisa.** O S2 é o **1º caso concreto** dele e destilou o critério que você pediu: *procedimento recorrente → script determinístico (controle) + comando (juízo/quando) + ADR (doutrina) + gate humano (irreversível)*. Não será materializado como produto sem dogfood.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- No próximo `/meta:adopt --update`: o `co-relay` chega vendorizado. A partir daí, p/ mandar um sinal ao core (mesma máquina): escreva no seu `docs/evolution/inbox/` e rode `/meta:co-relay <sinal> --target <path-do-core>` (Ato-1, entrega-sem-commit; a sessão do core commita + tria).
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-27-co-relay-s2-resolvido.md <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio). Ou: `/meta:co-deliver rhilo-metagamify --target <repo-do-adotante>`.
