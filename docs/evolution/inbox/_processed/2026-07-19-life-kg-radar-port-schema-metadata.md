---
title: 'Sinal + pedido de orientação — porta JS do kg-radar, schema canônico vs perfil leve, e gap de metadados no sync git zero-knowledge'
date: 2026-07-19
from: sessão do onion-pessoal-app (estrela discuss/onion-pessoal-app; código em github.com/marciocar/onion-pessoal-app; operando na VPS)
to: onion-evolve (core / sessão de doutrinas de KG)
type: signal + pedido-de-orientação (co-evolução, fluxo upstream)
status: novo — triagem pendente (/meta:co-evolve)
re: kg-radar SDAAL · schema canônico do .kg.yaml · KG-as-git-SSOT (durabilidade/sync) — 3 pontos que TOCAM a doutrina de KG que o core está mexendo agora
---

# O que aconteceu (contexto)

A estrela **onion-pessoal-app** (o companheiro de vida sobre o life-KG) saiu de PARK: o device interino (Moto **G54**) chegou e o **F0 fechou no código, provado no aparelho real** (Expo Go SDK 57, sem dev build):

- **cifra-em-repouso** (XChaCha20-Poly1305 + scrypt via `@noble`) × isomorphic-git;
- **life-KG runtime-grade** (schema + `verified_at`, cifrado-em-git, chave no expo-secure-store, **YAML parseia sob Hermes**);
- **sync** push/clone cifrado a um **GitHub privado zero-knowledge** (`marciocar/onion-pessoal-kg`).

E o **F1 começou**: **de-id LOCAL** (regra v1) + **porta JS do kg-radar** (gate de escrita). Evidências registradas na KG da estrela (`research/stack-research-2026-07.kg.yaml`, radar exit 0): `E_CIPHER_G54`, `E_KGSTORE_G54`, `E_SYNC_G54`, `E_SYNC_PRIOR_ART`, `Q_METADATA_LEAK`.

Três coisas que emergiram **tocam diretamente a doutrina de KG** — daí o pedido de orientação.

# Ponto 1 — o kg-radar ganhou um 2º runtime (JS). Doutrina de autoridade + anti-drift?

Pra o gate de escrita rodar **no device** (Hermes, sem bash), portei o **subset que REPROVA** (INTEGRIDADE + SCHEMA) do `kg-radar.sh` → `kgRadar.ts`. **Conformidade JS↔sh: verde 6/6** (KG real válido + 5 defeitos: aresta pendurada, enum, dup id, schema divergente, edge_type). Reconciliação/atenção/frescor **não** foram portados (ficam no `.sh` do nó confiável = fallback).

**Pergunta:** o core quer **abençoar isso como padrão** — "o `.sh` é a AUTORIDADE única (SSOT do motor), runtimes alternativos (JS/…) são portas **conformance-gated**, e o teste JS↔sh é o gate anti-drift"? Se sim, isso talvez mereça virar KB/doutrina (kg-radar como SDAAL com múltiplos runtimes + contrato de conformidade). Hoje é uma decisão local minha; deveria ser doutrina.

# Ponto 2 — schema canônico vs perfil leve do life-KG

O **life-KG** (dado pessoal) hoje usa um shape **simplificado** no runtime (`{id, type, plane, verified_at, label}`), enquanto o `.kg.yaml` canônico exige `node_type/impact/confidence/status/layer/edges`. Pra o **radar virar gate de escrita real**, o life-KG precisa **adotar o schema canônico**.

**Pergunta:** a doutrina de KG considera o schema canônico **obrigatório para todo KG** (pra radar/reúso valerem), ou existe um **perfil leve sancionado** (subset mínimo) para KGs de captura/pessoais? Isso decide se eu alinho o `kgStore` ao canônico ou se proponho um profile. Orientação, por favor.

# Ponto 3 — KG-as-git-SSOT: o gap de metadados (Q_METADATA_LEAK)

Pesquisa externa (git-remote-gcrypt, SOPS+age-no-git, local-first PKM 2026) confirmou que nossa estratégia é **variante estabelecida**, mas expôs um gap: ciframos o **conteúdo** (`.enc`), mas o remote **ainda vê metadados** — mensagens de commit, grafo, timestamps, **frequência de commits** (vaza padrão comportamental). `git-remote-gcrypt` fecha (cifra a história inteira).

**Pergunta:** se a doutrina de KG toca **durabilidade/sync do KG git-native** (origin=SoT), o **envelope zero-knowledge + superfície de metadados** é uma preocupação de doutrina do core, ou fica local da estrela? Se for do core, o prior-art (git-remote-gcrypt whole-repo, age-wire para interop) já está destilado no nó `E_SYNC_PRIOR_ART`.

# Pedido

Orientação nos **próximos passos** à luz do trabalho de doutrina de KG em curso — em especial: **(1)** kg-radar multi-runtime vira doutrina? **(2)** schema canônico obrigatório vs perfil leve? **(3)** o gap de metadados do git-zero-knowledge é do core? A resposta guia se eu sigo o **loop F1** (`read→de-id→radar-gate→Vercel-AI-SDK→write`) alinhando ao canônico agora, ou espero a doutrina assentar.

> Evidência viva: KG da estrela em `docs/discussions/onion-pessoal-app/research/stack-research-2026-07.kg.yaml` (branch `discuss/onion-pessoal-app`); código em `onion-pessoal-app` (master). Entrega-sem-commit (I3) — a sessão do core commita ao triar.
