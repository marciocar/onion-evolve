# 🔭 Doutrina de pesquisa (fragmento canônico — a lente que o maestro não redige mais)

> **Fragmento canônico compartilhado (SSOT).** Referenciado — **não copiado** — por `/meta:radar`,
> `@research-agent`, `/meta:kg` e pela rule `.claude/rules/research-lens.md` (carrega ao tocar
> `docs/evolution/research/**`). Nasceu de `docs/evolution/research/meta-research-lens-2026-09/`
> (ordem do maestro, 2026-09-02): 70% disto já vivia em `/meta:radar`; o resto era re-digitado a cada
> rodada. É **contexto**, não procedimento — a força é o Transformer; a maquinaria (radar, lint, catraca)
> **valida a saída**, nunca dirige o modelo por prosa. Não entra no CLAUDE.md (instruction bloat está em
> CAUTION no Thoughtworks Radar v34, e descreve o core).

## As 10 cláusulas (checklist executável — cada uma tem mecanismo ou lacuna declarada)

| # | Cláusula | Mecanismo | Faça |
|---|---|---|---|
| 0 | **O corpus primeiro** | `bash .claude/validation/kg-corpus-grep.sh <tema>` | Antes de buscar fora: o que os grafos já sabem (nós, datas, vereditos, tiers). Igual → transfere; diferente → desenha (régua do `/meta:adopt`). |
| 1 | **Onion como lente** | esta tabela + `onion-orchestration` | Toda pergunta passa por: KG-SSOT first/runtime · dogfood · SDAAL · breadcrumbs · gate determinístico. |
| 2 | **Claude Code na versão ATUAL** | eixo E3 + REGRA 65 (`cc_version` do PROCESSO) | Conferir `claude --version` E o processo (`CLAUDE_CODE_EXECPATH`); changelog oficial é fonte primária. **Para "qual é o valor/comportamento de X no Claude Code", o ARTEFATO INSTALADO vem antes da web** (`python3 re.finditer` sobre o binário = tier 10; medido 2026-09-02: 1 comando fechou o que 1,3 M tokens de busca não fecharam). |
| 3 | **Fontes amplas e emergentes** | `docs/onion/radar-sources.yaml` (F2) · search-by-trajectory | Oficial → paper → engenheiro reconhecido → analista (Gartner, YC, Thoughtworks, Forrester) → fórum/comunidade → repos por TRAJETÓRIA (`created:>` + `sort=stars`, HN Algolia). Buscar por nome só acha incumbente. |
| 4 | **Caminho do dinheiro — SEMPRE** | eixo E4 · worker de mercado no fan-out | Rodadas, M&A, parcerias, down rounds dos últimos 6–12 meses. Capital mostra o ESCASSO (construir); M&A antecipa feature de outro (integrar); down round mostra tese que caiu. Invariante, não opção por tema. |
| 5 | **Revisar o que temos** | inventário interno read-only (worker) | Forte/fraco, perto/longe, contra o mercado — com `arquivo:linha`. |
| 6 | **Não reinventar / não abandonar** | Elenxo + pergunta explícita | Ideia descartada responde *"por evidência ou por comodismo/hype?"* — a resposta vira nó `CONSTRAINS`/`REFUTES`, nunca some. |
| 7 | **Escolher fontes é dado + campo + guarda** | `source_tier`/`source_kind` no nó · SOFT no lint | Tier DREAM 1–10 (9–10 definitiva · 7–8 alta · 4–6 moderada · 1–3 baixa). `vendor-on-competitor` é **sempre suspeito**. Confiança ≥ 0,8 com tier ≤ 3 sem fonte primária = SOFT. Citação se verifica **re-buscando** (o trecho existe e sustenta), não lendo. |
| 8 | **Guardar em `.kg.yaml` com temporalidade** | `valid_from` + `verified_at` + `meta.review_after` · SOFT no lint | Bi-temporal: *quando o fato passou a valer* ≠ *quando EU verifiquei*. Cadência por tipo: ferramenta/preço 30 d · lineup de modelos 45 d · mercado/capital 90 d · benchmark 120 d · doutrina 12 m ou gatilho nomeado. Lacuna vira nó (cobertura completa é ~13% mesmo nos líderes — WANDR 2026). |
| 9 | **Decisões revisáveis, nunca apagadas** | `SUPERSEDES`/`REFUTES` · `/meta:kg-freshness` | Supersessão é operação nomeada; re-testar, nunca re-carimbar. |
| 10 | **Ferramenta sem uso é custo** | contrato de custo no frontmatter (`run_id/tokens/agents/duration_min`) · `valeu-a-pena` | Toda síntese declara o que custou e o que devolveu; regressão de custo/nó é achado. |

## Duas formas de rodada — e o gatilho que escolhe (não é gosto, é o estado da pergunta)

A cláusula 3 (fontes amplas) e a 7 (escolher fontes é dado + campo + guarda) se realizam de **duas formas**,
e o que decide é se **as lacunas já têm nome**:

| Estado da pergunta | Forma | Mecanismo |
|---|---|---|
| Campo **desconhecido**, lacunas **sem nome** | **varredura larga** — descobrir quais são as fontes | `mode: 'research'` / `'decision'`: Scope → Search → Fetch → Verify (3 votos, 2 refutam) → Synthesize → write(KG) |
| Lacunas **JÁ NOMEADAS** — rodada complementar, revisita dirigida, ou pergunta cujo eixo um run anterior declarou | **primárias nomeadas** — ler a fonte inteira e ancorar cada claim | `mode: 'primaries'` + `args.sources: [{key, gap, prompt}]`: Leitura → **Ancoragem** → Elenxo → write(KG) |

**A ancoragem é a peça nova** (e é o que compra o modo): o claim só existe com `quote` **verbatim** + `locator`,
e um **segundo agente, independente do leitor, reabre o documento** e julga — `ANCORADA` · `EXAGERADA` ·
`NAO-ENCONTRADA`, **default na dúvida NAO-ENCONTRADA**. É outra coisa que a votação adversarial 3/2: lá três
juízes **discutem a claim**; aqui um verificador **confere o texto**. Claim rejeitada na ancoragem nunca vira
nó — entra na contabilidade do `E_LACUNAS_…` (cláusula 8, lacuna vira nó).

**Custo medido na MESMA pergunta** (indivíduo × organização, 2026-09-13 — cláusula 10, ferramenta sem uso é custo):

| Forma | Run | Tokens | Agentes | Nós | Por nó | O que a rodada revelou |
|---|---|---|---|---|---|---|
| varredura larga | `wf_88199ba9-b9a` | 7.282.373 | 105 | 25 | ≈291k | **19 de 25** claims refutadas, a maioria **por fonte fraca** — pagou-se busca para descobrir fonte que o Verify depois derrubou por tier |
| primárias nomeadas | `wf_1865aba9-e20` | 2.680.149 | 28 | 64 | ≈42k | **13/13** fontes alcançadas · **62 claims ancoradas** · **14 rejeitadas na ancoragem** (13 exageradas, 1 não encontrada) |

Retornos versionados em `docs/evolution/research/compartilhamento-individuo-organizacao-2026-09/data/`.
**7× menos token por nó não é desconto: é a descoberta já paga.** Usar primárias num campo desconhecido só
move a descoberta para fora da maquinaria — por isso o modo **falha com erro nomeado** sem `args.sources`,
em vez de cair em varredura calado.

## Régua de saída (o que uma pesquisa Onion entrega, sempre)

1. **Grafo primeiro** (`.kg.yaml`, radar exit 0, TETO declarado) — a prosa é projeção.
2. **NÃO-VERIFICADOS** como lista de 1ª classe (com o motivo: 403, doc truncada, só agregador…).
3. **Mercado/capital** presente mesmo que o tema seja técnico.
4. **Custo declarado** e comparado ao histórico.
5. **Próxima revisita** carimbada (`meta.review_after`).

Doutrina completa (artefato do CORE, não vendorizado — no adotante este caminho não existe): a pesquisa
`docs/evolution/research/meta-research-lens-2026-09/` (grafo de 26 nós com o inventário interno, o estado da
arte de deep research e KG temporal, e o eixo mercado/capital que fundamentam cada cláusula acima).
