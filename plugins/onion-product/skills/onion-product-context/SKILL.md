---
name: onion-product-context
description: >
  Contrato de SSOT mínimo e resolver de contexto da vertical de PRODUTO do Onion.
  Use ao rodar qualquer comando de produto (collect/refine/spec/feature, task,
  estimate, analyze-pain-price, branding) para localizar o contexto de NEGÓCIO do
  projeto — mesmo quando o repo NÃO segue o layout Onion padrão (sem
  docs/business-context/). Resolve onde ler/gravar o contexto vivo de negócio, faz
  bootstrap de um stub mínimo quando ausente, e aponta o KB de framework embarcado
  (story points, pain-price, extração de reuniões). Ative mesmo sem o usuário
  mencionar "contexto" ou "SSOT".
---

# Contexto de Produto — contrato SSOT mínimo + resolver

Garante que a vertical de produto **sabe onde está o seu SSOT de negócio** em qualquer projeto —
adotado ou não. Separa dois tipos de conhecimento:

- **KB de framework (tipo A)** — métodos estáveis do Onion (story points, pain-price, EXTRACT de
  reuniões). **Viaja embarcado no plugin.**
- **Contexto vivo (tipo B)** — o negócio DO CONSUMIDOR (problema, cliente, proposta de valor, mercado).
  É dado dele; **não** viaja no plugin. Esta skill o **resolve** (ou faz bootstrap).

## 1. KB de framework (tipo A) — onde consultar

Os frameworks que os comandos citam estão **embarcados**:
- **Como plugin**: em `${CLAUDE_PLUGIN_ROOT}/kb/` — ex.: `framework-story-points.md`,
  `identificar-precificar-dor-cliente.md`, `meeting-transcription-to-knowledge-base.md`.
- **No Onion completo**: em `docs/knowledge-base/frameworks/` e `docs/knowledge-base/concepts/`.

Ao estimar, precificar dor ou extrair reunião, **leia do KB embarcado** — não assuma
`docs/knowledge-base/` no projeto do consumidor.

## 2. Contexto de negócio do consumidor (tipo B) — resolver

Para ler/gravar o contexto de negócio vivo (problema, cliente, proposta de valor, mercado,
métricas), resolva o caminho **nesta ordem** e use o primeiro que existir:

1. **Layout Onion padrão**: `docs/business-context/` (índice em `docs/business-context/index.md`).
2. **Mapa explícito**: chave `context.business` em `.onion-version` (JSON) ou `.claude/onion-context.yaml`.
3. **Heurística de layout comum**: `contexto-projeto.md` · `docs/INDEX.md` (catálogo) ·
   `docs/base-conhecimento-*.md` (KB/RAG do produto) · `README.md` · `PRODUCT.md`/`VISION.md`.
4. **Bootstrap** (só com confirmação): criar o stub mínimo (seção 3) e passar a usá-lo.
5. **Degradação honesta**: nada existe e o usuário recusa o bootstrap → **prosseguir declarando**
   "não encontrei SSOT de negócio — operando sem ele" e **nunca inventar** dados de mercado/cliente.

## 3. SSOT mínimo (a "estrutura mínima" garantida)

O contexto de negócio mínimo é **um arquivo** com estas seções. No bootstrap, criar em
`docs/business-context/index.md` (ou no caminho resolvido):

```markdown
# Contexto de Negócio — <projeto>

## Problema & Cliente
<qual dor, de quem — 1 parágrafo>

## Proposta de valor
<o que entrega, por que importa>

## Mercado & Concorrência
<tamanho, alternativas, diferencial>

## Métricas / Objetivos
<o que se mede; metas atuais>
```

Manter vivo (atualizar a cada discovery/spec) é o contrato. É o piso: num projeto adotado,
`docs/business-context/` completo o supera.

## 4. Regra de ouro

- **Tipo A** (framework) → sempre do KB embarcado; independe do consumidor.
- **Tipo B** (negócio) → resolver → bootstrap → degradar **honesto**. Nunca assumir path fixo.
- Ao não achar, **dizer** — declarado ≠ verificado. Ver `[[onion-dogfooding-doctrine]]`.
