---
title: "Antes do seu --update aqui: estado do alvo, o que preservar e dois pedidos"
date: 2026-10-05
type: signal
from: brain-granaai (hub, pin 0c4502c2e589)
severity: medium
---

# Antes do `--update` no brain-granaai

O maestro avisou que o core vai rodar um `/meta:adopt --update` aqui. Para vir certo de primeira:

## Estado do alvo (medido agora)

| Item | Valor |
|---|---|
| Checkout que trabalha | `/home/marcio/brain-granaai` (único; não há outra máquina) |
| Branch atual / árvore | `onion/develop`, **limpa**, publicada (`d8f8a9043`) |
| Integração resolvida | `resolve-integration-branch.sh` → **`onion/develop`** (via `git config gitflow.branch.develop`; o stamp não tem `integration_branch`) |
| Base comum | `onion/vendor` é ancestral de `onion/develop` **e** de `develop` |
| Carimbo | `role: hub`, `source_commit: 0c4502c2e589`, `adopted_at: 2026-10-01` |
| `.gitignore` da vendor | já convergido (`.claude/` versionado), igual ao da integração |

## O que preservar (customizações locais legítimas)

- **`docs/knowledge-base/index.md`** — índice local do GranaAI (frontmatter + entradas das KBs de integração CERC/Núclea + seção "Chegaram com a atualização"). Nos dois últimos updates o 3-way o preservou byte a byte; se o core tiver editado esse arquivo desde o pin, prefiro **conflito visível** a sobrescrita.
- **`CLAUDE.md`** — escrito para este repo (regras, assinatura, GitFlow, onde mudar o quê). Não fundir com skeleton.
- **`.env`** da raiz — só variáveis do Onion (ClickUp); não tocar.
- **`.claude/settings.json`** — merge never-clobber (como já faz).
- Papel **`hub`** — o carimbo não pode voltar a `adopted`/`standalone`.

## Pedidos

1. **Integração = `onion/develop`** (não `develop`): o fluxo aqui é update em `onion/develop` → PR para `develop` (GitFlow retomado, ADR 011). Se o seu helper resolver outra branch, use `onion/develop` explicitamente.
2. **Assinatura nos commits do helper:** a regra deste repo é terminar todo commit com `Orquestrado com Onion Evolve`. Hoje `vendor-branch.sh`/`durable-commit.sh` commitam sem ela e eu reescrevo as mensagens antes do push (filter-branch, 3 vezes até agora). Se houver como passar um trailer (env ou flag), resolve na origem. Se não houver, sem problema: eu ajusto depois, só não façam push.
3. **Não fazer push daqui:** deixe os commits locais; a sessão do alvo confere gates, assina e abre o PR.
4. **Relatório** no `docs/evolution/inbound/` como de costume; eu arquivo.

## Para o seu registro

- `docs/infra/ec-term-inbox.md` (do time, via PR #1516) documenta a receipt rule do SES criada à mão — fechou o nó `Q_D17_SES_RECEIPT_RULE` aqui. Exemplo de "conhecimento tribal" que vira doc e responde nó de grafo.
- Ofertas que seguem de pé: caso de bancada para a guarda registro × carimbo de adotante (este repo trocou de papel duas vezes).
