---
description: >
  Pesquisa com a lente do Onion — estado da arte, "como o mercado faz X", "vale a pena Y", comparar
  opções, tendência, benchmark, "o que mudou em 2026", contexto para uma decisão. Ative quando o
  usuário pedir pesquisa, estudo, levantamento, estado da arte, comparação de ferramentas/abordagens,
  "pesquise", "o que existe sobre", "está atual?", mesmo sem dizer "pesquisa". Injeta o CORPUS (o que
  os grafos já sabem) antes de qualquer busca, fixa os eixos invariantes (Claude Code atual, mercado/
  capital, trajetória, analistas, comunidade) e conduz ao workflow salvo /onion-research, que grava o
  resultado em .kg.yaml bi-temporal com tier de fonte e radar exit 0. NÃO ative para bug/código local
  nem para perguntas que o corpus já responde (aí a resposta é o próprio corpus).
---

# 🔭 onion-research — pesquisar com o corpus primeiro e o mercado sempre

A doutrina inteira: `.claude/commands/common/prompts/research-doctrine.md` (10 cláusulas). Esta skill é o
**caminho executável** dela — o maestro não redige a diretriz; ela chega como contexto e a maquinaria valida.

## Contexto injetado (0 tokens de raciocínio — lido antes de você pensar)

**Hoje:** !`date +%F`
**Claude Code (disco / processo):** !`claude --version 2>/dev/null | head -1` / !`basename "${CLAUDE_CODE_EXECPATH:-?}"`
**O que os grafos JÁ sabem sobre `$ARGUMENTS`:**
!`bash .claude/validation/kg-corpus-grep.sh $ARGUMENTS 2>&1 | head -40`

**Roster de fontes por eixo:** `docs/onion/radar-sources.yaml` (tier default por fonte; `vendor-on-competitor` sempre suspeito).

## Etapas

1. **Corpus primeiro.** Leia o bloco acima. Igual → transfere (responda do corpus e pare, ou cite os nós);
   diferente/ausente → desenha a pesquisa. Nunca re-derive o que um nó `confirmed` com `verified_at`
   recente já diz — cite o id.
2. **Gênero da pergunta** (dirige o pipeline): `qa` (fato) · `landscape` (estado da arte/mercado) ·
   `decision` (opções para o maestro selar) · `validation` (hipótese a refutar). Diga qual.
3. **Orçamento** (declare, nunca silencie): `maxFetch` (default 15) e `maxVerify` (default 25); excedente
   volta NOMEADO no retorno. Custo típico medido: 68–74k tokens por nó no censo — compare no `valeu-a-pena`.
4. **Rode o workflow** — o comando é o opt-in do `Workflow`:
   ```
   Workflow({ scriptPath: '.claude/workflows/onion-research.js', args: {
     question: '<pergunta>', corpus: '<bloco do corpus acima, verbatim>', today: '<hoje>',
     slug: '<kebab-case>', kgPath: 'docs/evolution/research/<slug>-<AAAA-MM>/<slug>-<AAAA-MM>.kg.yaml',
     budget: { maxFetch: 15, maxVerify: 25 } } })
   ```
   Fases: Corpus → Scope (ângulos do tema + 5 eixos fixos) → Search → Fetch (tier/kind/validFrom por fonte)
   → Verify (3 votos, 2 refutam; `vendor-on-competitor` sem primária = refutada) → Synthesize (seção
   **mercado obrigatória**) → **write(KG)** (o agente escreve o grafo e prova radar exit 0; sem 0 o run
   devolve erro).
5. **Depois do run** (o que o workflow não faz): `SYNTHESIS.md` como PROJEÇÃO do grafo com o contrato de
   custo no frontmatter (`kg:`, `run_id`, `tokens`, `agents`, `duration_min`) e as seções **NÃO-VERIFICADOS**
   (do retorno: `unverified`, `refuted` por fonte fraca, `notVerifiedByBudget`, `budgetDropped`) e
   **valeu-a-pena** (tokens ÷ nós); `meta.review_after` pela cadência do tipo dominante (REGRA 67);
   `docs/backlog.md` regenerado se houver nó open; resíduo REGRA 56; PR pelo fluxo normal.
6. **Se a pergunta é para DECIDIR** ("devo", "vale a pena", "qual escolher", "o que podar"): passe `mode: 'decision'`
   nos `args`. O workflow ganha a fase **Elenxo** (refutador opus/high, default REPROVADO): refuta cada achado **e**
   interroga cada descarte — *"por evidência ou por comodismo/hype/orçamento?"*; o descarte por comodismo volta
   como objeção sobrevivente. O `write(KG)` escreve **1 nó `decision` OPEN** (opções nomeadas + recomendação)
   com `CONSTRAINS` das objeções sobreviventes. **Você nunca sela**: informe ao maestro o id do nó `D_` e a
   tabela de selagem do `/meta:drive` (KIND decision). O retorno traz `decision: {options, objections,
   recommendation}`.

7. **Se as lacunas JÁ TÊM NOME** (rodada complementar, revisita dirigida, ou qualquer pergunta cujo eixo
   um run anterior já declarou): passe `mode: 'primaries'` e a lista de fontes NOMEADAS. O pipeline vira
   **Leitura → Ancoragem → Elenxo → write(KG)** — Scope/Search/Fetch/Verify **não rodam**.
   ```
   Workflow({ scriptPath: '.claude/workflows/onion-research.js', args: {
     mode: 'primaries', question: '<a pergunta / o que esta rodada precisa fechar>', today: '<hoje>',
     corpus: '<bloco do corpus acima, verbatim>',
     kgPath: '<.kg.yaml — se JÁ EXISTE o write APENDA (Aufhebung); se não, cria>',
     sources: [ { key: 'lgpd-bases',            // id curto da fonte (vira o label do agente)
                  gap:  'a lacuna NOMEADA que ela fecha',
                  prompt: 'o documento e como chegar nele (o quê ler, quais artigos/seções, em que site)' } ] } })
   ```
   - **Leitura** (1 leitor por fonte, sonnet/medium): lê o documento INTEIRO por WebFetch/WebSearch. Claim só
     existe com `quote` **verbatim** (30-400 chars) + `locator`; sem citação, não existe. `reachable=false`
     quando não chegou — nunca inventa.
   - **Ancoragem** (1 verificador por fonte, **agente SEPARADO** do leitor, sonnet/high): **reabre o documento**
     e responde *"a citação existe? o claim estica o texto?"* → `ANCORADA` · `EXAGERADA` (com `corrected`) ·
     `NAO-ENCONTRADA`. **Default na dúvida: NAO-ENCONTRADA.** Claim rejeitada aqui **nunca vira nó** — entra
     na contabilidade do `E_LACUNAS_…`.
   - **Fail-loud**: `mode: 'primaries'` sem `sources` utilizável devolve **erro nomeado** e não escreve nada.
     O modo **nunca** cai em varredura sozinho — se as lacunas não têm nome, peça varredura explicitamente.

   **Gatilho de escolha (a régua, não o gosto):**

   | Estado da pergunta | Modo | Por quê |
   |---|---|---|
   | Campo DESCONHECIDO, as lacunas **não têm nome** | `research` / `decision` (varredura larga) | é preciso DESCOBRIR quais são as fontes |
   | As lacunas **JÁ TÊM NOME** (rodada complementar, revisita dirigida, eixo declarado por um run anterior) | `primaries` | não se paga descoberta duas vezes; paga-se leitura e ancoragem |

   **Custo medido na MESMA pergunta** (indivíduo × organização, 2026-09-13):

   | Modo | Run | Tokens | Agentes | Nós | Por nó | Veredito |
   |---|---|---|---|---|---|---|
   | varredura (`decision`) | `wf_88199ba9-b9a` | 7.282.373 | 105 | 25 | ≈291k | **19 de 25** claims refutadas — a maioria por **fonte fraca**, não por evidência contra |
   | primárias (`primaries`) | `wf_1865aba9-e20` | 2.680.149 | 28 | 64 | ≈42k | 13/13 fontes alcançadas · **62 ancoradas** · **14 rejeitadas na ancoragem** (13 exageradas, 1 não encontrada) |

   Os dois retornos estão versionados em
   `docs/evolution/research/compartilhamento-individuo-organizacao-2026-09/data/`. A **ancoragem** é a peça que
   pegou o defeito que a votação 3/2 da varredura não pegava: lá três juízes discutem a claim; aqui um
   verificador **reabre o documento**.

## Fronteiras declaradas

- Só a sessão principal roda o workflow (opt-in por comando); subagente não orquestra.
- Sem WebSearch disponível o workflow degrada: use `WebFetch` sobre fontes do roster e declare.
- Não há cota de busca entre sessões (a plataforma zera em `/clear`): o orçamento é seu, por rodada.
- **Revisita** (F4): a REGRA 67 (grafo vencido) e a REGRA 69 (fonte do roster vencida) avisam no lint; você roda
  `Workflow({scriptPath: '.claude/workflows/onion-research.js', args: { question: '<a pergunta original>', revisit: '<caminho do .kg.yaml>', today, budget, cadenceDays: <opcional: força a cadência — "revisite agora"> }})`
  — só os nós de evidência vencidos (verified_at anterior a hoje − cadência) são re-medidos pela mesma votação;
  confirmados ganham `verified_at` novo, refutados ganham nó novo + `SUPERSEDES` (Aufhebung), e `meta.review_after`
  avança. Nunca cron (MOAT W7). Nós sem URL: `/meta:kg-freshness`.
