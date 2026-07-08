---
title: 'Sinal de campo — .gitignore blanket /docs/ (linha 105) engolia docs/evolution/inbox/ do próprio doc-bridge'
date: 2026-07-07
from: granaai (adotante standalone, regulated)
to: onion-evolve (core / "mestre")
re: PR #1094 (reconciliação, mergeado) + PR #1096 (fix .gitignore, mergeado)
type: federation-doc-bridge (feedback de adoção — não-solicitado)
status: corrigido (PR #1096 mergeado em develop, 2026-07-07). Provenance: este sinal foi
  RECONSTRUÍDO pelo core a partir do comentário verbatim de Mauricio Matos no PR #1094
  (2026-07-07T01:40:44Z) — a entrega original pelo canal normal (inbox do adotante +
  /meta:co-relay) NÃO chegou. Verificado 2026-07-07: ausente em todas as branches do
  granaai (pós-fetch) e no inbox do core. Conteúdo técnico é 100% dele; a materialização
  como sinal formal é nossa, não relayada por ele.
---

# Sinal de campo — o bug real do `.gitignore` não era onde parecia (2026-07-07)

## O achado (Mauricio Matos, granaai, comentário no PR #1094)

Ao reconciliar o PR #1094, o `.gitignore` do granaai deixou de ignorar `docs/*` na linha 109
(ajuste já feito antes) — mas continuava ignorando artefatos de `docs/` porque o culpado real
era **outra linha, uma acima**:

> O culpado real **não** é `/docs/*` (linha 109) e sim `/docs/` na **linha 105** — quem o git
> honra primeiro:
> ```
> $ git check-ignore -v docs/technical-context/novo.md
> .gitignore:105:/docs/   docs/technical-context/novo.md
> ```
> Corrigir só `/docs/*` não resolveria.

**Evidência colateral que motiva este sinal especificamente**: essa mesma regra engolia
`docs/evolution/inbox/` — o canal que o doc-bridge usa pra falar com o core.

> Evidência divertida: até o `docs/evolution/inbox/` do próprio doc-bridge cai nessa regra —
> o sinal de resposta a este PR precisou de `git add -f` pra ser commitável.

## Por que isso interessa ao core, não só ao granaai

1. **Blanket `/docs/` sem exceção explícita quebra o canal de co-evolução silenciosamente** — um
   adotante pode achar que está "sem sinais pra mandar" quando na verdade está sendo bloqueado
   pelo próprio `.gitignore` do projeto, sem erro visível (o arquivo simplesmente nunca vira
   staged, a menos que alguém pense em `-f`).
2. **`/meta:adopt` já preserva regras específicas de `docs/` no gitignore-merge** (não sobrescreve
   o padrão do projeto-alvo, doutrina "adota, não impõe") — mas isso significa que um adotante com
   uma regra `/docs/` legada e larga demais **herda o próprio problema**, e nada no fluxo de adoção
   detecta isso hoje.
3. **Candidato a checagem no `/meta:adopt` ou no lint vendorizado**: verificar, na instalação ou no
   `--update`, se `git check-ignore -v docs/evolution/inbox/README.md` (ou qualquer caminho
   canônico do doc-bridge) resolve para "não ignorado" — um `git add -f` funcionando por acidente
   não é o mesmo que o canal estar saudável por padrão.

## Correção aplicada (granaai)

PR #1096 — remove as duas regras blanket (`/docs/` linha 105 e `/docs/*` linha 109), preserva as
exclusões pontuais do projeto, mantém `apps/docs` intacto. Mergeado em `develop`, 2026-07-07.

## Ação sugerida ao core (não urgente — flow C, insumo de evolução)

Avaliar, num próximo `/meta:evolve` ou revisão do `/meta:adopt`, se vale adicionar essa checagem
de "canal do doc-bridge não pode estar gitignored" ao script de validação pós-adoção. Sem
gatilho numérico definido — fica como candidato até um 2º adotante reportar o mesmo padrão.

## Triagem 2026-07-08 (core)

**Veredito: BACKLOG — candidato de evolução, GATED (não implementar agora).**

- **Estado no adotante:** já corrigido (granaai PR #1096, mergeado em develop 2026-07-07). Não há
  bug ativo no core — o sinal é insumo/candidato, não defeito.
- **Teste do 2º adotante (feito na triagem):** durante o `/meta:adopt --update` de
  `rhilo-metagamify` (2026-07-08), verificado com `git check-ignore -v` que o canal do doc-bridge
  (`docs/evolution/inbox/README.md`, `_processed/.gitkeep` de inbox e inbound) **NÃO está
  gitignored** e o repo **não tem regra blanket `/docs/`**. O padrão **não recorreu**.
- **Consequência:** o gatilho declarado ("candidato até um 2º adotante reportar o mesmo padrão")
  **não foi atendido** → a checagem não deve ser construída ainda.
- **Critério de reabertura:** um 2º adotante reproduzir uma regra `docs/` larga demais que engula
  `docs/evolution/`. Aí promover a checagem no `/meta:adopt` (pós-adoção) ou no lint vendorizado.
- **Disposição:** movido para `_processed/`; registrado como observação de diário para reaparecer
  num futuro `/meta:evolve`. Sem CHANGELOG/anúncio (nada muda para adotantes).
