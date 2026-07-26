---
name: {{PROJECT}}-context
description: >
  Contrato de SSOT mínimo e resolver de contexto (book) da vertical {{PROJECT_TITLE}}.
  Use ao rodar qualquer comando de {{PROJECT_TITLE}} para localizar o book/SSOT do projeto
  — mesmo quando o repo não segue um layout padrão. Resolve onde ler/gravar o contexto vivo,
  faz bootstrap de um stub mínimo quando ausente, mostra antes de salvar e NUNCA inventa.
  Ative mesmo sem o usuário mencionar "contexto", "book" ou "SSOT".
---

# 📚 {{PROJECT_TITLE}} — Resolver de SSOT (book)

Localiza e valida o **book/SSOT** da vertical {{PROJECT_TITLE}}: onde vive o contexto vivo do
projeto, o contrato mínimo que ele deve ter, e como fazer bootstrap quando falta — sempre
**mostrando antes de salvar** e **nunca inventando**.

## Cadeia de resolução (primeiro que casar vence)

1. **Mapa explícito** — campo apontando o book em `.onion-version` / `.claude/onion-context.yaml`.
   **Declaração vence convenção** — o específico ganha do default (senão, como a adoção CRIA
   `docs/{{PROJECT}}-context/`, o layout padrão sempre casaria antes e o mapa viraria código morto;
   sinal de campo 2026-07/D1).
2. **Layout padrão** — `docs/{{PROJECT}}-context/` (ou o diretório de book do projeto).
3. **Heurística** — arquivos de contexto comuns na raiz (`README.md`, `docs/INDEX.md`, o book do projeto).
4. **Bootstrap só com confirmação** — se nada casar, proponha criar o stub mínimo (abaixo) e **confirme**.
5. **Degradação honesta** — ao não achar, **declare** "não encontrei SSOT — operando sem ela" e siga.
   Declarado ≠ verificado; **nunca invente** o conteúdo do book.

## Contrato de SSOT mínimo (o piso, não o teto)

Um arquivo do book de {{PROJECT_TITLE}} com, no mínimo, seções para:
- **Estado/entidades** — o que o projeto rastreia (as fichas do book).
- **Decisões** — o que foi decidido e por quê.
- **Convenções** — como as coisas são nomeadas/estruturadas nesta vertical.

## Gestão do book (o que o hub `{{PROJECT}}` delega aqui)

Criar / editar / atualizar / validar fichas do book — **mostrando o diff antes de salvar**,
nunca sobrescrevendo às cegas (never-clobber), nunca inventando campo que a fonte não tem.

> Gerado por `bootstrap-new-project.sh`. Ajuste a cadeia e o contrato ao domínio real de {{PROJECT_TITLE}}.
