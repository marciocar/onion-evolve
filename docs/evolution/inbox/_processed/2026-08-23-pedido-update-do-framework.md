<!-- ATENDIDO 2026-08-23: /meta:adopt --update rodado na PoC (pin b9580a52→595bcb46, merge onion/vendor→main LIMPO 0 conflito, baseline filtrado 47→0, lint 0 HARD). Relatório downstream na inbound/ da PoC. -->
---
title: "Pedido ao core: rodar /meta:adopt --update apontando para esta PoC"
date: 2026-08-23
from: poc-venda-direta-pdi (adotante de campo — PoC)
to: onion-evolve (core)
re: 2026-08-18-elenxo-doctrine-vendorizada (a ação recomendada do anúncio)
type: upstream-signal
classe: COORDENAÇÃO — operação source-driven, o adotante não pode executar
---

# 📦 Pedido de update — o adotante não pode se atualizar sozinho

O anúncio do Elenxo recomenda `/meta:adopt --update` "no momento oportuno". O maestro
autorizou. Mas o **PASSO 0 do comando bloqueia o adotante por desenho**:

```
role: adopted  →  não passa em  grep '^role: (source|hub)'  →  Abortar
```

Correto: é operação **source-driven** (FED-3-1 — consumidor não se re-adota). Então o
pedido é para vocês rodarem, da sessão do core:

```bash
/meta:adopt --update /home/marcio/poc-venda-direta-pdi
```

## Estado deste alvo (verificado agora)

| | |
|---|---|
| pin adotado | `b9580a520e5b` (2026-08-17) |
| pin do core hoje | `9321bad012db` (2026-08-23) |
| delta do manifesto |  36 files changed, 1886 insertions(+), 134 deletions(-) |
| árvore | **limpa**, sincronizada com origin |
| branch de integração | `main` (7 PRs mergeados; `onion/adopt` é a branch de trabalho) |

## O que pedimos que observem no update

1. **`onion/vendor` existe aqui?** A adoção foi em 2026-08-17 com o fluxo novo, mas vale
   confirmar antes do merge — sem a base comum, o helper semeia e o 3-way não acontece
   nesta passada.
2. **Customização local que vai conflitar:** nada em `.claude/` foi editado à mão deste
   lado. O que é nosso vive em `scripts/`, `docs/` (fora de meta-specs/knowledge-base) e
   nos grafos — fora do manifesto. Conflito aqui seria surpresa, não regra.
3. **Gate nativo:** `core.hooksPath .githooks` está ativo e o lint roda a cada commit
   (0 violações HARD hoje). Se o update mexer nas validações, o primeiro commit depois
   dele é o teste — avisem se esperarem mudança de contagem no inventário.

Depois do update, movemos o anúncio do Elenxo para `inbound/_processed/` deste lado e
o ciclo fecha.
