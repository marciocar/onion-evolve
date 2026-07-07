# Semente de pesquisa — VSCode/outra IDE, revisitado × o abandono formal de 2026-05-18

> **Status: SEMENTE (2026-07-06)** — plantada pelo maestro numa rodada de sementes especulativas
> ("de forma independente, sem julgamento"). ⚠️ **Esta semente colide de frente com uma decisão
> formal, repetidamente citada como definitiva até 2026-07.** Registrar isso não é fechar a
> pergunta — é o mínimo que a doutrina `declarado≠verificado` exige antes de reabrir qualquer
> coisa.

## Por que esta pesquisa

O maestro pergunta: podemos ir para dentro do VSCode ou outra IDE, com eficiência e eficácia?

**Multi-IDE foi abandonado formalmente em 2026-05-18** — e não como decisão esquecida: é citada
como definitiva em praticamente toda a doutrina de identidade lida até hoje (2026-07-06):

- `docs/analysis/onion-review-2026-05.md` (a própria origem): *"Abandono do `.onion/` — a proposta
  de diretório agnóstico para portabilidade entre IDEs não será mais perseguida; o Onion permanece
  em `.claude/`."* Tabela explícita: *"Suporte multi-IDE (Cursor, Continue, Cline) → Abandonada →
  Aceitar Claude Code como plataforma única."*
- `docs/knowledge-base/meta/onion-framework-identity.md` §7 (o que o Onion NÃO é): *"Multi-IDE
  (Cursor, Zed, Windsurf) → Dilui integração; Claude Code é a plataforma certa."*
- `docs/meta-specs/architecture.md` §5: *"Sistema Onion roda exclusivamente em Claude Code [...]
  Não há suporte planejado para Cursor, Continue, Cline ou outras CLIs."*
- `docs/materials/press-kit.md`, no FAQ, a formulação mais direta: *"A aposta é profundidade de
  integração com o Claude Code, não portabilidade entre IDEs [...] diluiria a integração que é o
  diferencial."*
- O próprio artigo crítico interno do Onion já nomeia o risco sem resolver:
  `docs/materials/critical-article-outline.md` §3 — *"Não há plano B de portabilidade — foi
  explicitamente removido [...] a viabilidade do Onion está atada às decisões de roadmap, preço e
  disponibilidade do Claude Code/Anthropic."* E `onion-review-2026-05.md` nomeia isso como "Risco
  8 — Drift de plataforma", com mitigação marcada **fora do escopo** daquela análise.

Um resíduo textual do abandono ainda foi encontrado tão tarde quanto 2026-06-16
(`onion-evolution-2026-06-16.md`, achado D6: *"agent-skills-specialist.md:103 resíduo multi-IDE
[...] — abandonado em 2026-05-18"*), confirmando que a decisão continuou sendo ativamente
enforced, não apenas registrada e esquecida.

**Isso não significa que a pergunta esteja fechada** — significa que qualquer resposta séria
precisa dizer explicitamente *o que é diferente agora* comparado a maio de 2026, porque a razão
dada foi "diluiria o diferencial", não "é tecnicamente impossível".

**Retrofit 2026-07-06** — [`onion-parecer-rejection-vs-spinoff-signal-2026-07.md`](onion-parecer-rejection-vs-spinoff-signal-2026-07.md)
nomeou `bifurcado` pra exatamente a leitura que a Q2 abaixo já cogitava: talvez isto não seja
"reabrir o abandono de 2026-05-18", e sim reconhecer que o onion-mini/família multi-plataforma já
é a resposta *bifurcada* — o lugar certo pra essa necessidade, fora do core. Se for essa leitura,
não há decisão a reabrir, só um apontamento a fazer.

## Questões de pesquisa

**Q1 — O que mudou desde 2026-05-18 que poderia mudar o cálculo?** A decisão foi tomada num
momento específico, com um argumento específico (profundidade > portabilidade). A pergunta não é
"multi-IDE é bom ou mau" — é: o cenário de custo/benefício que gerou aquela decisão ainda é o
mesmo? (Ex.: Claude Code ganhou/perdeu capacidades desde então? Outras IDEs ganharam suporte a
protocolos que reduziriam o custo de portar, como MCP ou algo equivalente ao `AGENTS.md` que o
próprio onion-mini já usa como "caminho rápido" universal?)

**Q2 — "Ir para dentro do VSCode" é a mesma pergunta que "multi-IDE", ou é outra?** O abandono de
2026-05-18 foi sobre o **core** oferecer suporte nativo a múltiplas IDEs (Cursor, Continue,
Cline). Mas o onion-mini já resolve uma versão adjacente dessa pergunta — ele roda em qualquer
lugar que leia `AGENTS.md`, incluindo VSCode com extensões agênticas, **sem que o core precise
mudar nada**. A pergunta do maestro é sobre o core native (reabrir o que foi fechado) ou sobre
"como o onion-mini/família multi-plataforma já cobre isso" (não reabre nada, só aponta pro que já
existe)?

**Q3 — "Com eficiência e eficácia" é o critério que faltou em 2025-12.** A razão de abandono foi
qualitativa ("dilui o diferencial"), não um teste real de eficiência. Se o maestro tem em mente um
jeito específico de fazer isso ser eficiente (não replicar tudo, aproveitar `AGENTS.md`/onion-mini
como ponte), essa proposta concreta é o que faltaria pra reabrir com evidência nova — não uma
reafirmação genérica de "seria bom ter multi-IDE".

## Método previsto

Não é pesquisa externa ampla — é primeiro uma conversa de esclarecimento com o maestro sobre Q2
(que pergunta é essa, de fato), porque as duas leituras têm respostas completamente diferentes:
se for "aproveitar o que o onion-mini já faz", não há pesquisa nenhuma a fazer — é comunicação
("já está resolvido, veja o `AGENTS.md`"). Se for "reabrir suporte nativo no core", precisa de uma
proposta escrita que confronte diretamente o argumento de 2026-05-18 (Q1) antes de qualquer
pesquisa técnica de viabilidade.

## Gatilho

O maestro pede ("vamos revisitar multi-IDE") → executar a partir DESTA semente, começando por
Q2 (esclarecer qual pergunta é essa). Registro na memória da sessão:
`sementes-modelo-federacao-lente-radar-2026-07` (ponteiro consolidado).
