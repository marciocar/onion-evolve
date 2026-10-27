---
name: onion-design-context
description: >
  Contrato de SSOT mínimo e resolver de contexto da vertical de DESIGN do Onion.
  Use ao rodar qualquer comando de design (setup, identity, generate, deck) ou o
  @design-system-specialist para localizar o contexto de IDENTIDADE VISUAL do
  projeto — brief, tokens W3C DTCG e o grafo do design-context — mesmo quando o
  repo NÃO segue o layout Onion padrão (sem docs/design-context/). Resolve onde
  ler/gravar, faz bootstrap de um stub mínimo do brief quando ausente (com
  confirmação), e diz como o grafo do design se liga ao business-context e ao
  technical-context. Ative mesmo sem o usuário mencionar "contexto" ou "SSOT".
---

# Contexto de Design — contrato SSOT mínimo + resolver

Garante que a vertical de design **sabe onde está o seu SSOT de identidade visual** em qualquer projeto —
adotado ou não. Separa dois tipos de conhecimento:

- **Framework (tipo A)** — o método estável do Onion: o formato W3C DTCG, o gate de tokens
  (`lint-design-tokens.sh`: DTCG bem-formado, alias sem órfã nem ciclo, contraste WCAG), o design-sink e o
  design-source. **Viaja embarcado** (plugin `onion-design`).
- **Contexto vivo (tipo B)** — a identidade DO CONSUMIDOR: o brief, os tokens e o grafo. É dado dele; **não**
  viaja. Esta skill o **resolve** (ou faz bootstrap).

> **Contexto ≠ dimensão.** O design-context é contexto de primeira classe; a doutrina das três dimensões
> (produto, engenharia, compliance) só muda quando o gatilho medido do core disparar (dois adotantes rodando
> o ciclo inteiro). Esta skill não afirma uma 4ª dimensão.

## 1. Onde mora o contexto de design (tipo B) — resolver

Resolva **nesta ordem** e use o primeiro que existir:

1. **Mapa explícito**: chave `context.design` em `.claude/onion-context.yaml` (ou `.onion-version` JSON).
   **Declaração explícita vence convenção.** Os passos 1 e 2 são executáveis:
   `bash .claude/utils/scope/resolve-context-dir.sh design` imprime a pasta (exit 3 = declaração inválida: pare).
2. **Layout Onion padrão**: `docs/design-context/` (índice em `docs/design-context/index.md`).
3. **Heurística de layout comum**: `tokens/`, `design-tokens/`, `src/theme/`, `tailwind.config.*`,
   `components.json` (shadcn), um `BRAND.md`/`STYLEGUIDE.md`. Achou tokens fora do padrão → **leia, não mova**.
4. **Bootstrap** (só com confirmação): `/design:setup`, que parte do brief que existe e só cria o stub
   mínimo (seção 2) quando não há brief **e** o usuário confirma.
5. **Degradação honesta**: nada existe e o usuário recusa → prosseguir declarando "não encontrei SSOT de
   design — operando sem ele". **Nunca inventar** cor de marca, público ou tom.

## 2. SSOT mínimo (a "estrutura mínima" garantida)

```
<design>/brief.md                         # escrito à mão; frontmatter projection_of + review_after
<design>/foundations/color.tokens.json    # primitivos W3C DTCG (a marca e os neutros)
<design>/semantic/color.tokens.json       # papéis por alias (surface, on-surface, action)
<design>/governance/contrast-pairs.json   # pares fg/bg com o mínimo WCAG (4,5 para texto)
<design>/design-context.kg.yaml           # o GRAFO: a fonte; o brief.md é a projeção dele
```

O brief mínimo tem: personalidade da marca, público, tom e restrições, e a cor de marca (o papel de cada
cor). O frontmatter dele declara `projection_of: <design>/design-context.kg.yaml` e `review_after`.

**O contraste do CTA é calculado, nunca estimado:** o texto sobre a cor de ação chega a 4,5:1 com branco
ou com quase preto; se nenhum chega, a ação usa um tom mais escuro da marca e a cor original vira acento.
O `/design:setup` faz essa conta e o gate re-mede.

## 3. O grafo do design-context e as ligações

O design é o **primeiro contexto com grafo próprio**. Tipos (contrato KG-SSOT vendorizado, sem mudança):

| Nó | Tipo | Camada |
|---|---|---|
| a marca, cada token citado | `entity` | domain |
| o contraste ≥ 4,5:1 verificado | `invariant` (`rule` quando é só diretriz) | domain |
| o tema aplicado | `state` | domain |
| a política de uso da marca | `policy` | domain |
| a escolha da paleta (espera o selo do maestro) | `decision` | audit |
| os arquivos de tokens | `artifact` | audit |
| o brief | `claim` com `trace: <design>/brief.md` | audit |

- **Tokens não se copiam para o grafo:** o nó aponta o arquivo por `trace:` e o token por
  `provenance.locator`, um JSON Pointer (`#/color/action/primary`).
- **Ligações entre contextos** por `external_edges` relativas à raiz: o brief `TRACES_TO` o posicionamento
  (`E_POSITIONING`) e o público (`E_AUDIENCE`) do grafo do business-context; o invariante de contraste
  `CONSTRAINS` o tema aplicado (`ST_THEME_APPLIED`) do grafo do technical-context. Esses ids são a
  **convenção** que o `/design:setup` procura.
- **Sem o alvo, não se inventa a aresta:** um nó `question` aberto com `x_missing_context: business-context`
  (ou `technical-context`) ligado ao brief declara a falta.
- **Ordem de migração:** o grafo-alvo entra no git ANTES do grafo do design (o gate só enxerga rastreado).

## 4. Quem confere o quê

- **Ligação quebrada** (alvo sumiu): o gate do contrato KG-SSOT (`integrity.dangling-external`), sem regra nova.
- **Token citado que sumiu do JSON, locator que aponta um grupo, brief sem ligação nem falta declarada:**
  `bash .claude/validation/design-context-check.sh` (rc 0/1/2; no 1º ciclo os achados são AVISO).
- **Contraste, alias e DTCG:** `bash .claude/validation/lint-design-tokens.sh`.
- **Frescor:** `/meta:context-freshness` cobre `docs/design-context/`.
- **Projeção** (o `.md` cita ids que existem no grafo): o checador do kg-ssot ainda não existe — declarado
  ≠ verificado. Ver `[[onion-dogfooding-doctrine]]`.

## 5. Regra de ouro

- **Tipo A** → do framework embarcado. **Tipo B** → resolver → bootstrap com confirmação → degradar honesto.
- O setup **nunca sobrescreve**, roda em dry-run antes de gravar e é idempotente.
- **Tudo local:** nenhum serviço externo no núcleo (o Gamma do `/product:presentation` não entra no ciclo).
