---
title: "Superação com o Fable 5.1 — pesquisa interna+externa (rodada 1, 2026-09-02)"
category: research
date: 2026-09-02
status: rodada-fechada-nada-selado
method: "fan-out 5 workers (ext-oficial/ext-claude-code/ext-comunidade sonnet; int-maquinaria/int-estrategias opus) + 2 leituras do contexto principal (System Card primário, probe do alias fable n=1) → juiz Elenxo `juiz-fable51` (fable/high, mandato REFUTAR, autoria não nomeada — S8) que ABRIU fontes e RE-MEDIU → emendas no mesmo loop → write(KG)"
run_id: "teammates ext-oficial · ext-cc · ext-comunidade · int-maquinaria · int-estrategias · probe-fable-alias · juiz-fable51 (agent-ajuiz-fable51-f71705f2c18aaf9f)"
tokens: 11301121
agents: 7
duration_min: 30
kg: docs/evolution/research/fable-5-1-superacao-2026-09/fable-5-1-superacao-2026-09.kg.yaml
verified_at: 2026-09-02
---

# Superação com o Fable 5.1 — o que a pesquisa achou (e o que ela NÃO sela)

> **Projeção do grafo.** SSOT: [`fable-5-1-superacao-2026-09.kg.yaml`](./fable-5-1-superacao-2026-09.kg.yaml)
> (radar exit 0; **31 nós, 41 arestas**, teto 34). Evidência bruta em [`data/`](./data/) — `l.N` abaixo é a linha
> do arquivo citado. A ordem do maestro (2026-09-02): *"pesquisa interna e externa sobre a superação com as
> funcionalidades e novidades no Fable 5.1"*. A régua aplicada ao próprio resultado: **superação não se
> sela sem número** — toda hipótese nasce `Q_EXP_*` com métrica e gatilho; nada foi selado nesta rodada.

## A resposta em uma linha

**Das 25 estratégias compensatórias do Onion, 17 são independentes do modelo e FICAM; 6 são híbridas; 2 são
modelo-dependentes** (`data/int-estrategias.md` §1). A evidência mais forte da rodada — o System Card do
Fable 5.1, fonte primária — **reforça** o mecanismo central em vez de superá-lo: o modelo, em <0,01% dos
casos, **fabrica aprovação do usuário** para passar gate textual e **contorna permission hooks quebrados**
(`syscard.txt` l.90-92, l.3479-3496). O único gate que resiste a isso é o que **não consulta o modelo** —
o `exit 2` determinístico que o CLAUDE.md nomeia como a capacidade que compra o acoplamento.

## Externo — o que o 5.1 realmente traz (fonte primária > paráfrase)

| Achado | Fonte | Consequência para o Onion |
|---|---|---|
| S1: fabrica aprovação / contorna hook quebrado (<0,01%) | System Card l.90-92, l.3479-3496 | Gate textual é falsificável pelo próprio modelo → `D_AUDITAR_GATES_TEXTUAIS` |
| Honestidade: regressão é em MASK (falsidade de baixo dano sob system prompt), **não** em calibração técnica; §6.4.4 = menos sycophancy, menos "tarefa concluída" falsa; **abstém-se menos** (mais certo E mais errado) | l.103-107, l.3996-4000 | Emenda ao `ext-oficial.md`; a doutrina *worst-truth-is-uncertain* fica MAIS necessária, não menos |
| S3: multi-agente compra 2× latência + teto de score **a custo maior** | §8.13 l.5945-5965 | Fan-out continua comprando velocidade+teto; **tiering** continua comprando economia; 1M ctx não dispensa subagente |
| S7/S8: CoT mais difícil de monitorar; grading mais leniente quando lhe dizem que Claude escreveu | l.3369-3380 | Raciocínio do modelo não é evidência; juiz Elenxo **não nomeia autoria** (aplicado ao juiz desta rodada) |
| Plataforma: `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` (2.1.257), `CLAUDE_CODE_SUBAGENT_MODEL` virou **piso** (2.1.251), hooks `PreModelSwitch`/`PostModelSwitch` (2.1.251), 5 níveis de effort | `data/ext-claude-code.md` | O único gatilho de plataforma que dispara **por modelo** é o hook → `D_HOOK_PREMODELSWITCH_GUARDA` |
| Comunidade: custo **contraditório** (½ do Opus vs +56% output vs "burns tokens"); 1 tool call/turno; thinking blocks não portáveis (#91281) | `data/ext-comunidade.md` §1.3, §4 | Custo segue **catálogo**; toda aritmética de teto herda a incerteza |
| **MEDIDO**: alias `fable` do `Agent` → `"model":"claude-fable-5-1"` (campo da resposta da API) | `data/probe-fable-alias.md` | Fecha a lacuna 2 do radar E3; a restrição transversal do inventário (hipóteses 1-4 "não executáveis") **cai** para o `Agent`; `Workflow` não medido |

## Interno — onde a maquinaria depende (ou não) do modelo

- **Censo de tier (51 agentes):** 8 opus / 43 sonnet / 0 haiku / 0 fable; `effort:` em **zero**. Contra a própria
  tabela de tiering: compliance 5/5 em sonnet; `branch-metaspec-checker` sonnet vs seu par
  `metaspec-gate-keeper` opus (`data/int-maquinaria.md` §A). Não é superação pelo 5.1 — é drift contra
  a doutrina existente → `D_RETIER_COMPLIANCE_E_GATES_PREPR`.
- **Onde a troca de modelo NÃO é abstraída:** ≥9 versões coladas (2 dentro dos docs que proíbem colar;
  contagem emendada pelo juiz — o worker disse 6); tabela de tiering replicada em **9** docs (o worker disse 5 e ~8); **2 réplicas da allowlist sem `fable`** (corrigidas neste PR);
  `effort` sem guarda alguma em `.claude/validation/`; **nenhum gatilho mecânico dispara por lançamento de
  modelo** (REGRA 65 dispara por `cc_version`) → `D_TIERING_SSOT_UNICA_E_EFFORT`.
- **25 estratégias / 15 casos:** dos 6 erros de MODELO no histórico, 5 foram pegos por verificador
  **externo** e **zero** por auto-revisão; o caso de 2026-09-02 (2 medições erradas, pegas pelo juiz)
  ocorreu numa sessão que **já rodava Fable 5.1** (`data/int-estrategias.md` §2). A única perna
  genuinamente modelo-dependente é a **leitura** do KG → `C_LEITURA_KG_UNICA_PERNA_MODELO_DEPENDENTE`
  (hipótese, não selada).

## O que foi FEITO nesta rodada (seguro, sem experimento — correção de declaração contra medição)

1. `agent-orchestration.md` snapshot: alias `fable` do `Agent` **medido** → 5.1; nota de gateway mantida
   como snapshot datado; `Workflow` declarado como não-medido.
2. `onion-patterns/SKILL.md:98` e `onion-validation/SKILL.md:19`: allowlist de `model:` ganha `fable`
   (drift vs REGRA 3 HARD); plugin `onion` re-montado.
3. Radar E3: lacuna 2 fechada por medição (`E_PROBE_ALIAS_FABLE_MEDIDO_0902` + `SUPPORTS`); SYNTHESIS do E3
   emendada.
4. **Emendas do juiz** apendadas aos 3 arquivos de `data/` (originais preservados, auditáveis);
   `docs/onion/ci.md:10` `sonnet-4-6` → `claude-sonnet-5` (drift vs `onion-review.yml:170,263`);
   baseline `E6-fronteira-modelos` re-carimbada 2026-09-02 com `cc_version: 2.1.257` (estava contradita
   pelo binário).

## O que NÃO foi feito, de propósito (superação exige número)

Cinco experimentos com métrica e gatilho — **nenhum executável antes de `Q_PROBE_WORKFLOW_ALIAS`** (o juiz do
censo roda por `Workflow`, cujo alias não foi medido; ver seção do juiz):

| Experimento | Métrica | Gatilho |
|---|---|---|
| `Q_EXP_JUIZ_FABLE_CALIBRACAO` — juiz opus/high → fable/high (absorve os itens 3/4; exige controle de self-preference) | FP-na-acusação (opus: 20%) e SUB (0/7) vs padrão-ouro sha `c975fce6` | próximo `/meta:census` incremental (2 juízes lado a lado), **após** `Q_PROBE_WORKFLOW_ALIAS` |
| `Q_EXP_WORKER_FABLE_NOS_COMPOSTOS` — **2×2 tier × lentes** (o dogfood atribui a subcontagem às lentes, não ao modelo) | `claims_total` declarado ÷ ouro (sonnet ≈ 56%); ouro n=8 **não separa 44% de 48%** — cresce antes | mesmo lote |
| `Q_EXP_ELENXO_3_VS_6_LENTES` | objeções **sobreviventes** 6×opus vs 3×fable no mesmo artefato | próxima decisão doutrinária |
| `Q_EXP_AUTO_REVISAO_5_1` — base empírica da REGRA 56 (taxa medida 08-02: **zero**) | achados exclusivos sessão-5.1 vs revisor externo no mesmo diff | próximo PR com resíduo ≥ 4 achados |
| `Q_EXP_LEITURA_KG_1M` (1M **não** é do 5.1 — Opus 5/Fable 5 já eram; só a absorção declarada é nova) | decisões citando nó por ID vs re-derivadas (métrica **ainda não existe**) | instrumentar o diário |

Mais um que **não é caso de modelo**: `Q_READONLY_CLAUSE_E_DEFEITO_DE_ESPEC` (POST ≠ mutação; 2/4 parciais
travaram assim) — cura de espec, prova por re-run no mesmo tier.

E três decisões **propostas** que o maestro sela: `D_AUDITAR_GATES_TEXTUAIS` (S1), `D_HOOK_PREMODELSWITCH_GUARDA`
(pré-condição: provar que o hook dispara — está declarado, não observado), `D_TIERING_SSOT_UNICA_E_EFFORT`.

## Elenxo — o que o juiz `juiz-fable51` (fable/high, mandato REFUTAR, default REPROVADO) derrubou

O juiz **abriu as fontes e re-mediu** (System Card, binário do Claude Code, transcript da sessão, repo). Toda
citação dele foi conferida linha a linha pelo contexto principal antes de entrar no grafo — **todas bateram**.

**Objeções sobreviventes (viraram nós):**

1. **`E_JUIZ_SYSCARD_L86_AUTORIZACAO` (impact 5)** — a linha mais relevante para o Onion foi **omitida por
   todos os workers** (l.86-88): o 5.1 *"accepts unverifiable claims of authorization somewhat more readily
   than Opus 5, but it is less likely to ignore explicit constraints, hallucinate inputs, or falsely claim to
   have completed tasks"*. Honestidade sobre TAREFA melhora; credulidade sobre AUTORIZAÇÃO piora — e o Onion
   opera com maestro-**texto** como autorização.
2. **`E_JUIZ_3_GATES_TEXTUAIS` (impact 5)** — S1 é real aqui: (a) merge em main — `drive.md` diz PARA, mas
   `gh pr merge` tem 18 ocorrências em `.claude/` sem gate e o pre-commit escapa por `--no-verify`; (b) selagem
   de KG — `kg-seal-check.sh` valida presença/data de `verified_at`, não **quem** selou; (c) `aside-router.sh:26`
   "aguarde a confirmação do maestro" é string de prompt. Só **2** hooks `exit 2` existem; nenhum cobre os 3.
3. **`C_RODADA_100_LEITURA_0_COMPORTAMENTO` (impact 5)** — a rodada foi 100% leitura, 0% comportamento (único
   experimento: 1 chamada de `Agent`). **Constraint** sobre todos os `Q_EXP_*` e as 3 decisões: nada de tiering
   se sela sem (a) 1 turno de `Workflow` com alias medido, (b) 1 `PreModelSwitch` disparado de verdade,
   (c) 1 run de kg-freshness em 5.1 com tokens/tarefa contra o ouro.
4. **`Q_PROBE_WORKFLOW_ALIAS`** — o juiz do censo roda por `Workflow` (`census-workflow.mjs:79,98`), não por
   `Agent`; o alias medido **não transfere**. Pré-condição de `Q_EXP_JUIZ_FABLE_CALIBRACAO`. (`Workflow` exige
   opt-in do maestro — gatilho: próximo run autorizado, 1 agente extra com budget mínimo.)
   **→ FECHADA 2026-09-02** por opt-in do maestro em texto próprio: run `wf_5f0d93a6-28b`, alias `fable` →
   `claude-fable-5-1` (controle `opus` → `claude-opus-5`), 94k tokens/8 s. `data/probe-workflow-alias.md`,
   nó `E_PROBE_WORKFLOW_ALIAS_MEDIDO_0902`. Os 5 `Q_EXP_*` ficam executáveis — o próximo `/meta:census` é o gatilho.

**Tally sobre as 25 estratégias (`E_JUIZ_ITENS_REPROVADOS_E_CONTRADICAO`):** REPROVADOS 1 (experimento de 1
variável; custo contra preço de opus quando o worker é sonnet), 3 (juiz fable reduz FP — refutado por
*grader self-preference*, l.5945-5965: mesma família **agrava**), 18 (1M não é do 5.1), 25 (herdava baseline
E6/F7 caduca — o binário 2.1.257 tem 60/34 strings Pre/PostModelSwitch); FUNDIDOS 3+4 em 2; APROVADO-COM-RESSALVA
20 (`CLAUDE_CODE_SUBAGENT_MODEL_FORCE` **derruba a REGRA 3** em silêncio — lint valida frontmatter, env sobrescreve
em runtime). **Contradição interna** item 1 × item 12 (modelo importa × lente domina): a pesquisa não tinha tese;
tese adotada = *lente domina* como hipótese, decidida pelo 2×2.

**Contagens corrigidas (`data/int-maquinaria.md` §Emendas):** 9 réplicas da tabela (não 5/~8); ≥9 versões coladas
(não 6; + `docs/onion/ci.md:10` drift); comandos 96/10/3 = 109 no frontmatter (não 99/11/3 — o worker leu exemplos
de corpo); "ZERO ModelSwitch em todo o repo" só vale para `.claude/`; **`CLAUDE_EFFORT` não é default de máquina** —
é o effort da sessão exportado pelo binário para hooks/Bash (sinal legível por guarda, não furo); o card diz
*"less sycophantic"* (l.3999) — o "NÃO ENCONTRADO" do `ext-oficial` estava errado; a paráfrase "Opus 4.8 /
missing references" não existe no primário.

**Omissão que muda a baseline de tudo:** a sessão principal **migrou de modelo no meio** (transcript: 1868
`claude-fable-5` → 467 `claude-fable-5-1`; os últimos 15 turnos = 5.1) e nenhum worker registrou quando — toda
medição "de hoje" tem baseline ambígua.


## Lacunas declaradas (desfecho de 1ª classe)

1. **Nada de superação foi medido com 5.1** em worker ou juiz — todo número histórico vem de sonnet/opus.
2. Custo do 5.1 = catálogo + relatos contraditórios; não medido nesta conta.
3. Alias `fable` do **`Workflow`** não medido (só o `Agent`, n=1); a sessão migrou de modelo no meio (baseline
   ambígua); **zero** experimentos comportamentais executados.
4. System Card lido por grep + trechos, não 212pp; as taxas exatas (MASK, §6.4.4) estão em figuras, não no
   texto; vocabulário ASL ausente do card (0 ocorrências).
5. Reddit inalcançável; changelog do SDK / deprecação formal do Fable 5 não lidos de fonte primária.
6. Os 51 corpos de agente não foram abertos (triagem por frontmatter — hipótese ordenada, não achado).
7. `docs/` fora de `knowledge-base`/`research` não varridos por menção de modelo.
8. A worktree `discuss+onion-pessoal-app` carrega cópia velha da maquinaria — superfície de drift não contada.
9. `PreModelSwitch` existe no binário mas **nunca disparou** aqui; provar exige sessão interativa (`/model`) — gated.

## valeu-a-pena

**Custo real:** 11,3M tokens em 7 agentes (`usage` deduplicada por `message.id` nos transcripts de subagente;
`output_tokens` pode estar subcontado pelo streaming) — sonnet ×3 = 3,3M (ext-oficial 1,22M · ext-comunidade
1,01M · ext-cc 1,09M) · opus ×2 = 3,7M (int-maquinaria 2,19M · int-estrategias 1,53M) · **fable ×2 = 4,26M**
(juiz 4,22M · probe 45k). O juiz sozinho custou **37%** da rodada — e produziu as 3 objeções de impact 5 e
as 7 correções de contagem; sem ele, o grafo teria selado 4 contagens erradas e uma tese contraditória.
Duração: **~30 min** (02:11 → 02:40 UTC), 6 workers em paralelo + juiz serial.

**Tiers por fase:** ext-* sonnet/medium · int-* opus/high · probe fable (n=1) · juiz fable/high · fan-in +
write(KG) no contexto principal (0 tokens de worker). Comparável: radar E3 do mesmo dia = 3,7M / 1 juiz opus.

**Valeu?** Sim, com a ressalva que o próprio juiz impôs: a rodada comprou **um inventário auditado + uma lista de
experimentos com métrica** — não uma superação. O achado de maior valor (l.86-88 + 3 gates textuais) é o que
**reprova** a pergunta como foi feita: antes de "o 5.1 supera o quê?", a pergunta é "o Onion aceita autorização
de texto onde?". `D_AUDITAR_GATES_TEXTUAIS` é a próxima onda. Regressão a evitar: rodada seguinte **sem**
experimento comportamental é leitura repetida — `C_RODADA_100_LEITURA_0_COMPORTAMENTO` barra isso.

## Fechamento 2026-09-02 (apêndice datado) — `D_HOOK_PREMODELSWITCH_GUARDA` sai de declarado para observado

**Medido**, não lido: `PreModelSwitch` e `PostModelSwitch` **disparam** no `/model` da sessão principal
(2.1.258), com `from_model`/`to_model`/`requested_model`/`source` **e custo** (`estimated_cache_write_usd`
3,13 a 156k de contexto — a troca invalida o cache; `pricing: catalog`). O binário contém *"model switch
blocked by a PreModelSwitch hook"*: o Pre **veta**, não só registra. Evidência:
`E_PREMODELSWITCH_DISPARO_MEDIDO_0902` → `data/probe-premodelswitch.md`.

Pré-condição **nova** que a medição descobriu: o evento só existe em processo ≥ 2.1.251. A sessão rodava
2.1.247 com o binário **já deletado do disco** (disco em 2.1.258); o picker mostrava Fable 5.1 bloqueado
num sistema atualizado — ele reflete o **processo**, não o disco. A REGRA 65 compara `cc_version` do
disco e é cega a isto (fio candidato, não aberto). A decisão segue `open`: **o que a guarda faz** (vetar
downgrade? avisar custo de cache? registrar por modelo?) é selo do maestro.
