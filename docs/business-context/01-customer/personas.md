# Personas

**Última Atualização:** 2026-07-19

Personas em **camadas** — do usuário provado hoje (N=1) ao aspiracional (`[hipótese]`). Cada uma tem nota de interação com IA.

---

## P1 — Maestro N=1 (você / criador) — **provada**

- **Papel:** criador, único operador, dogfooder do core.
- **Objetivo:** entregar como um time sendo um só — qualidade + automação no ciclo produto/engenharia/compliance sem headcount.
- **Dor:** delegation gap — usa IA em ~60% do trabalho mas só delega 0–20% com confiança; contexto de decisão se perde entre sessões/repos ([Anthropic 2026](https://agentmarketcap.ai/blog/2026/04/05/anthropic-agentic-coding-trends-report-claude-code-eight-shifts)).
- **Contexto tech:** altíssimo — orquestra subagentes, federação multi-repo, escreve as próprias doutrinas.
- **Nota IA:** pt-BR, denso, sem hand-holding; trata veredito de agente como hipótese a verificar; espera pesquisa citada antes de posição em temas amplos.

## P2 — Adotante da família — **provada (campo)**

- **Papel:** projeto que instalou o Onion (metagamify, granaai, gustavo-pulga, arandek).
- **Objetivo:** herdar o método maduro do core sem reinventar; co-evoluir via federação.
- **Dor:** manter consistência com o core enquanto evolui local; receber melhorias sem quebrar.
- **Contexto tech:** alto — opera GitFlow, sessions, adapters.
- **Nota IA:** respeitar soberania do dado local (federação ≠ perder autonomia); doc-bridge entrega-sem-commit.

## P3 — Empresa com sistemas internos — `[hipótese]` (`D6`)

- **Papel:** time/org que quer padronizar dev-com-IA nos sistemas internos.
- **Objetivo:** consistência e escala entre squads; reduzir retrabalho e onboarding.
- **Dor:** cada dev usa IA de um jeito; nenhuma trilha; contexto não escala (16–30% de ganho só no quintil que reformula processo — [InfoQ](https://www.infoq.com/articles/enterprise-spec-driven-development/)).
- **Nota IA:** falar em ROI/consistência, não em features; comprador org (procurement, mudança).

## P4 — Time regulado / enterprise — `[hipótese]` (cunha de maior valor)

- **Papel:** setor regulado (farma, financeiro) adotando IA no loop de dev.
- **Objetivo:** adotar IA sem estourar risco regulatório — trilha de auditoria.
- **Dor:** shadow AI (82% das empresas têm agentes que a segurança desconhece); riscos FINRA de autonomia / scope creep / auditabilidade ([Zylos 2026](https://zylos.ai/research/2026-05-01-ai-agent-governance-compliance-2026/)). **Nenhum concorrente SDD cobre isso.**
- **Nota IA:** ênfase em governança/rastreabilidade; conservador; evidência e trilha acima de velocidade.

## P5 — Dev solo / maestro N=1 externo — `[hipótese]`

- **Papel:** desenvolvedor individual (a linha do dev solo, na plataforma Claude Code).
- **Tier / entrada `[reframe 2026-07-19]`:** o **standalone** — ferramenta COMPLETA, **grátis**, sem federação.
  Entra pela porta pública **`onion-standalone`** (aberta 2026-07-19; antes só adoção assistida via core privado).
- **Objetivo:** produtividade pessoal com estrutura.
- **Dor:** Claude Code puro não dá continuidade nem papéis; vibe coding gera drift.
- **Nota IA:** onboarding facilitado; o "aha" tem que ser rápido e no repo dele.
- **Conversão:** P5 **não** é meta de receita em volume (é MOAT/advocacy). Vira **hub** (empresa) quando chega o
  MULTI (2ª pessoa/repo) — aí sim o alvo de receita (P3/P4). O tom da porta pública precisa falar com ele
  (dev solo descobrindo sozinho), não o tom denso "do core" — ver `messaging-framework.md` (brand voice, stub).

## P6 — Leigo final / Onion Pessoal — `[hipótese — maior incerteza]` (`D3`)

- **Papel:** pessoa não-técnica; "cérebro pessoal" (Company Brain N=1).
- **Objetivo:** organizar a própria vida/decisões como o Onion organiza um projeto.
- **Dor:** complexidade — hoje o Onion é técnico demais para esse público.
- **Nota IA:** muda promessa e linguagem inteiras; **depende de branding/storytelling/posicionamento** (`@branding-positioning-specialist`, `@storytelling-business-specialist`). Não comprometer sem esse trabalho. Ligado a `discuss/onion-pessoal-marcio`.

## P7 — Contribuidor do core — **provada**

- **Papel:** quem evolui o framework (RFCs, `/meta:*`, federação).
- **Objetivo:** evoluir o método com disciplina (dogfood, respeito à doutrina).
- **Nota IA:** citar inventário canônico; validar com `@metaspec-gate-keeper`; dogfood é o gate.

---

_§template: um adotante substitui P1–P7 pelas suas próprias personas de negócio; a camada é o padrão, não o conteúdo._
