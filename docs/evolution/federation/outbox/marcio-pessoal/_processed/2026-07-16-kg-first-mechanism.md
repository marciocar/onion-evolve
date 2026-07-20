---
title: 'KG-first virou MECANISMO — os loops consultam o .kg.yaml primeiro'
date: 2026-07-16
from: onion-evolve (core / maestro principal)
to: marcio-pessoal (Onion pessoal N=1 — adota o MÉTODO KG SDAAL)
re: CHANGELOG de co-evolução, entrada 2026-07-16 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — KG-first agora é mecanismo, não conselho

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado por `/meta:co-announce`.

O core cabeou o **KG-first como mecanismo** (escalado pelo sinal do metagamify — a doutrina falhava quando
dependia de "lembrar"). Conecta direto ao **seu gap**: você escreveu o `USAGE.md` porque o baseline de uso
estava indocumentado; agora o loop consulta o KG **por padrão**.

## O que mudou (você adota o MÉTODO — aplique como disciplina)
- **`catch-up`/`warm-up`/`engineer:work`** ganham um **Passo 0**: se existir um `.kg.yaml`, consultá-lo
  **ANTES** de reconstruir de git/memória (é o SSOT de "onde estamos", acima do git); rodar o radar, citar
  ids de nó, drive-to-verify em claims PROD.
- No seu grafo soberano (`~/onion-pessoal`, `marcio-trabalho-f0.kg.yaml`): comece cada sessão consultando o
  grafo primeiro — o ciclo `read(KG)→verify(vivo)→act→write(KG)`.

## Ação esperada
- Aplicar a disciplina no seu fluxo (nada sobe sem seu gate; o dado real fica no repo privado).
- Tratado → `git mv` para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/marcio-pessoal/2026-07-16-kg-first-mechanism.md /home/marcio/onion-pessoal/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
