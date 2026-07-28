---
title: 'Sinal RESOLVIDO: lint-selftest O(fixtures × repo) — escopo-de-arquivo `--only` (você JÁ tem o fix)'
date: 2026-07-01
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-01 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Sinal RESOLVIDO: lint-selftest O(fixtures × repo)

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Seu sinal de campo foi endereçado** (inbox 2026-06-24, agora em `inbox/_processed/` do core): o
  `lint-selftest.sh` levava **~10-17 min** no seu repo porque cada fixture re-rodava o `lint-artifacts.sh`
  **repo-inteiro** (41s/passada × ~20 fixtures) — O(fixtures × tamanho-do-repo), invisível no core (docs/
  pequeno). Exatamente o alvo da sua recomendação "escopo de scan no lint".
- **Fix (PR #180, commit `22f30b0`, 2026-06-27):** `lint-artifacts.sh` ganhou a flag **`--only=<arquivo>`**
  (wrapper `_find`): cada regra varre **só o arquivo injetado**, preservando a semântica de escopo por
  regra. O selftest passa `--only="${dst}"` nas invocações → cada fixture roda **O(1 arquivo)** em vez de
  re-escanear `docs/` inteiro. No core: ~8min → ~30s. No seu repo a projeção é **de ~10-17min para
  ~1-2min** (o `cp -a docs/` do sandbox permanece — o `inventory.sh` precisa dos números reais — mas o
  custo dominante, o re-scan por fixture, morreu). Complementado pelo PR #202 (modos core-only pulam
  gracioso — já anunciado em 2026-06-28).
- **Você JÁ tem o fix:** verificado no core que `22f30b0` e `2d2dad0` são ancestrais de `a458a0fc6b71` —
  o seu `--update` de 2026-06-30 os trouxe vendorizados. **Nenhuma ação além de re-rodar**
  `bash .claude/validation/lint-selftest.sh` e conferir o wall-clock. Se a medição real divergir da
  projeção, é um sinal novo bem-vindo (a sugestão "guard-rail de tempo" do seu sinal segue no radar, não
  implementada).

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL**, fix já vendorizado no seu pin atual — só re-rodar o selftest e (opcional) reportar
  a medição real como novo sinal.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-07-01-sinal-lint-selftest-escala-resolvido.md /home/marciocar/rhilo-metagamify/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
