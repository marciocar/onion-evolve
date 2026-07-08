---
name: build-index
description: Gerar e atualizar índices de documentação em docs/ a partir da estrutura real (contagens escaneadas, nunca hardcoded).
model: sonnet
category: docs
tags: [index, navigation, documentation, spec-as-code]
version: "3.1.0"
updated: "2026-06-13"
allowed-tools: Read Write Edit Glob Grep Bash(find *) Bash(ls *) Bash(wc -l *)
argument-hint: "[seção opcional: knowledge-base | business-context | technical-context | compliance-context | onion | meta-specs]"
---

# Build Index — Índices de Documentação

## Objetivo

Gerar/atualizar os índices de `docs/` (o hub `docs/INDEX.md` e os `index.md` de seção) **a partir da estrutura real** do repositório. Mantém a navegação organizada, os links válidos e as contagens corretas.

> **Princípio evergreen (obrigatório):** **NUNCA** escreva contagens, listas ou métricas hardcoded de memória — elas estagnam (foi o que aconteceu com versões anteriores deste comando). **Sempre escaneie** o filesystem na hora da execução e derive os números de lá. Relacionado: skill `language-standards` e a premissa de frescor em `/meta:kb-freshness`.

## Quando usar

- Após adicionar/remover/renomear docs ou KBs.
- Após mudanças estruturais (novas categorias, dedup, renomeações).
- Para corrigir links mortos ou contagens desatualizadas num índice.
- Junto com `/meta:kb-freshness` (frescor de conteúdo) e `/docs:validate-docs`.

## Estrutura real de `docs/` (descobrir dinamicamente)

Não assuma esta lista — confirme com `find docs -maxdepth 1 -type d`. Tipicamente:

| Seção | Conteúdo | Observação |
|---|---|---|
| `INDEX.md` | hub central de navegação | gerado por este comando (sem argumento) |
| `knowledge-base/` | KBs por categoria (`concepts/`, `frameworks/`, `tools/`, `platforms/`, `patterns/`, `architectures/`, `meta/`) | tem `index.md` próprio |
| `meta-specs/` | constituição L0 (agents, commands, architecture, code-standards, integrations) | tem `index.md` |
| `onion/` | documentação operacional (guias, referências) | tem `index.md` |
| `business-context/` | contexto de negócio (spec-as-code) | **template** no framework (só `README.md`); **populado no projeto-alvo** por `/docs:build-business-docs` |
| `technical-context/` | contexto técnico (C4/ADR, spec-as-code) | **template** no framework; populado no alvo por `/docs:build-tech-docs` |
| `compliance-context/` | contexto de compliance (ISO/SOC2/PMBOK) | **template** no framework; populado no alvo por `/docs:build-compliance-docs` |
| `analysis/`, `plans/`, `applying/`, `sdaal/` | análises datadas, planos, guias, KB SDAAL | indexados a partir do `INDEX.md` |

## Etapas

**Argumento recebido**: `$ARGUMENTS` — vazio reconstrói o hub; uma seção reconstrói só o `index.md` dela.

### `/docs:build-index` (sem argumento) — reconstrói o hub `docs/INDEX.md`

1. **Escanear** `docs/` (`find docs -maxdepth 1 -type d`) e `.claude/` (comandos, agentes, skills) para **contar recursos na hora** (`find ... | wc -l`).
2. **Ler** o `index.md`/`README.md` de cada seção para extrair título e descrição.
3. **Gerar** `docs/INDEX.md` com: visão geral, estatísticas (contadas), estrutura, navegação por perfil e links de seção.
4. **Validar links**: cada caminho referenciado deve existir (`test -f`); remover/corrigir links mortos.

### `/docs:build-index <seção>` — reconstrói o `index.md` daquela seção

1. Resolver a pasta (`docs/<seção>/`); abortar com aviso se não existir.
2. Percorrer arquivos e subpastas reais; **contar dinamicamente**.
3. Gerar/atualizar `docs/<seção>/index.md` com links relativos corretos.
4. Para os **3 contextos** (`business-context`, `technical-context`, `compliance-context`): refletir o **estado real** — no framework são templates (só `README.md`, marcar como "template, populado no projeto-alvo"); num projeto-alvo, indexar o conteúdo gerado pelos comandos `build-*-docs`.

## Saída esperada

- `docs/INDEX.md` (ou `docs/<seção>/index.md`) atualizado, com contagens reais e **zero links mortos**.
- Resumo ao usuário: seções tocadas, nº de arquivos por categoria (escaneados), links corrigidos/removidos.

## Exemplos

```bash
/docs:build-index                      # reconstrói o hub docs/INDEX.md
/docs:build-index knowledge-base       # reconstrói docs/knowledge-base/index.md
/docs:build-index business-context     # indexa o contexto de negócio (template ou populado)
/docs:build-index technical-context    # indexa o contexto técnico
/docs:build-index compliance-context   # indexa o contexto de compliance
```

## Notas

- **Contagens vêm do scan**, nunca de memória — releia a estrutura a cada execução.
- Os 3 contextos são **spec-as-code** (`architecture.md §1.3`): vazios/template no framework, populados no projeto-alvo.
- Este comando **não cria conteúdo** de contexto — para isso use `/docs:build-business-docs`, `/docs:build-tech-docs`, `/docs:build-compliance-docs`.

## Referências

- Hub: `docs/INDEX.md`
- Geração de contexto: `/docs:build-business-docs`, `/docs:build-tech-docs`, `/docs:build-compliance-docs`
- Frescor de conteúdo: `/meta:kb-freshness`
- Validação: `/docs:validate-docs`
