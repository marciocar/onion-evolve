# Onion Evolution Backlog — 2026-07-04

## 0. Sumário

◆ Dimensões: 9 (D6 limpa · D9 no-op — contextos são templates) ◆ Padrão: fan-out-and-synthesize
◆ Workers: 8 de scan + 14 juízes adversariais (opus) ◆ Budget: ~835k tokens ◆ Run ID: `wf_01b63531-114`
◆ Achados: 23 brutos → **16 sobreviventes** (7 refutados pelo juiz) → 3 🔴 · 8 🟡 · 5 🟢
◆ Baseline anterior: [onion-evolution-2026-06-25.md](onion-evolution-2026-06-25.md)

> **Este run é também o 1º dogfood do Knowledge Graph SDAAL no core** (F2 da vertical
> `onion-investigation`): os achados, vereditos e refutações abaixo estão modelados como grafo
> tipado em [`docs/onion/graph/onion-evolution-2026-07.kg.yaml`](../onion/graph/onion-evolution-2026-07.kg.yaml),
> verificado pelo radar determinístico `.claude/validation/kg-radar.sh`. O comando `/meta:kg`
> nasceu desta vivência.

## 1. Backlog priorizado

| # | Sev | Dim | Achado (evidência) | Padrão (doutrina) | Artefato-alvo | Esforço | Comando de execução |
|---|-----|-----|--------------------|-------------------|---------------|---------|---------------------|
| 1 | 🔴 | D7 | 5 links do CHANGELOG da federação apontam para `../inbox/` mas os arquivos foram movidos a `_processed/` (`CHANGELOG.md:235,279,342×2,369`) — quebrados pelos próprios `git mv` de triagem | links válidos = navegação da co-evolução | `docs/evolution/federation/CHANGELOG.md` | S | edição dirigida (`../inbox/` → `../inbox/_processed/`) |
| 2 | 🔴 | D7 | Typo `knowbase` em 2 sinais processados (`2026-07-02-sinal-sdaal-knowledge-graph.md:37`, `2026-07-03-secret-handling-pattern.md:50`) | idem | `docs/evolution/inbox/_processed/` (2 arquivos) | S | edição dirigida (`knowbase` → `knowledge-base`) |
| 3 | 🔴 | D8 | `/meta:graph` sem campo `model:` obrigatório no frontmatter (`graph.md:1-10`) | forma-alvo §frontmatter completo | `.claude/commands/meta/graph.md` | S | edição dirigida + gap de lint (ver §3) |
| 4 | 🟡 | D5 | `meta/adopt.md:9` declara `Bash(rm *)`, `Bash(bash *)`, `Bash(cat *)` irrestritos — muito além do uso real do corpo; é o comando de maior raio de explosão do inventário | commands.md §1.3 escopo mínimo | `.claude/commands/meta/adopt.md` | S | edição dirigida + `/meta:metaspec-validate` |
| 5 | 🟡 | D8 | 6 agentes sem `category:` no frontmatter (brand-generator, design-system-specialist, runflow-specialist, zen-engine-specialist, branding-positioning-specialist, pain-price-specialist) | forma-alvo §metadata | `.claude/agents/{development,product}/` (6 arquivos) | S | edição dirigida |
| 6 | 🟡 | D1 | `presentation-orchestrator.md` 1189 linhas — cerimônia: blocos YAML de delegação repetidos (`:71-180`), 7 fases prescritivas (`:223-588`), 5 casos de uso (`:650-716`) | shed-ceremony → KB citável | `.claude/agents/product/presentation-orchestrator.md` | M | `/meta:create-knowledge-base` + redução |
| 7 | 🟡 | D1 | `gamma-api-specialist.md` 1166 linhas — conhecimento de API (auth, rate-limit, retry `:300-500`) deveria ser KB citável | extrair conhecimento → KB | `.claude/agents/development/gamma-api-specialist.md` | M | `/meta:create-knowledge-base` + redução |
| 8 | 🟡 | D2 | Cluster `branch-*`: só 2 de 4 pares têm a distinção diff-scoped-vs-geral autodocumentada (faltam branch-test-planner e branch-documentation-writer); a doutrina lista o cluster como NÃO resolvido (`:137`) | decisão documentada > overlap implícito | `.claude/agents/git/branch-{test-planner,documentation-writer}.md` | S | edição dirigida (nota "Diferença vs @X") |
| 9 | 🟡 | D2 | Pares `/meta:create-*` × `@*-creator-specialist`: doutrina flagou (`:140`); nesta rodada o juiz REFUTOU a versão forte (create-agent JÁ delega — ver §2 D1-2); resta afinar a delegação nos demais pares | verificar antes de consolidar | `.claude/commands/meta/create-{command,skill}.md` | M | `/product:spec → /engineer:plan` (avaliação, não consolidação) |
| 10 | 🟡 | D7 | Path relativo errado em sinal processado quebra link ao KB GitFlow (`2026-06-18-adopt-gitflow-develop-branch-config.md:27`) | links válidos | `docs/evolution/inbox/_processed/` | S | edição dirigida |
| 11 | 🟡 | D7 | Path relativo errado em anúncio processado da outbox (`2026-06-27-s1-toolbox-resolvido.md:17` — `../` deveria ser `../../../`) | links válidos | `docs/evolution/federation/outbox/rhilo-metagamify/_processed/` | S | edição dirigida |
| 12 | 🟢 | D1 | `postgres-specialist.md` 1121 linhas — margem de alerta, sem estourar limite | observar no próximo ciclo | `.claude/agents/development/postgres-specialist.md` | S | próxima rodada `/meta:evolve` |
| 13 | 🟢 | D4 | 2 KBs sem NENHUM campo de data (branding-posicionamento-marca, onion-relation-vocabulary) — frescas via `git log`, mas inauditáveis sem sair do arquivo | auto-suficiência spec-as-code | `docs/knowledge-base/concepts/` (2 arquivos) | S | edição dirigida (bloco Metadata) |
| 14 | 🟢 | D7 | Âncora malformada `§7` em link markdown (`git-ledger-as-working-dir.md:125`) | convenção de âncora | `docs/knowledge-base/platforms/git-ledger-as-working-dir.md` | S | edição dirigida |
| 15 | 🟢 | D8 | Contagem de KBs (53) inclui 4 READMEs de subdiretório — convenção legítima, não documentada | SSOT documenta convenção | `CLAUDE.md` / `inventory.sh` | S | nota de 1 linha |
| 16 | 🟢 | D4 | **D4 saudável**: nenhuma KB stale pelo gate ≤18 meses (mais antiga: runflow.md 2025-11-18) | registro de saúde, não ação | — | — | — |

## 2. Achados refutados pelo juiz adversarial (7)

O juiz (opus, verificação em primeira mão) refutou 7 achados plausíveis-mas-errados — todos
preservados no `.kg.yaml` como claims `status: refuted` com arestas `REFUTES` (história reconcilia,
não apaga):

| id | Alegava | Por que caiu |
|---|---|---|
| D1-2 | create-agent × agent-creator-specialist duplicam 5 fases | O comando (214 linhas) é casca fina que JÁ delega ao especialista — camadas deliberadas, não duplicação |
| D3-6 | 4 comandos replicam o fragmento de detecção de provider | Eles **citam** o fragmento (PASSO 0 = ponteiro de 3-5 linhas); o conteúdo canônico só existe no fragmento |
| D3-7 | Qualificador "(REST API; MCP opcional)" é duplicação | É afordance inline de 3 palavras; as ocorrências substantivas já citam a SSOT |
| D7-13 | 5 links quebrados em sdaal-examples.md | Todos dentro de code fences (templates de geração) — falso-positivo de scanner que ignora fences |
| D7-16 | 3 links quebrados em c4-adr-patterns.md | Idem: conteúdo ilustrativo dentro de ```markdown fence, resolvido do arquivo GERADO, não da KB |
| D7-18 | Link de diretório em INDEX.md:488 deveria apontar .md | Link de coleção intencional; diretório resolve; preferência de estilo, não defeito |
| D7-19 | `.claude/utils/task-manager/` sem factory/interface | Factualmente falso — os arquivos existem (`ls` confirma) |

## 3. Alertas transversais (causa sistêmica)

1. **Links relativos quebram quando a triagem move arquivos** (achados #1, #2, #10, #11 — 4 dos 16):
   o ritual `git mv → _processed/` não atualiza quem aponta para o arquivo movido. Candidato a
   guarda determinística: modo `--links` no lint cobrindo `docs/evolution/` (hoje o lint não varre
   links deste diretório). **Padrão, não acidente.**
2. **Scanner de links ingênuo gera falso-positivo em code fence** (3 dos 7 refutados): qualquer
   futura guarda de links DEVE ignorar conteúdo dentro de fences — lição paga nesta rodada pelo
   juiz adversarial.
3. **Frontmatter incompleto escapa do lint** (#3, #5): `model:` em comandos e `category:` em
   agentes não são validados pelas guardas atuais — o gap permitiu 7 artefatos divergirem.

## 4. Invariantes respeitadas

- Nenhuma proposta funde fases de `engineer/*` ou `product/*` (juiz adversarial: 0 vetos de fase).
- D4/D5/D9 rodaram como scan focado herdando os gates canônicos (≤18 meses; artefatos de alto
  risco; no-op em templates) — permitido pelo evolve.md quando delegar aninharia orquestração.
- Read-only respeitado: nenhuma mutação em `.claude/` por este run; escrita = este relatório +
  o `.kg.yaml` (dogfood F2).

## 5. Próximos passos

1. **Quick-wins S (itens 1-5, 10-11, 13-14)**: uma sessão de edição dirigida fecha 9 itens.
2. **Guarda de links da co-evolução** (alerta transversal #1) — prevenção > correção.
3. **Cluster de cerimônia de agentes** (itens 6-7, 12): rodada de `/meta:create-knowledge-base` + redução.
4. **F2 concluído neste run**: `/meta:kg` + `kg-radar.sh` nasceram do dogfood — ver o `.kg.yaml` e o ADR.
