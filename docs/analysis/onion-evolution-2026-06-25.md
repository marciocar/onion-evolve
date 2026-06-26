# Onion Evolution Backlog — 2026-06-25

## 0. Sumário

◆ **Dimensões:** 9 (D1–D9) ◆ **Padrão:** fan-out-and-synthesize ◆ **Workers:** 9 scan + 22 juízes opus
◆ **Substrato:** ferramenta nativa `Workflow` ◆ **Run ID:** `wf_4f2602c9-d0f` ◆ **Tokens:** ~1.4M ◆ **Agentes:** 31 ◆ **Duração:** ~27min

| Etapa | Nº |
|-------|---:|
| Achados brutos | 49 |
| Julgados (adversarial opus) | 22 |
| Mortos pelo juiz (refutados/vetados) | 10 |
| Sobreviventes da frota | 39 |
| **Refutados na curadoria do maestro** (validação adversarial = insumo) | **4** |
| **Backlog real após curadoria** | **35** |

> **Read-only por contrato:** esta auditoria não mutou `.claude/`. A única escrita é este relatório.
> A execução das correções é dos atuadores (`/meta:*`, edição direta) sob validação do `@metaspec-gate-keeper`.

**Veredito de alto nível: 0 blockers reais.** Os 4 "blockers" da frota não sobreviveram à curadoria
(2 eram "no action needed" mal-rotulados; 1 refutado por evidência; 1 rebaixado a recommended). O framework
está **saudável** — o backlog é manutenção de frescor e fechamento de buracos de lint, não dívida estrutural.

---

## 1. Backlog priorizado (pós-curadoria)

Severidade após minha validação direta. Rótulos mnemônicos de 2-5 palavras na 1ª menção.

| # | Sev | Dim | Achado (arquivo:linha) | Padrão (doutrina) | Esforço | Comando de execução |
|---|-----|-----|------------------------|-------------------|---------|---------------------|
| 1 | 🟡 | D5 | **Contagens hardcoded stale** — `onion.md:132` "49 total" / `:203` "82 total"; `command-creator:47,49` "60+ comandos"/"24+ agentes"; `agents-reference:55` "87 comandos, 49 agentes" (real: 90/51/5/37) | drift = erro de CI (§50) | M | estender lint Regra 8 + `/meta:inventory` |
| 2 | 🟡 | D5 | **`product/task.md:6` omite Jira** — declara "ClickUp, Asana, Linear" mas Jira é o 1º provider em integrations.md §1 (e é o provider **ativo** nesta sessão) | align-to-metaspec | S | edição direta |
| 3 | 🟡 | D5 | **`engineer/pr.md:5` `Bash(bash *)` amplo** — usado só p/ `resolve-integration-branch.sh`; viola commands.md §1.3 (prefixos escopados) | align-to-metaspec | S | edição direta → `Bash(bash .claude/validation/*)` |
| 4 | 🟡 | D7 | **Links com caminho errado** — `compliance-context/README:130` aponta `compliance/corporate-compliance-specialist.md` (está em `review/`); `:137` aponta `docs/onion/applying-regulated.md` (está em `docs/applying/`, e anotação "(a criar)" stale) | fix-broken-ref | S | edição direta |
| 5 | 🟡 | D7 | **Refs a federation-design v1 deletado** — `onion-federation-design-v2-2026-06.md:5,13` referenciam o `-v1` que não existe mais | fix-broken-ref | S | edição direta |
| 6 | 🟡 | D4 | **Vazamento ClickUp/MCP hardcoded em KBs** — `command-creation-patterns:187,556`, `configuration-management:370` (`mcp__clickup__*`), `specification-driven-ai-abstraction-layer:114` (diagrama) violam agnosticismo SDAAL/API-first | route-through-adapter | M | edição direta (generalizar p/ "task manager ativo via abstração") |
| 7 | 🟡 | D2 | **`quick/analisys` typo** — `name: analisys` (→`analysis`) + output em `docs/alalisys/` (duplo typo) | fix-typo | S | edição direta (cuidado: renomear arquivo afeta inventário) |
| 8 | 🟢 | D9 | **`design-context/brief.md:42` diz "6 pares"** — `governance/contrast-pairs.json` tem 8 (e o gate valida 8); memória já registra 8 pares/28 tokens | refresh-context | S | edição direta |
| 9 | 🟢 | D8 | **READMEs de categoria ausentes** — 7 categorias de comando + 9 de agente sem README de descoberta | fill-doc | M | `/meta:create-*` ou edição |
| 10 | 🟢 | D8 | **Frontmatter opcional ausente** — `expertise`/`related_agents` em brand-generator, design-system-specialist, runflow-specialist, zen-engine-specialist, pain-price-specialist | fill-frontmatter | S | edição direta |
| 11 | 🟢 | D2/D1 | **Clusters candidatos a consolidação** (test-* / meta-creators / branch-* / C4 / NX) — **NÃO acionar sem dogfood**; a maioria é peer distinto por design (a própria frota reconhece) | consolidar-vs-manter (§44) | L | avaliar caso a caso pós-evidência |

---

## 2. Refutados na curadoria do maestro (validação adversarial = insumo, não ordem)

Estes vieram como sobreviventes da frota mas **rejeito com evidência** — fechando o loop adversarial
(o juiz opus só rodou nos 22 que tocavam `engineer/*`/`product/*` ou consolidação; os "blockers" passaram batido):

| ID | Sev frota | Por que refuto |
|----|-----------|----------------|
| **D1-7** | 🔴 blocker | "Sem lint CI p/ drift de inventário" — **FALSO**. `lint-artifacts.sh:286 check_inventory_sync()` emite **HARD** e `:317 check_claude_md_drift()` também; `onion-validate.yml:26` os roda no CI. Worker procurou `inventory` direto no workflow YAML e no `inventory.sh` (o check vive no lint). |
| **D8-4** | 🔴 blocker | "Inventory perfeitamente alinhado, **no action needed**" — não é achado; é confirmação de saúde mal-rotulada como blocker. |
| **D8-5** | 🔴 blocker | "Todo frontmatter presente, **no action needed**" — idem. (Contradiz D8-2/D8-3 do mesmo worker, que apontam campos opcionais ausentes — esses, opportunistic, ficam no backlog.) |
| **D1-9** | 🟢 opp. | "38 KBs por `find` vs 37 no inventário = drift" — `inventory.sh` tem definição própria de KB (não é `find` cru); diferença de 1 não é drift comprovado. A verificar, baixíssima prioridade — não acionável. |

E os **10 mortos pelo juiz opus** (todos refutados, **0 vetos de fusão de fase**): D1-0, D1-5, D2-1, D2-9,
D3-0, D3-1, D3-2, D3-3, D6-1, D7-4 — em geral porque a evidência se contradizia ou a oportunidade **já estava
satisfeita** (ex.: D1-5 alegava que `presentation-orchestrator` não cita `onion-fleet`, mas `:59` cita
explicitamente; D2/D3 alegavam duplicação já extraída para `common/prompts/`).

---

## 3. Alertas transversais (causa sistêmica)

**🔴 SISTÊMICO — Buraco no lint Regra 8 (contagens):** 3 achados independentes (D5-0, D5-1, D5-2) com a
**mesma causa**: contagens hardcoded stale que o lint **não pega**. Confirmei rodando o lint: passa com
**0 violações** enquanto "49 total", "82 total", "60+ comandos", "87 comandos, 49 agentes" existem no
filesystem. A Regra 8 cobre frases-de-total **canônicas** (`N agentes e M comandos`) mas não:
(a) formato parentético `(N total)`, (b) aproximado `60+ comandos`, (c) composto numa linha
`87 comandos, 49 agentes, 5 skills, 37 KBs`. **Item #1 do backlog deve estender o lint** — senão essas frases
re-divergem a cada mudança de inventário e o `--fix` não as alcança.

**🟡 SUB-CLUSTER — Vazamento de provider em material de conhecimento:** D4-0/D4-1/D4-2 mostram `mcp__clickup__*`
e ClickUp hardcoded em 3 KBs/diagramas SDAAL. Causa comum: KBs escritos antes da consolidação API-first/SDAAL
não foram regenerados. Item #6.

**🟡 SUB-CLUSTER — Drift de caminho em refs:** D7-0/D7-1/D7-2/D7-3 — links apontando para caminhos antigos
(categoria movida, doc renomeado/deletado). Itens #4–#5. Os de session archives (D7-3) são gitignored → ignorar.

---

## 4. Invariantes respeitadas

- ✅ **Nenhuma proposta funde fases** de `engineer/*` ou `product/*` — verificado pelo juiz adversarial opus
  (`vetoed_phase_merge=false` em todos os 22 julgados; D2-1 chegou a propor tocar o fluxo de produto e foi
  **refutado** com a observação de que collect→refine→spec→task→estimate→feature é o faseado canônico legítimo).
- ✅ **Read-only:** `.claude/` intacto; só este relatório foi escrito.
- ✅ **Sem fleet-in-fleet:** D4/D5/D9 rodaram como scan focado (agente único, gate ≤18mo herdado), não sub-frotas.

---

## 5. Próximos passos (cada item → seu atuador)

**Quick wins (S, edição direta) — recomendo agrupar num só PR:**
- #2 (Jira em `product/task.md`), #3 (escopo `Bash` em `pr.md`), #4–#5 (links), #7 (typo `analisys`), #8 (brief.md 8 pares).

**Esforço médio (M):**
- #1 — estender lint Regra 8 (o de maior alavancagem: fecha o buraco sistêmico) + rodar `/meta:inventory`.
- #6 — generalizar provider hardcoded nos 3 KBs.

**Deferidos / não-acionáveis:**
- #9, #10 — cosmético/opportunistic.
- #11 — consolidação de clusters **só com dogfood** (doutrina §44: manter se há nome canônico/escopo distinto;
  a frota mesma classificou test-*/branch-*/C4/NX como peers por design).

---

*Gerado por `/meta:evolve` (fan-out-and-synthesize, 9 dimensões). Curadoria adversarial do maestro aplicada
sobre o output da frota — falsos-positivos refutados com evidência citada, conforme doutrina de dogfood.*
