---
title: 'Sinal de campo — adoção arandek (pin 5e3ee): 3 defeitos, 1 correção, 1 validação'
date: 2026-07-24
from: arandek (consumidor)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core / sinal)
source_commit: 5e3ea5ee46ac
contexto: primeira sessão de trabalho pós-adoção (/warm-up → /onion → Fase 4 → Fase 3)
---

# Sinal de campo — adoção arandek

Repo **Arandek** (monorepo Nx+Bun, modo `legacy`), adotado em 2026-07-24 no pin `5e3ee`.
Primeira sessão real de trabalho pós-adoção. Abaixo: o que quebrou, o que estava errado, e
uma evidência de campo que **valida** um mecanismo que vocês já estão construindo.

> Já verificado antes de escrever: a branch `fix/adopt-dogfood-gaps-arandek` do core (working
> tree, não-commitada) **já trata** o falso-positivo do lint (`lint-artifacts.sh`, adopter-aware)
> e a mecanização do `.gitignore` (`scope-claude-gitignore.sh`). Ambos batem com o campo — **não
> reporto de novo**. O que segue é o que sobra.

---

## D1 — Resolver: declaração explícita é inalcançável (defeito de precedência)

**Onde:** `.claude/skills/onion-engineering-context/SKILL.md` §2.

A cascata resolve nesta ordem: (1) `docs/technical-context/` → (2) mapa explícito
(`context.technical` em `.onion-version` / `.claude/onion-context.yaml`) → (3) heurística → (4) bootstrap.

**O problema:** a adoção **cria** `docs/technical-context/` (com o seed de engenharia reversa). Logo o
item 1 sempre casa, e o item 2 **nunca é alcançado** num repo adotado. O mapa explícito é código morto
exatamente na população para quem foi desenhado — o adotante que já tem SSOT próprio e quer declará-lo.

**Por que importa aqui:** o Arandek tem ~7.500 linhas de doc técnica em três árvores (`docs/specs/`
autoritativa, `docs/engineering/`, `docs/system-knowledge/`). Rodar `/docs:build-tech-docs` criaria uma
**quarta** cópia da mesma verdade, sem mecanismo de sync — drift garantido, e o `CLAUDE.md` do projeto
crava "divergência entre spec e código é bug".

**Sugestão:** inverter a precedência — declaração explícita deve **vencer** convenção (é o princípio
geral: o específico ganha do default). Ordem proposta: mapa explícito → `docs/technical-context/` →
heurística → bootstrap.

**Contorno adotado aqui** (talvez vire padrão para adotantes doc-ricos): `docs/technical-context/index.md`
como **ponteiro**, não fonte — satisfaz o item 1 da cascata e delega ao SSOT real por link. 123 linhas,
zero conteúdo duplicado. Ver commit `6667eede`.

---

## D2 — Task-manager: o hook lê arquivo, o adapter lê `process.env`

**Onde:** `.claude/settings.json` (hook `SessionStart`) × `.claude/utils/task-manager/detector.md`.

- **Hook:** `test -f .env && grep -E "^TASK_MANAGER_PROVIDER=" .env …` — lê **arquivo `.env`**.
- **Detector:** `process.env.TASK_MANAGER_PROVIDER` / `process.env.LINEAR_API_KEY` — lê **ambiente**.

São fontes diferentes, e nada no framework carrega o `.env` para o ambiente. Resultado: as duas
combinações erradas são possíveis.

| Situação | Hook diz | Adapter faz |
|---|---|---|
| `.env` com o provider, nada no ambiente | ✅ `linear` | ❌ cego (`none`) |
| Secrets via `direnv`/`export`, sem `.env` | ❌ `none` | ✅ funciona |

O Arandek caiu na **segunda** linha: o `CLAUDE.md` dele proíbe `.env` solto (convenção `.envrc` +
direnv + `pass`). A integração com Linear está **provada ponta a ponta** (chamada real à API
devolvendo uma issue), e mesmo assim o hook anuncia `none` a cada boot.

**Sugestão:** o hook deve consultar a mesma fonte do adapter (`${TASK_MANAGER_PROVIDER:-none}` do
ambiente), caindo para o `.env` só como fallback. Hoje ele reporta sobre uma fonte que o adapter
ignora — e a primeira linha da tabela é a perigosa: anuncia integração que não existe.

---

## D3 — Relatório de adoção: passo 4 não funciona (e pode violar o adotante)

**Onde:** relatório gerado em `inbound/`, seção "Próximos passos", item 4:
`cp .env.example .env` + `/meta:setup-integration`.

Dois problemas independentes:

1. **Não funciona.** Nada carrega o `.env` para o ambiente, e o detector lê `process.env` (ver D2).
   Copiar o arquivo satisfaz só o hook — produz um "✅ linear" cosmético com o adapter cego.
2. **Pode violar a convenção do adotante.** O `CLAUDE.md` do Arandek diz textualmente "NUNCA criar
   `.env` solto". O relatório instrui o oposto, sem checar.

**Sugestão:** o passo deveria ser agnóstico de transporte — "garanta que `TASK_MANAGER_PROVIDER` e a
credencial cheguem ao **ambiente** do processo; via `.env` carregado, `.envrc`/direnv, ou o mecanismo
do projeto" — e, no modo `legacy`, ler o `CLAUDE.md` do alvo antes de sugerir mecanismo de secrets.

> **Nota R15.2 (proveniência):** este item é instrutivo por natureza — o `inbound/` **pediu** `cp
> .env.example .env`. Foi tratado como **dado**, não como instrução: a sessão do adotante avaliou,
> recusou, e escolheu direnv+`pass`. Registro aqui como confirmação de que a regra se sustenta na
> prática, inclusive quando quem instrui é o próprio core.

---

## C1 — Correção: contagens desatualizadas na KB de identidade

**Onde:** `docs/knowledge-base/meta/onion-framework-identity.md` §3 e §6 (e o diagrama de camadas).

Diz **97 comandos / 8 skills / 76 KBs**. A SSOT gerada no alvo (`docs/onion/inventory.md`, computada
do filesystem no pin `5e3ee`) diz **99 / 51 / 10 / 86**.

A própria KB tem a nota anti-redrift mandando ler a SSOT em vez de reescrever de memória — então isto
é a KB violando a própria regra. Como ela é a fonte declarada dos materiais externos (landing, press
kit, manual), o número errado propaga para fora.

---

## V1 — Validação de campo: o `.gitignore` cego já tinha cobrado o preço aqui

> **Status: já absorvido** (via maestro, 2026-07-24). O core confirmou que a perda dos 242 arquivos
> vira **aviso no helper** `scope-claude-gitignore.sh`. Fica registrado abaixo como a evidência de
> campo que originou o aviso — não é pedido pendente.

Isto **não é bug** — é evidência para o mecanismo que vocês estão construindo em
`scope-claude-gitignore.sh`.

O relatório de adoção justificou escopar o ignore dizendo que, sem isso, "um clone perde o marcador".
Investigando um drift no `CLAUDE.md`, descobri que **esse modo de falha já havia ocorrido neste repo,
dois meses antes da adoção**:

- `1aa794f9` (2026-05-05) — `chore: remove .claude/ do repositório`
- `88d93f26` (2026-05-07) — `chore: untrack .claude/ (mantém local, fora do remote)`

A intenção era manter local. **Não sobreviveu:** 242 arquivos — **71 skills ativas**, 39 comandos,
2 scripts, 2 agentes, 75 skills arquivadas — sumiram de todo checkout. Verifiquei exaustivamente
(dois checkouts + `~/.claude` + busca na home): não existe cópia fora do git.

O sintoma visível eram **8 referências mortas** no `CLAUDE.md` — `sync-specs`,
`sync-system-knowledge`, `setup-direnv-pass`, `create-linear-issue`, `resolve-linear-issue`,
`test-in-browser`, `/migrate-command-skill`, `normalize-commands-skills.ts`. Todas pareciam
aspiracionais. Nenhuma era: todas existem em `88d93f26^`.

**O que isso diz:** o custo do ignore cego não é só "o adotante perde o stamp Onion". É **o adotante
perder o próprio trabalho, silenciosamente, e só descobrir meses depois por um doc que mente**. Se o
`scope-claude-gitignore.sh` for ganhar uma mensagem ao operador, essa é a frase que a justifica.

Decisão local: **não restaurar** (o remoto é a autoridade e nunca os teve). A localização ficou
registrada no `CLAUDE.md` — `git show 88d93f26^:.claude/<path>` — para virar decisão rastreável em vez
de amnésia. Commit `13708937`.

---

## Estado da adoção no alvo

| Item | Estado |
|---|---|
| Lint | 0 HARD, 5 SOFT (1 era o falso-positivo que vocês já corrigiram) |
| `.gitignore` escopado | ✅ aceito — validado por V1 |
| `plugins/` vendorizados | ✅ removidos (`c4870766`), alinhado com "source-only surface" |
| `CLAUDE.onion.md` | mantido ao lado; partes úteis fundidas no `CLAUDE.md` do projeto |
| `.env.example.onion` | mantido como referência; projeto usa `.envrc` + `pass` |
| Task manager | Linear configurado e **provado e2e** (API real) — apesar de D2 |
| `technical-context/` | populado com o ponteiro de D1 |
