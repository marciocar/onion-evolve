# Síntese — Padrões de autonomia de agentes (2026) para o runtime de condução de fios

> **Proveniência:** pesquisa web (2026-07) + fontes internas, para o contrato de autonomia do ADR
> `onion-adr-autonomous-thread-runtime-2026-07`. Este é o **`write(KG)`** da pesquisa (não morre no efêmero).
> Grafo audit co-locado: `./autonomous-thread-runtime.kg.yaml` (radar exit 0, arestas `SUPERSEDES`).

## O que a web de 2026 diz (fontes)

1. **Autonomia é espectro graduado, não binário.** Modelo canônico **Audit → Assist → Automate**: Audit (IA
   executa, humano revisa tudo) → Assist (IA rotina, humano trata exceções) → Automate (IA ponta-a-ponta, humano
   monitora). **"Automate é um estado GANHO, ajustável"** — earned trust: permissões estreitas, limites modestos,
   caminho rápido para ganhar termos melhores por comportamento verificado.
   ([progressive autonomy](https://www.mindstudio.ai/blog/progressive-autonomy-ai-agents-safe-deployment) ·
   [HITL playbook 2026](https://ideaforgestudios.com/2026/07/17/human-in-the-loop-ai-agents-autonomy-playbook/))
2. **Merge é decidido por política DETERMINÍSTICA, nunca por probabilidade.** "Há diferença entre ajudar um PR a
   andar mais rápido e decidir se ele deve mergear. Sugestão de review pode ser probabilística; a decisão de merge
   NÃO. IA sugere e acelera; **política determinística decide e força**." GitHub Agentic Workflows rodam
   **read-only por padrão** + safe-outputs.
   ([deterministic guardrails](https://medium.com/@mvtavares/ai-can-speed-up-code-review-but-merge-decisions-still-need-deterministic-guardrails-c9d6ec9325e6))
3. **Humano mantém autoridade sobre a minoria arriscada/irreversível; a IA cuida da maioria rotineira.** HITL para
   o irreversível, HOTL/supervisão para o rotineiro — oversight por nível de risco no MESMO workflow.

## Como isso casa com o Onion (transfere) e onde diverge (desenha)

- **Transfere:** Audit/Assist/Automate ≈ os **3 atos** (transportar/notificar automatiza; executar gateia) + o
  **toolbox-lifecycle** (ASSESS→TRIAL→ADOPT) + `declarado≠verificado` (ganho por comportamento verificado).
  "Merge por política determinística" ≈ o gate mecânico do Onion (lint/selftest/radar) + a doutrina *"hooks são
  código, prompts se ignoram"*.
- **Desenha (o que o Onion adiciona):** o **moat inviolável** (repo-alheio/entregar-adotante/W7 NUNCA, além do
  irreversível) e a **path-allowlist vendor** (o que chega ao adotante é sempre AUDIT+) — mais estrito que a web,
  porque a federação expõe superfície downstream.

## A verificação adversarial (o adversário ganhou o dinheiro)

O contrato-rascunho foi refutado por um revisor `fable` (padrão de validação) — **10 furos**, 4 ALTA foram
**contradições internas**: (1) "own-repo docs-mostly" ≠ "não-outward-facing" (`.claude/`/`docs/knowledge-base`
são vendorizados); (2) "auto-merge own-repo" contradiz "não mergear no main" (repo só tem `main`); (3) a "política
determinística" continha 2 vereditos de LLM; (4) o enabler git-nativo já armado foi ignorado. + working-tree
própria (não só alheia), poda não é reversível/Nível-0, ADR deve nascer GATED, 3 guardas de parada ausentes.

**Resolução (o contrato pós-refutação):** AUTOMATE nasce **GATED** (3 pré-condições duras: enabler git-nativo +
path-allowlist mecânica + política 100% mecânica com LLM veto-only); a 1ª passada roda **só no AUDIT** (main
humano); worktree própria + beacon-check; 3 guardas de parada. Detalhe em
[`onion-adr-autonomous-thread-runtime-2026-07`](../../../analysis/onion-adr-autonomous-thread-runtime-2026-07.md).

## Confiança / gaps
- **Alta:** o modelo graduado + merge-determinístico é o consenso 2026 e casa com a doutrina Onion.
- **Média:** a classe AUTOMATE real deste repo é pequena (non-vendor) — a ser confirmada em campo.
- `declarado≠verificado`: o contrato só sela após o dogfood da Fase 2 (o ADR nasce `proposed-GATED`).
