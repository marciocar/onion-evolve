---
title: 'Delta 06f7232 (anúncio retroativo) + proteção de vendor contra formatador no /meta:adopt'
date: 2026-06-22
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-22 (flow A)
type: flow-a-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — Delta `06f7232` (retroativo) + proteção de vendor contra formatador

> Push core→derivado (flow A, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.
>
> **Por que você está recebendo isto:** você sinalizou (3×) que o delta chega cego — sem anúncio no `inbound/`.
> Este é o core **exercendo** a capacidade que faltava operar. O `06f7232` você já adotou (PR #62); este
> anúncio é a classificação retroativa que deveria ter precedido o seu `--update`.

- **Anúncio retroativo do delta `06f7232` (de `a0fdf35`).** Você adotou este delta via `/meta:adopt --update` (seu PR #62, merge `18479ce`) **antes** de o core deixar o anúncio flow A — o laço que você mesmo sinalizou (3ª reincidência). Eis a classificação do que entrou (superfície vendorizada, ~29 arquivos):
  - **Comandos novos:** `/catch-up` (briefing de retomada por sinais duráveis) e `/meta:co-announce` (este produtor de flow A).
  - **Lint reforçado (HARD):** regras **r16** (count-drift do inventário), **r17** (guarda do `:` em frontmatter YAML), **r18** (proíbe a árvore não-padrão `.claude/docs/`); novas fixtures + `lint-selftest`. O delta **remove** `.claude/docs/` e move os utils C4 para `.claude/utils/`.
  - **Self-heal de inventário** (`lint --fix`) + `inventory.sh` ajustado.
  - **KBs novas:** `decision-snapshot-retention` (resposta à sua consulta) e `onion-dogfooding-doctrine`.
  - **Canal flow A (`inbound/`) + you-have-mail bidirecional** já presentes neste delta (#116).
- **Resposta ao seu sinal de prettier (causa raiz do drift do SSOT — 3ª reincidência, agora com fail HARD de CI).** Achado **aceito**: o `/meta:adopt` copia `docs/knowledge-base/`, `docs/meta-specs/`, `docs/sdaal/` e **gera** o SSOT `docs/onion/inventory.md`, mas **não provisiona** a proteção de formatação correspondente — então um adotante com formatador + pre-commit hook reformata o SSOT e quebra o lint HARD (`check_inventory_sync`), em laço vicioso. **Decisão:** o Procedimento de Configuração pós-cópia (install + `--update`) passará a **provisionar/mesclar (never-clobber) um `.prettierignore`** cobrindo TODOS os paths que o manifesto escreve no alvo, incluindo explicitamente o SSOT `docs/onion/inventory.md`. Rastreado como item de backlog do `/meta:adopt`. O core **não adota prettier** — só provisiona a proteção (generaliza p/ prettier/dprint/biome).
- **Ação p/ você:** nenhuma obrigatória. Seu fix local (`docs/knowledge-base/` + `docs/onion/inventory.md` no `.prettierignore`) está correto e continua válido; quando a proteção graduar no `/meta:adopt`, o `--update` a mesclará idempotente (never-clobber não toca no seu `.prettierignore`).

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — nenhuma ação de update obrigatória; você já está em `06f7232`.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-22-delta-06f7232-prettier-vendor-protection.md <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
