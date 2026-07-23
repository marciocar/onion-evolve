---
name: diary
description: |
  Gerencia o diário de aprendizado da instância Onion — sistema de breadcrumbs para o Transformer.
  Cria, lista, exporta e RE-TESTA entradas estruturadas (learning/decision/error/innovation/observation)
  que orientam a absorção correta do contexto em sessões futuras e entre instâncias federadas — o
  sub-comando review é o gatilho invariável de reflexão (⏰ migalha vencida → re-testar, nunca re-carimbar).
  O diário é autobiografia viva: não registra o passado, orienta o futuro. Relacionado: /meta:co-relay,
  /meta:personality-sync (Fase 2, gated), RFC-0003.
model: sonnet
allowed-tools: Read Write Edit Glob Grep Bash(git *) Bash(bash *) Bash(ls *) Bash(cat *) Bash(mkdir *) Bash(touch *) Bash(date *) Bash(find *) Bash(awk *) Bash(grep *) Bash(sort *)
argument-hint: "create | list [--classification <c>] [--type <t>] [--sharable] | export-sharable [--dry-run] | index | review"
category: meta
version: "1.4.0"
updated: "2026-07-23"
---

# 🧅 /meta:diary — Diário de Aprendizado Onion

## Propósito

O diário é o **sistema de breadcrumbs da instância** — cada entrada é um sinal explícito que força
o Transformer a **absorver** a intenção correta, não *acomodar* o mais provável.

Distinção crítica (`breadcrumb-patterns.md`):
- **Acomodação**: modelo infere contexto do corpus (default perigoso)
- **Absorção**: modelo lê frontmatter YAML estruturado e o segue — mesmo contra o padrão esperado

Canal de maior absorção: **Frontmatter YAML** (chega proeminente antes de qualquer prosa).

---

## Sub-comandos

### `create` — Criar nova entrada

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIARY_DIR="$REPO/.claude/diary"
mkdir -p "$DIARY_DIR"
TODAY="$(date +%F)"
INSTANCE_ID="$(awk '/^instance:/{print $2}' "$REPO/.claude/.onion-version" 2>/dev/null || basename "$REPO")"
```

**Coleta guiada** (perguntar ao maestro o que não pode ser auto-detectado):

1. **Tipo** — qual categoria melhor descreve este aprendizado?
   - `learning` — algo novo aprendido do uso
   - `decision` — decisão arquitetural ou de processo tomada
   - `error` — erro cometido e como foi resolvido (+ como evitar)
   - `innovation` — algo novo criado aqui que pode beneficiar a rede
   - `observation` — observação de mercado, comunidade ou padrão externo
   - `reflection` — síntese retrospectiva sobre o próprio método (nenhum dos acima serve: não veio do uso
     nem é decisão, e não é externo). **Promovido em 2026-07-17** — o campo já o escrevia antes de existir
     no vocabulário (`hegel-limit-kg-boundary`, `the-day-the-loop-ran-both-ways`) e o `diary-index.sh` não
     validava `type`. Enum agora é **guarda** (tipo fora da lista = migalha desonesta → exit 1).

2. **Classification** — quem deve poder ler isto?
   - `private` — só esta instância (default para `error` com contexto de negócio)
   - `protected` — instância + core
   - `peer` — instância + peers autorizados em `trust.diary_readable_by`
   - `downstream` — instância + seus adotados (T2)
   - `public` — qualquer instância federada (default para `innovation` e `observation`)
   - `collective` — candidato à síntese coletiva co-autorada pelo core

3. **Tags** — 1-5 tags descritivas (ex: `[oauth, session, co-evolution]`)
4. **Affects** — quais dimensões esta entrada afeta: `engineering`, `product`, `compliance`, `design`, `meta`
5. **Slug** — nome curto para o arquivo (ex: `oauth-session-learning`)
6. **Classe de conflito** — COMO esta migalha pode ser invalidada? (vocabulário
   [MemConflict](../../../docs/analysis/onion-intelligent-breadcrumbs-research-2026-07.md) — a
   estrutura de decisão que dirige o re-teste; pesquisa 2026-07: o estado da arte reconhece só ~25%
   das contradições porque a memória não carrega estrutura de invalidação):
   - `dynamic` — o fato muda com o tempo/mundo (pin, versão, comportamento de script). Re-teste:
     **rodar o artefato** de novo.
   - `static` — o fato era uma conclusão que fonte melhor pode corrigir (veredito de auditoria,
     interpretação). Re-teste: **confrontar a melhor fonte atual**.
   - `conditional` — vale ENQUANTO uma condição vale. Re-teste: **checar só a condição** (o mais
     barato). Exige `valid_when`.
7. **valid_when** *(obrigatório se `conditional`; opcional nas demais)* — a condição de
   aplicabilidade em 1 linha testável (ex: `"o adotante segue sem node_modules na worktree"`).
8. **Nasceu no grafo?** *(pergunta guiada só para `type` em `decision`/`error`/`learning`/`reflection`
   — os tipos epistêmicos)* — esta migalha veio de uma investigação/audit/verify-multi-round (algo que
   valeu a pena modelar como claims/evidência/decisões)?
   - **Sim** → informe `kg: <path/para/o.kg.yaml>` (born-in-graph — o grafo é o destino, a migalha é
     projeção dele; ver `write(KG)` canônico em `onion-orchestration`).
   - **Não, foi prosa-só** → não preencha `kg:` (o campo é **opcional** — ausência não é violação,
     não retro-reprova migalhas antigas), mas diga numa linha **por que** não valeu grafo (ex.: "insight
     pontual de 1 fonte, sem cadeia de evidência a modelar").

**Gerar arquivo:**

```bash
SLUG="<slug-coletado>"
FILENAME="${TODAY}-${SLUG}.md"
FILEPATH="$DIARY_DIR/$FILENAME"

# Calcular review_after (90 dias por padrão)
REVIEW_DATE="$(date -d "$TODAY + 90 days" +%F 2>/dev/null || date -v +90d +%F 2>/dev/null || echo "$(echo $TODAY | awk -F- '{printf "%s-%02d-%s", $1, ($2%12)+1, $3}')")"

cat > "$FILEPATH" <<EOF
---
date: ${TODAY}
instance: ${INSTANCE_ID}
type: <tipo>
classification: <classification>
tags: [<tags>]
affects: [<affects>]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: ${REVIEW_DATE}
conflict_class: <dynamic|static|conditional>
valid_when: "<condição testável — obrigatória se conditional; REMOVER a linha se não se aplica>"
significance: "<frase orgulhosa e honesta, ≤1 linha — por que esta migalha vale e qual seu papel no continuum dogfoodado; OPCIONAL, REMOVER a linha se ainda não estiver clara>"
kg: "<path/para/o.kg.yaml> — OPCIONAL: só se esta migalha nasceu de investigação/audit/verify-multi-round; REMOVER a linha se foi prosa-só (ausência não é violação — só kg: declarado-mas-inválido reprova no gate de integridade)"
---

## Signal
[≤3 linhas — o que o Transformer DEVE absorver desta entrada]

## Evidence
[bullets — o que aconteceu de concreto]
-

## Next crumb
[o que deve ser feito ou investigado depois de absorver esta entrada]
EOF
echo "Criado: $FILEPATH"
```

Abrir o arquivo para o maestro completar, guiado por **4 perguntas** (Signal/Evidence/Next crumb já
eram; `significance` é a 4ª, nova em 1.3.0):

1. **Signal** — o que o Transformer DEVE absorver desta entrada (≤3 linhas)?
2. **Evidence** — o que aconteceu de concreto (bullets, não prosa)?
3. **Next crumb** — o que fazer/investigar depois de absorver esta entrada?
4. **Significance** *(campo `significance:` no frontmatter — opcional)* — "em uma frase orgulhosa e
   honesta, por que esta migalha vale e qual seu papel no continuum da evolução dogfoodada?"

**Guarda orgulho ≠ hype** (a `significance` não é decoração):
- **Precisa de lastro em Evidence/Signal** — uma `significance` sem lastro no que a entrada de fato
  mostra é migalha **desonesta** (mesma classe de `type`/`conflict_class` fora do vocabulário — ver
  Regras do diário). Orgulho é ganho pela evidência, não declarado por conta própria.
- **Cai junto quando a migalha é superseded** — no `review`, se o veredito for "inválida"
  (`superseded: true`), a `significance` cai com o resto: não se vende com orgulho uma migalha morta.
  É re-testada junto (mesma disciplina do `⏰`/`conflict_class`).
- **Uma frase, não um parágrafo** — a força é a destilação. Se o encaixe-no-todo não cabe numa linha
  orgulhosa e honesta, ele ainda não está claro — e isso, por si, já é um sinal (não force a frase).
- **Opcional e retrocompatível** — entradas antigas (pré-1.3.0) não têm o campo e continuam válidas;
  o `diary-index.sh` degrada gracioso (mostra "—") quando ausente. Não é obrigatório preencher em
  entradas onde o papel-no-continuum ainda não se provou.

**Após preenchimento:** rodar `diary index` para atualizar o index.md.

---

### `list` — Listar entradas

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIARY_DIR="$REPO/.claude/diary"

# Filtros opcionais via argumento:
# --classification private|protected|peer|downstream|public|collective
# --type learning|decision|error|innovation|observation
# --sharable (só entradas com share_with != [] ou classification em [peer,public,collective])

find "$DIARY_DIR" -name "*.md" ! -name "index.md" | sort -r | while read f; do
  DATE=$(awk '/^date:/{print $2}' "$f")
  TYPE=$(awk '/^type:/{print $2}' "$f")
  CLASS=$(awk '/^classification:/{print $2}' "$f")
  SLUG=$(basename "$f" .md | cut -d- -f4-)
  REVIEW=$(awk '/^review_after:/{print $2}' "$f")
  # significance é FRASE (espaços) → extrair com sub(), nunca $2; aspas de borda removidas.
  SIG=$(awk '/^significance:/{sub(/^significance:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$f")
  printf "%-12s  %-12s  %-12s  %-30s  review: %s\n" "$DATE" "$TYPE" "$CLASS" "$SLUG" "$REVIEW"
  # NUNCA id nu: quando a migalha diz por que vale, isso aparece junto — é o canal avaliativo
  # de ① Absorção (breadcrumb-patterns §Faceta de ①), não decoração. Ausente → linha some.
  # `if` e não `[ ... ] && printf`: como É O ÚLTIMO comando do corpo do loop, a forma curta
  # devolveria exit 1 na última entrada SEM significance (falha espúria sob set -e / no `||`).
  if [ -n "$SIG" ]; then printf "              ↳ %s\n" "$SIG"; fi
done
```

Sinalizar entradas com `review_after` < hoje: `⏰ VENCIDO` ao lado.

---

### `export-sharable` — Empacotar entradas compartilháveis para co-relay

Identifica entradas com `share_with != []` OU `classification` em `[peer, downstream, public, collective]`
e as empacota para transporte via `/meta:co-relay`.

```bash
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIARY_DIR="$REPO/.claude/diary"
OUTBOX="$REPO/docs/evolution/outbox/diary"
mkdir -p "$OUTBOX"

find "$DIARY_DIR" -name "*.md" ! -name "index.md" | while read f; do
  SHARE=$(awk '/^share_with:/{print}' "$f" | grep -v '\[\]')
  CLASS=$(awk '/^classification:/{print $2}' "$f")
  
  if [ -n "$SHARE" ] || echo "$CLASS" | grep -qE "^(peer|downstream|public|collective)$"; then
    DEST="$OUTBOX/$(basename "$f")"
    if [ ! -f "$DEST" ]; then
      cp "$f" "$DEST"
      echo "📤 Empacotado: $(basename "$f") (class: $CLASS)"
    else
      echo "↩  Já empacotado: $(basename "$f") (sem mudança)"
    fi
  fi
done

echo ""
echo "Outbox: $OUTBOX"
echo "Próximo passo: /meta:co-relay --to core (ou --to peer:<peer-id>) para transportar"
```

Se `--dry-run`: listar sem copiar.

---

### `index` — Regenerar index.md

```bash
bash "$(git rev-parse --show-toplevel)/${CLAUDE_PLUGIN_ROOT}/validation/diary-index.sh"
```

O index.md é o Tier-0 pointer do diário (~1KB). O Transformer lê o índice, não o diário inteiro.
Formato do índice: tabela com date, type, classification, slug, **significance** (quando presente —
degrada para "—" quando ausente), review_after, conflict_class — ordenada por data desc. A coluna
`significance` é o que faz o índice dizer **por que ler** cada entrada, não só o quê/quando.

---

### `review` — Re-testar migalhas vencidas (gatilho invariável de reflexão)

Quando o hook sinalizar **⏰** (entradas com `review_after` vencido), rodar o protocolo de re-teste —
**nunca re-carimbar sem re-testar** (risco nº1 documentado: reflexão falsa persistida vira erro
auto-reforçante — [ADR work-models §4](../../../docs/analysis/onion-adr-work-models-session-topologies-2026-07.md)):

1. **Listar vencidas:** entradas com `review_after < hoje` (o `index.md` já as marca ⏰).
2. **Re-testar cada uma contra evidência ATUAL, dirigido pela `conflict_class`** (não contra a
   memória da época — e não genericamente):
   - `dynamic` → **RODE o artefato** de novo (o pin ainda é esse? o script ainda sai com esse
     código? exit code é evidência, leitura é hipótese).
   - `static` → **confronte a melhor fonte atual** (a conclusão sobrevive ao que existe de melhor
     hoje? fonte nova supersede?).
   - `conditional` → **cheque só o `valid_when`** (a condição ainda vale? → migalha vale; condição
     caiu? → inválida ou reescrever). É o re-teste mais barato — use-o.
   - *(sem `conflict_class` — entrada pré-1.2.0)* → protocolo genérico: verificar Signal e Evidence
     no filesystem/git/execução; ao re-testar, **classificar** (adicionar o campo) para o próximo ciclo.
3. **Veredito (sempre confirmado pelo maestro — gate na absorção):**
   - **Válida** → atualizar só `review_after` (+90 dias) e registrar 1 linha de re-teste no corpo
     (`## Re-testada em <data>: <evidência>`).
   - **Inválida** → adicionar `superseded: true` ao frontmatter + nota do porquê (nunca apagar — o
     diário é história; o índice deixa de recomendá-la).
   - **Parcial** → reescrever Signal/Evidence com o estado atual + novo `review_after`.
4. **Regenerar o índice** (`diary index`).

---

## Regras do diário

1. **Signal é o que o Transformer absorve** — não é título, não é prosa. É a instrução explícita.
2. **Evidence é bullet, não prosa** — o Transformer precisa de fatos, não narrativa.
3. **Next crumb é obrigatório** — o diário não termina numa entrada; termina numa ação.
4. **review_after sempre preenchido** — nada no diário é eterno. Padrão: 90 dias após `date`.
   `conflict_class` diz COMO re-testar quando vencer (dynamic → rodar; static → confrontar fonte;
   conditional → checar `valid_when`). `conditional` sem `valid_when` é inválida (guarda no
   lint-selftest); os campos são **opcionais** para retrocompat — entrada sem eles cai no protocolo
   genérico do review e é classificada no 1º re-teste. Experimento em curso (pesquisa breadcrumbs
   2026-07, Q2): medir re-absorção com vs sem estrutura entre ciclos de review.
5. **Classification antes de share_with** — a classificação é a política; share_with é exceção explícita.
6. **Private é o default para erros com contexto de negócio** — não expor dados do adotante.
7. **Innovations são public por padrão** — se descobrimos algo útil, a rede deve poder absorver.
8. **Significance é opcional, mas se presente exige lastro** — uma frase (≤1 linha, frontmatter) que
   destila por que a migalha vale e qual seu papel no continuum dogfoodado. Orgulho é ganho por
   Evidence/Signal, não declarado por conta própria — `significance` sem lastro é migalha desonesta
   (mesma classe de `type`/`conflict_class` fora do vocabulário). Cai junto quando a entrada é
   `superseded` no `review` (não se vende com orgulho uma migalha morta). Campo **opcional e
   retrocompatível** — entradas pré-1.3.0 sem ele continuam válidas; o `diary-index.sh` degrada
   gracioso ("—") quando ausente.
9. **`kg:` é opcional, mas se declarado exige integridade** — para tipos epistêmicos
   (`decision`/`error`/`learning`/`reflection`), a pergunta guiada oferece registrar o path do
   `.kg.yaml` quando a migalha **nasceu de investigação/audit/verify-multi-round** (born-in-graph — ver
   `write(KG)` canônico em `onion-orchestration`). **Ausência não é violação** — não retro-reprova as
   migalhas existentes; só `kg:` **declarado** e apontando para um grafo pendurado/quebrado é. A
   integridade de `kg:` (path existe + `kg-radar.sh --integrity --schema` sai 0) é validada no gate de
   frontmatter (dono: `validation/`), não neste comando.

---

## Quando usar o diário

| Situação | Tipo recomendado | Classification padrão |
|---|---|---|
| Aprendi algo novo de um erro | `error` | `protected` |
| Tomei uma decisão arquitetural | `decision` | `protected` |
| Descobri uma pattern nova | `innovation` | `public` |
| Observei algo no mercado | `observation` | `public` |
| Entendi como algo funciona | `learning` | depende do conteúdo |
| Quero contribuir para KB coletiva | qualquer | `collective` |

---

## Estrutura de arquivos

```
.claude/diary/
├── index.md                      # Tier-0 pointer (~1KB) — gerado por diary-index.sh
├── 2026-07-01-oauth-learning.md
├── 2026-07-02-sdaal-decision.md
└── ...
```

---

## Relação com co-evolução

O diário é o **conteúdo** que o protocolo co-evolução **transporta**. A sequência canônica:

```
1. /meta:diary create            # cria a migalha localmente
2. /meta:diary export-sharable   # empacota para transporte
3. /meta:co-relay --to core      # (ou --to peer:<id> — Fase 3, gated)
4. Core: /meta:co-evolve         # tria o sinal recebido
5. Loop fecha: learning adotado, ajuste enviado de volta, ou knowledge base atualizada
```
