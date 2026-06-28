---
title: 'Revisão adversarial em orquestração — ADR de topologia de orquestração (locus × forma)'
date: 2026-06-22
type: orchestration-review-report
status: executado (refinos camadas 1-2 aplicados ao ADR; camada 3 diferida à promoção)
scope: revisão do ADR onion-orchestration-topology-adr-2026-06-21
run_id: wf_e7ae4944-674
target: docs/analysis/onion-orchestration-topology-adr-2026-06-21.md
note: "Proof-point da revisão (dogfood: revisar a doutrina de orquestração usando a própria orquestração). Output bruto: /tmp/.../tasks/wcutuh3rs.output (efêmero)."
---

# Revisão adversarial em orquestração — ADR de topologia de orquestração

## 0. Sumário do run

| | |
|---|---|
| Padrão | fan-out-and-synthesize + verificação adversarial (dogfood: orquestração revisando a doutrina de orquestração) |
| Lentes (review) | 5 — coerência-doutrinária · âncoras/citações · lógica-do-gatilho · nomenclatura · tensão-KB |
| Workers | 21 agentes · ~838K tokens · 108 tool-uses · ~9,5 min |
| Fan-in | determinístico em JS a 0 token (fiel ao próprio ADR: síntese no orquestrador, não em agente) |
| Achados brutos | 16 |
| Refutados pelo verificador | **0** |
| Veredito por verdict | 6 `confirmed` · 10 `partial` (verificador rebaixou exageros de revisor) |
| Severidade | **0 blocker · 0 major** · 7 minor · 9 nit |
| **Decisão central do ADR** | **VALIDADA** — distinção locus×forma sólida; contra-ponto W/m *fortalece* (não mina) |

> **Nota de método:** o estágio de verificação foi genuinamente adversarial — rebaixou 10/16 a `partial`
> apontando que vários fixes propostos já estavam parcialmente no ADR (ex.: CA1–CA3 cobrem parte do
> "gatilho não-operacionalizável"; a distinção sumarizador/sintetizador não está tão turva). Veredito de
> revisor tratado como hipótese verificada contra os arquivos reais, não como ordem.

---

## 1. Achados por tema

### Tema A — Citação stale (2 achados · confirmed · nit) → ✅ CORRIGIDO
Seção Referências citava `architecture.md` §4.2 na **linha 203** (regra errada: `agents/*→utils/*`); a
regra correta (`agents/*→commands/*=Não`) está na **204**. Corpo e footer já estavam em 204 — só a
seção Referências ficou stale. **Fix aplicado** (camada 1).

### Tema B — Critérios de aceite vendem "mecânico" onde é julgamento (3 · 1 confirmed/2 partial · minor) → ✅ REFINADO
- **CA3** atribuía a `/meta:metaspec-validate` (julgamento LLM, `model: sonnet`) uma prova mecânica
  "→ ✅". Verificado: `grep 'worker-orchestrator' .claude/agents/` retorna só a *referência-proibição* em
  `metaspec-gate-keeper.md`, nenhum agente real → a ausência estrutural é grep-able; a garantia
  *comportamental* ("nunca dispara orquestração") **não** é. **Fix:** CA3 separado em (a) ausência estrutural
  determinística + (b) conformidade de design por veredito LLM.
- **CA2** "grep não encontra agente que dispara orquestração" — grep pega a string literal, não a intenção
  semântica (expressa em prosa no `.md`). **Fix:** CA2 reescrito para a parte estrutural observável.
- **`b·m ≤ W`** decorativa (W/m/b sem valor nem método; o próprio ADR marca o paper como não-verificado).
  **Fix:** rebaixada a heurística de primeiros princípios ("input do sintetizador cabe na janela").

### Tema C — Nomenclatura "nó sumarizador" (3 · partial · minor/nit) → ⏳ DIFERIDO À PROMOÇÃO
- "Nó sumarizador" é **cunhagem**, não termo de mercado — tensiona a regra de linguagem ubíqua
  (`docs/evolution/README.md:23-25`). Equivalentes consolidados existem: *aggregator / sub-orchestrator /
  synthesizer*; e o próprio Onion já tem **"agente de síntese"** (`fan-out-and-synthesize`).
- Coexistência sumarizador (intermediário) × sintetizador (final) — distinção real, mas sem frase que a
  fixe. Mitigação atual ("nomenclatura") é circular na seção Negativas isolada.
- **Ação na promoção:** ancorar o termo ao equivalente de mercado / "agente de síntese" ao documentar na KB.

### Tema D — Tensão KB / procedência (3 · 2 confirmed/1 partial · minor/nit) → parcial: refinado + diferido
- **Doutrina "vigente" sem porta de entrada** — KB/SKILL não tocadas; o leitor da KB só vê a armadilha de
  *locus*. (Diferido: frase-âncora locus×forma na KB ao lado de `:461/:478`.)
- **Metadados incoerentes** — `status: accepted` + título "RASCUNHO" + `type: adr-draft` + filename
  `-draft-`. **4 referências cruzadas** em `onion-orchestration-math-phase-transition-2026-06.md` e
  `onion-orchestration-external-radar-2026-06.md` apontam para o nome atual. (Diferido: promoção `draft→adr` + atualizar refs.)
- **Espantalho leve** — a KB *silencia* sobre forma do grafo, não diz "hierarquia proibida". **Fix:**
  "O gap" reframado como inferência-por-omissão (camada 2). ✅

### Tema E — Coerência doutrinária / a base (3 · nit) → ✅ REFINADO (opcionais)
- Contra-ponto W/m **fortalece** a decisão (não mina): o ADR fecha um gap doutrinário mantendo o default
  plano. **Fix:** frase anti-objeção na abertura da Decisão. ✅
- Separar mecanismo **(a)** `parallel`/`pipeline` aninhados (a árvore legítima) de **(b)** nesting de
  subagentes `agents/*→agents/*` (delegação, não orquestração). **Fix aplicado** no Contexto. ✅
- `b·m≤W` como "tradução do paper" enquanto se desautoriza o paper — reancorado em primeiros princípios. ✅

---

## 2. Detalhe dos 16 achados (evidência preservada)

> Formato: `[lente] título — verdict/severidade`. Claim + evidência + fix + síntese da verificação.

1. **[lógica-gatilho] CA3 confunde validação estrutural (grep-able) com garantia comportamental** —
   *partial/minor.* `metaspec-validate` é julgamento LLM, não checador determinístico; a ausência do
   agente é grep-able, a garantia comportamental não. Verificador: núcleo correto; calibrado a partial
   porque o texto *literal* de CA3 reivindica só "não existe agente worker-orchestrator" (alvo modesto).

2. **[lógica-gatilho] `b·m ≤ W` é decorativa** — *partial/minor.* Três variáveis sem valor nem método;
   paper auto-declarado não-verificado. Verificador: a desigualdade é decorativa, mas CA2 já não depende
   dela — verifica o observável ("lê k resumos, não N brutos"). Rebaixar a heurística.

3. **[lógica-gatilho] CA2 afirma verificação por grep do que grep não detecta** — *confirmed/minor.*
   "agente que dispara orquestração" é semântico (prosa), não padrão sintático. String literal `worker-orchestrator`
   é grep-able e hoje só aparece como referência-proibição (`metaspec-gate-keeper.md:187`,
   `agent-orchestration.md:478`).

4. **[nomenclatura] "Nó sumarizador" é cunhagem, não termo de mercado** — *partial/minor.* Viola regra
   ubíqua; equivalentes: `agent-orchestration-landscape-2026.md:32,44,51` (orchestrator-worker/supervisor).
   Verificador: `summarizer` dá ZERO nas fontes cross-source; o equivalente interno mais fiel é "agente de
   síntese". Partial porque o ADR já flagra o risco e difere a promoção.

5. **[tensão-KB] Doutrina "vigente" não existe no texto que o leitor consome** — *confirmed/minor.*
   KB/SKILL só registram a armadilha de locus; eixo "forma do grafo" ausente. Fix: frase-âncora mínima na
   KB, ou rebaixar "vigente" a "aceita-mas-não-publicada".

6. **[tensão-KB] Metadados: accepted + RASCUNHO + adr-draft + filename -draft-** — *confirmed/minor.*
   Internamente coerente em status, mas title/type/filename dizem draft. 4 refs cruzadas a verificar antes
   de renomear (math-phase-transition :12,64,118; external-radar :111,166).

7. **[coerência] Distinção locus×forma é sólida; W/m fortalece (não mina)** — *confirmed/nit.* Aceitar não
   introduz padrão de uso; mantém default plano. Fix opcional: frase anti-objeção na Decisão.

8. **[coerência] Tensão nesting-5-níveis vs "orquestração no topo"** — *partial/nit.* A Parte 2 cita nesting
   de subagentes ao lado de `parallel` aninhado; são categorias diferentes. Verificador: a Decisão já
   amarra a árvore legítima a "composto no nível principal"; só o parágrafo de Contexto mistura — melhoria
   editorial. Fix aplicado (separar (a)/(b)).

9. **[coerência] Citação interna divergente: corpo :204, Referências :203** — *confirmed/nit.* Mesma âncora,
   dois números. Fix aplicado.

10. **[coerência] `b·m≤W` como "tradução do paper" enquanto desautoriza o paper** — *partial/nit.* Não é
    circular (orquestrador-JS × agente-LLM são nós distintos), mas o fraseado herda fragilidade epistêmica.
    Reancorar em primeiros princípios. Fix aplicado.

11. **[âncoras] Drift :203→:204 na seção Referências** — *confirmed/nit.* (mesmo que #9, lente âncoras).
    Verificado: architecture.md:204 = regra correta; :203 = `agents/*→utils/*` (errada). Fix aplicado.

12. **[âncoras] Range :247-248 inclui linha em branco** — *partial/nit.* Conteúdo "0 token" está só na 248.
    Verificador: correto, mas o achado erra a própria contagem de ocorrências; cosmético, baixíssima prioridade.

13. **[lógica-gatilho] Gatilho "JS não basta" não-operacionalizável (sem rúbrica/juiz)** — *partial/nit.*
    Verificador: tese forte refutada — CA1 É o checklist binário, CA2 traz threshold, CA3 nomeia o validador;
    o que falta de fato é *quem aprova a exceção* (não escrito). Risco prático baixo (padrão diferido).

14. **[nomenclatura] sumarizador (intermediário) × sintetizador (final): dois rótulos** — *partial/nit.*
    Verificador: distinção real e o código já separa `summarizeGroup` × `synthesize`; gravidade
    superdimensionada. Polimento útil, não defeito.

15. **[nomenclatura] Mitigação "nomenclatura" é circular** — *partial/nit.* Verificador: a escolha lexical
    concreta já está na Alternativa C (:150-151) e no Gatilho de Implementação (:174-176); a palavra
    "nomenclatura" na seção Negativas é ponteiro abreviado. Micro-melhoria de cross-referência.

16. **[tensão-KB] Premissa "leitor lê hierarquia=proibida" é exagerada** — *confirmed/nit.* A KB sequer usa
    "hierarquia"/"árvore" nesse sentido (`grep` = 0); fala só de locus. Risco é por omissão. Fix aplicado
    ("O gap" reframado).

---

## 3. Disposição

- **Aplicados ao ADR (camadas 1-2):** #1-#3, #7-#11, #16 (citação, CA2/CA3, b·m≤W, "O gap" omissão,
  mecanismo (a)/(b), frase anti-objeção).
- **Diferidos à promoção (camada 3):** #4 (ancorar nomenclatura), #5 (frase-âncora na KB), #6 (promoção
  draft→adr + 4 refs), #14/#15 (polimento de nomenclatura) — registrados no histórico de revisão do ADR.
- **Sem ação (verificador refutou a gravidade):** #12 (cosmético), #13 (CA1-CA3 já cobrem; só falta nomear
  o aprovador da exceção — opcional na promoção).

---

**Mantido por:** Sistema Onion · **Run:** `wf_e7ae4944-674` (2026-06-22)
