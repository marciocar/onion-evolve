---
name: deck
description: |
  Gerador de deck de treino/onboarding AUTO-GUIADO como HTML self-contained: uma spec
  (roteiro de slides) vira um deck que abre em qualquer navegador, OFFLINE (fonte embutida
  data-URI, zero CDN), com progressive-disclosure, botões "Copiar", exemplos preenchidos e
  modo projetor. Distinto do /product:presentation (Gamma.app, SaaS online): aqui o
  deliverable é um único .html soberano, sem rede. Nasceu de dogfood de campo (decks de um
  treino real, 2026-07 — validados em uso).
allowed-tools: Read Write Edit Glob Grep Bash(bash ${CLAUDE_PLUGIN_ROOT}/validation/*)
category: design
tags: [design, deck, onboarding, training, self-contained, offline, progressive-disclosure]
version: "0.1.0"
updated: "2026-07-30"

parameters:
  - name: spec
    description: "Roteiro do deck (arquivo .md com os slides) OU o slug de uma vertical cujo uso o deck ensina"
    required: true
  - name: mode
    description: "onboarding (ensina a USAR primeiro) | advanced (uso avançado/hands-on) — molda o arco"
    required: false
    default: onboarding
---

## /design:deck — o deck que se explica sozinho, offline

Um deck de treino que depende de rede, de um SaaS ou de um facilitador lendo os slides é frágil.
Este comando gera um **HTML self-contained** — um arquivo só, que abre em `file://`, com a fonte
embutida e zero CDN. É a **face de didática** irmã da vertical: o `/meta:create-vertical` scaffolda
`book + hub + helpers`; este ensina a **usá-los**.

> **Regra que não se negocia:** o deck **abre offline** (fonte data-URI, sem `<script src>` externo,
> sem `fetch`). O gate é o mesmo do console rico: zero requisição de rede. Um deck que precisa de
> internet numa sala de treino é um deck que trava na hora errada.

### O chassi (destilado do protótipo de campo)

Cada slide é uma seção `.slide`. O chassi reúne os elementos que fizeram o treino real funcionar
(CSAT 10 na fase "decks", retro 2026-07-29):

| Elemento | O que é | Por que |
|---|---|---|
| **Fonte embutida** | `@font-face` com `src: url(data:font/woff2;base64,…)` | offline premium — tipografia sem CDN |
| **Progressive disclosure** | 1 conceito por slide; detalhe revela ao avançar | público não-técnico aprende a USAR antes de CRIAR |
| **Botão "Copiar"** (`.copybtn`) | copia o prompt/exemplo do slide | tira o atrito de transcrever à mão |
| **Exemplo preenchido** (`.practice`/`.napratica`) | todo "pratique agora" já vem com um caso real preenchido | mostra o resultado, não só a instrução |
| **Modo projetor** | tema alto-contraste, navegação por setas ← → | usável numa sala, não só no laptop |
| **Cartão de prompt** | bloco copiável com o prompt exato de cada skill | o deck vira um kit de uso, não só slides |

### Etapas

#### 1. Ler a spec (o roteiro, não o pixel)
- `spec` = arquivo → cada `## <título>` vira um slide; `pill-label`/`anchor`/blocos de exemplo são
  a matéria-prima. `spec` = slug de vertical → derivar os slides do hub+helpers (uma skill por slide:
  menu → modo ajuda → funções, com o cartão de prompt de cada uma).
- **Arco por `mode`:** `onboarding` abre pelo **uso** (instalar → 1º comando → hands-on), detalhe
  vem depois; `advanced` assume o básico e foca em fluxo completo + exemplos preenchidos.

#### 2. Montar o HTML self-contained
- Reusar o **chassi** (CSS tokens + `.slide` + `.copybtn` + `@font-face` data-URI + nav por setas +
  modo projetor). A fonte entra como **data-URI** (nunca `<link>`/CDN). Cada "pratique agora" carrega
  um **exemplo preenchido** real.
- **Injeção segura** de qualquer dado dinâmico: base64 → decode no cliente (à prova de `</script>`),
  o mesmo padrão do `kg-console.sh`.

#### 3. Gate offline (determinístico, não confiança)
```bash
# zero rede: nenhum src/href http externo, nenhum fetch/XHR
grep -qiE 'src=.?https?://|<link[^>]+https?://|fetch\(|XMLHttpRequest' <deck.html> && echo "REPROVA: tem rede" || echo "OK: self-contained"
```
Um deck que casa qualquer um desses **não fecha** — inline o recurso ou remova.

#### 4. (Client-safe, se cruza fronteira)
Se o deck vira material de cliente ou viaja pra fora, passa pelo gate `grep`=0 de identificadores
sensíveis (a convenção "SSOT com partição de visibilidade") **antes** de sair.

### Saída
Um `.html` self-contained (o path declarado), pronto pra abrir offline. No relatório: nº de slides,
`mode`, e o veredito do gate offline (o `grep` de rede = 0).

### Notas
- **Distinto do `/product:presentation`** (Gamma.app): aquele é SaaS online, pitch/report; este é
  **deck de treino/onboarding soberano offline**. Escolha por destino: sala de treino sem rede
  garantida → `deck`; apresentação corporativa rica online → `presentation`.
- **Federação:** viaja o **chassi + o método**, nunca o conteúdo de nenhum deck (soberania — cada
  adotante gera o próprio, do próprio book).
- **Composição:** par natural do `/meta:create-vertical` (scaffolda a vertical) → `/design:deck`
  (ensina a usá-la). E do `/design:identity` (a identidade visual que o chassi pode herdar).
