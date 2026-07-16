---
title: 'KG-SSOT ganha guardas de FRESCOR + SCHEMA e a doutrina SSOT-as-runtime (crédito: seu F0 N=1)'
date: 2026-07-16
from: onion-evolve (core / maestro principal)
to: marcio-pessoal (Onion pessoal N=1 — adota o MÉTODO KG SDAAL, não vendoriza .claude/)
re: CHANGELOG de co-evolução, entrada 2026-07-16 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — KG-SSOT: frescor + schema + SSOT-as-runtime

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

**Isto reconhece o seu F0** — o KG SDAAL validado numa **vida (N=1)**: reconciliou declarado(DEV)×vivido(PROD),
2 `SUPERSEDES` + 1 `REFUTES` de propósito → `exit 1` honesto. Foi registrado como a **3ª evidência de campo**
convergente (produção/metagamify · consultoria/gustavo · **vida/você**) no ADR de frescor. O método transferiu
ao domínio mais sensível mantendo a régua.

## O que o core shippou (doutrina que você aplica, já que adota o MÉTODO)

- **Disciplina de frescor:** carimbe `verified_at:` em nós `plane:PROD` **e** em nós DEV que rastreiam
  artefato móvel (declare `verified_against:` — branch/commit/deploy). Sem carimbo = ⚠ STALE (a foto pode ter
  envelhecido). `meta.baseline:` fecha o STALE-OLD.
- **`schema_version: "1"`** no `meta:` do seu `.kg.yaml` — versiona a gramática; o radar recusa se driftar.
- **Ciclo SSOT-as-runtime:** `read(KG)→verify(vivo)→act→write(KG)`. KG-first + drive-to-verify. Isto ecoa o
  **seu próprio gap** (o baseline de uso indocumentado — o `USAGE.md` que você escreveu): a SSOT só entrega
  quando é o substrato de execução, não um doc arquivado.
- **`/meta:co-evolve` v1.4.0** agora dá `git fetch`/`pull` antes de ler o inbox — **direto do seu sinal**
  (o `onion-pessoal-usando-dogfood-kg-sdaal` não "chegou" na 1ª leitura por checkout stale).

## Ação esperada no adotante
- Ler este anúncio (📥 inbound).
- Aplicar a disciplina no seu grafo soberano (`~/onion-pessoal`, privado) quando fizer sentido — nada sobe
  sem seu gate humano; o dado real nunca sai do repo privado.
- Tratado → `git mv` para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/marcio-pessoal/2026-07-16-kg-ssot-freshness-schema-runtime.md /home/marcio/onion-pessoal/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
