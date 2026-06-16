---
name: adopt
description: |
  Adota um repositório/pasta no Sistema Onion: recebe um caminho local ou URL git
  e instala o framework (modelo durável) ou opera in-place (efêmero), faseado e
  retomável. Greenfield-first. NÃO é CLI — roda dentro do Claude Code.
  Relacionado: /docs:reverse-consolidate, /meta:setup-integration, /docs:build-tech-docs.
model: sonnet
allowed-tools: Bash Read Write Edit Glob Grep
argument-hint: "<path-local | git-url> [--mode greenfield|legacy|regulated] [--in-place] [--dry-run]"
category: meta
version: "1.0.0"
updated: "2026-06-16"
---

# 🧅 /meta:adopt — Adoção de Repositório

## Objetivo

Operacionalizar a doutrina [`docs/applying/`](../../../docs/applying/README.md) como **comando
faseado**: apontar o Onion para um repo/pasta e "assumir o controle" — **instalar** o framework
(durável) ou **operar in-place** (efêmero), reusando atuadores existentes. Greenfield-first.

> **Decisão de design:** [ADR de Adoção](../../../docs/analysis/onion-adr-repo-adoption-2026-06.md).

## Identidade e fronteiras (do ADR — inegociável)

- **NÃO é CLI standalone** (invariante `architecture.md §5/§7`). Roda **dentro** de uma sessão
  Claude Code que **já tem** o framework Onion (a *fonte*); o alvo é o argumento.
- **"Controle" = um de dois modelos:**
  - **Instalar** (default) — copia o framework **para dentro** do alvo → vira **Onion soberano**.
  - **Operar in-place** (`--in-place`) — monta o alvo como working directory auxiliar e opera
    **sem instalar nada** (controle efêmero; bom para análise one-off).
- **Alto impacto:** escreve em repo alheio → o **Contrato de Segurança** abaixo é obrigatório.

## Quando usar

- Trazer um projeto novo/legado/regulado para o ciclo Onion (produto + engenharia + compliance).
- Preparar um repo para virar **membro soberano da federação** (rampa de entrada).
- Rodar uma análise Onion pontual sobre um repo externo (`--in-place`).

---

## 🛡️ Contrato de Segurança (OBRIGATÓRIO)

1. **Dry-run primeiro.** `--dry-run` (ou sempre, na 1ª passada) **lista** o que seria clonado/copiado/
   criado e **não escreve nada**. Só aplica após **confirmação explícita** do usuário.
2. **Branch dedicada.** Aplicar em `onion/adopt` (ou worktree) no alvo — **nunca** na branch default
   sem consentimento. Em alvo sem git, inicializar antes.
3. **Never-clobber.** Se o alvo **já tem** `.claude/`, é **re-adoção**: comparar (diff) e **atualizar**,
   **nunca** sobrescrever cego. Conflitos → parar e reportar.
4. **Idempotente.** Re-adotar = atualizar a superfície + re-carimbar o stamp, não duplicar.

---

## ⚡ Fluxo de Execução (faseado, retomável)

> Cria sessão `.claude/sessions/adopt-<slug>/STATE.md` (ponteiro `NEXT`) para retomar — protocolo
> em [worklog-protocol.md](../../../docs/knowledge-base/concepts/worklog-protocol.md).

### PASSO 0 — Precondições e resolução do alvo

1. **Confirmar a fonte:** `bash .claude/validation/onion-version.sh` deve emitir `role: source`.
   Se não, abortar (esta sessão não tem o framework para instalar).
2. **Resolver o alvo** (`$1`):
   - caminho local existente → usar;
   - URL git → `git clone` para destino e usar.
3. **Detectar MODO** (ou `--mode`):
   - **greenfield** — alvo vazio/sem código (este MVP detalha este modo);
   - **legacy** — alvo tem código (ver §Modos);
   - **regulated** — `--mode regulated` ou marcadores de compliance (ver §Modos).
4. Criar a sessão de adoção (`STATE.md`).

### Fase 1 — Engenharia reversa (se houver código)

- **greenfield:** pular (nada a reverter).
- **legacy/regulated:** rodar o fluxo de `/docs:reverse-consolidate <target>` (delega a
  `@docs-reverse-engineer`) → consolida stack/estrutura; alimenta `technical-context`.

### Fase 2 — Instalar o framework  _(modelo "instalar"; pular se `--in-place`)_

**Manifesto da superfície instalável** — o que vai para `<target>` (respeitando `architecture.md §3`:
**zero path absoluto**):

| Inclui | Exclui (framework-internos) |
|---|---|
| `.claude/{agents,commands,skills,utils,validation}` | `.claude/sessions/` |
| `docs/{meta-specs,knowledge-base,sdaal}` | `docs/analysis/` · `docs/materials/` · `docs/applying/` |
| templates de `docs/{business,technical,compliance}-context/` | `docs/INDEX.md` da fonte (regenerar) · `.git` |
| `.env.example` | `.claude/.onion-version` da fonte (a fonte não tem; ver Fase 5) |

- **Dry-run:** listar arquivos a copiar/criar (diff vs alvo) e **pedir confirmação**.
- Copiar para a branch `onion/adopt`; **never-clobber** (se existe, reportar diff).

### Fase 3 — Scaffold de contextos + `CLAUDE.md` do alvo

- Criar `docs/{business,technical,compliance}-context/` a partir dos templates (vazios, prontos para
  `/docs:build-*-docs`).
- **Gerar** o `CLAUDE.md` do **alvo** (NÃO copiar o da fonte — o da fonte descreve *o framework*).
  Mínimo: identidade do projeto-alvo + roteamento Task Manager + diretrizes de idioma + entrada `/onion`.
- Regenerar `docs/INDEX.md` do alvo (`/docs:build-index`).

### Fase 4 — Configurar integrações (`.env`)

- Rodar `/meta:setup-integration` no alvo (Task Manager etc.). Fallback gracioso se pulado.

### Fase 5 — Carimbar versão (stamp de proveniência)

- Ler a identidade da fonte: `bash .claude/validation/onion-version.sh --json`.
- Escrever `<target>/.claude/.onion-version` (`role: adopted`) — schema em `architecture.md §6.1`:
  ```yaml
  framework: onion-claude
  source_commit: <commit da fonte agora>
  source_commit_date: <YYYY-MM-DD>
  role: adopted
  adopted_from: <repo/URL da fonte>
  adopted_at: <data de hoje>
  mode: greenfield | legacy | regulated
  ```
- Se o alvo versiona `.claude/`, **committar** `.onion-version` (proveniência durável).

### Fase 6 — Relatório + próximos passos

- Resumo: superfície instalada, modo, stamp, branch (`onion/adopt`).
- Próximos no alvo: `/warm-up` → `/onion` → `/docs:build-tech-docs`.
- **Rampa da federação:** oferecer registrar o alvo como membro (`members.yaml`) — ver
  [multi-repo-federation.md](../../../docs/knowledge-base/concepts/multi-repo-federation.md).

---

## Modos

| Modo | Diferença | Status |
|---|---|---|
| **greenfield** | scaffold + instalação; reverse-eng mínima | ✅ MVP (este comando) |
| **legacy** | reverse-eng pesada, migração gradual, **worktree obrigatório**, never-clobber reforçado | 🔜 iteração 2 |
| **regulated** | + `compliance-context` populado + agentes de compliance (ISO/SOC2/PMBOK) | 🔜 iteração 2 |

## Operar in-place (`--in-place`)

Não copia nada. Adiciona `<target>` como **working directory auxiliar** e opera com agentes/comandos
Onion sobre ele. Controle **efêmero** — o repo **não** vira Onion. Ideal para análise/relatório one-off
(ex.: `@docs-reverse-engineer` + relatório) antes de decidir instalar.

## Idempotência / re-adoção

Alvo com `.claude/` existente → **atualizar**: diff da superfície instalável, aplicar só o que mudou,
re-carimbar `.onion-version` (novo `source_commit`/`adopted_at`). **Nunca** duplicar nem clobrar.

---

## 🔗 Referências

- **Decisão:** [ADR de Adoção](../../../docs/analysis/onion-adr-repo-adoption-2026-06.md)
- **Doutrina:** [`applying/`](../../../docs/applying/README.md) (greenfield/legacy/regulated)
- **Stamp:** `.claude/validation/onion-version.sh` · `architecture.md §6.1`
- **Atuadores reusados:** `/docs:reverse-consolidate` · `/meta:setup-integration` · `/docs:build-*-docs` · `/docs:build-index`
- **Rampa a jusante:** [federação multi-repo](../../../docs/knowledge-base/concepts/multi-repo-federation.md)
