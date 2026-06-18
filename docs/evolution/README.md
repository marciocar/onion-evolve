# 🔄 Co-evolução Onion — modelo operacional (canônico)

> **Autoridade:** este diretório é a **fonte canônica** do protocolo de co-evolução entre o **Onion core**
> (`onion-evolve`) e os **projetos que o adotam** (derivados, ex. `rhilo-metagamify`). Projetos
> **referenciam/respondem**; não redefinem. Mantido pela sala de design do core.

## O problema

O Onion (framework) evolui; **muitos projetos** o adotam. Sem método, duas dores aparecem:

1. **Instâncias de IA colidem** — duas sessões mexendo no mesmo repo geram trabalho duplicado e pontes meio-construídas.
2. **O sinal do campo não volta** — bugs e pedidos dos projetos não chegam ao framework de forma rastreável.

## Princípios (estado da arte 2026)

- **Orquestração, não autonomia:** o humano (você) é o **maestro**; agentes rodam async, cada um no seu escopo. **Sem IA-fala-IA ao vivo** (A2A-runtime fica `hold` por critério de design).
- **Coordenação = git-async:** mensagens são **markdown commitado** (padrão *drop-box* / GitHub Squad). "Async dentro do repo escala melhor que tempo-real."
- **Um escritor por repo:** cada repo tem uma sessão dona; **git worktrees** para paralelismo no mesmo repo.
- **Eficiência > cerimônia:** o mínimo que destrava; maquinaria formal só quando se paga.

## Os 3 fluxos

### A. Core → projetos (downstream / distribuição)
*Quando o framework muda, os projetos descobrem e adotam com segurança.*
- **Registro:** [`federation/members.yaml`](federation/members.yaml) — quem adota o Onion e em que versão.
- **Pin de versão:** cada projeto carrega `.claude/.onion-version` (commit de origem).
- **Anúncio:** o core registra mudanças relevantes em [`federation/CHANGELOG.md`](federation/CHANGELOG.md).
- **Atualização no projeto:** `/meta:adopt --update` (deliberado, nunca link vivo).

### B. Projetos → core (upstream / sinal + pedido de ajuda) ← o loop de co-evolução
*Um projeto reporta bug, dá feedback, **pede ajuda/feature**, manda status.*
- **Canal:** [`inbox/`](inbox/) aqui no core. O projeto deposita um markdown datado (`AAAA-MM-DD-<assunto>.md`).
- **Exemplo real:** o bug do `.env.example` (dogfooding no metagamify) virou o fix `#89`. O 1º veredito do metagamify está em [`inbox/`](inbox/).

### C. Dentro de um repo (sessões paralelas)
*Duas sessões no mesmo repo não colidem.*
- **git worktrees** (isolamento) + **um escritor por escopo** + **handoff commitado** (cada sessão registra o que fez antes de sair).

## Seu ritual (maestro)

1. **Início de sessão:** `git fetch` + ler o `inbox/` do repo (e o do core, se for sessão de projeto).
2. **Projeto precisa de algo do core** → deposita mensagem no `inbox/` do core (fluxo B).
3. **Core mudou algo que afeta projetos** → registra no `CHANGELOG.md` (fluxo A); projetos puxam via `/meta:adopt --update`.
4. **Você roteia** entre os repos e decide a ordem de merge. **Uma sessão por repo**; se uma sessão cobrir outro repo (a ponta estava adormecida), **logue quem fez** no handoff e commit isolado.

## Ownership — de quem é a RFC?

- O **core (`onion-evolve`) é dono** do protocolo e da **série de RFCs** de co-evolução ([`rfc/`](rfc/)).
- Projetos **referenciam/respondem** — não mantêm série própria.
- A `rfc-0001` foi rascunhada no `metagamify` e **promovida aqui como canônica**; a cópia de lá vira referência.

## Fundamentação 2026 (por que assim)

| Decisão | Base (estado da arte) |
|---|---|
| Coordenação por arquivo commitado no repo | *drop-box* do GitHub Squad — async no repo escala melhor que tempo-real |
| Humano maestro, agentes async por escopo | "Coerência por orquestração, não autonomia" (consenso 2026) |
| A2A-runtime = `hold` | A2A v1.2 (Linux Foundation, prod) é p/ cross-org enterprise — pesado aqui |
| Registro + pin de versão | manifest-pinning (textbook); multi-repo custa 15–30% em coordenação |

Fontes: [GitHub Squad](https://github.blog/ai-and-ml/github-copilot/how-squad-runs-coordinated-ai-agents-inside-your-repository/) · [Orchestration not autonomy](https://mikemason.ca/writing/ai-coding-agents-jan-2026/) · [LF Agent2Agent](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents) · [Multi-repo coordination tax](https://medium.com/@kantmusk/the-20-coordination-tax-every-multi-repo-javascript-team-pays-in-2026-f58d1a6b85d3)

## Gatilho de graduação (quando ligar a Federação formal)

Hoje a coordenação é **leve**: registro + inbox + changelog. **Ligar contratos versionados + tests/fixtures + ciclo `publish/check`** (comandos `/meta:federation-*`, **já implementados**) quando:

- surgir um **contrato que pode quebrar** consumidores (ex.: mudança *breaking* no `/meta:adopt --update`); **ou**
- o nº de projetos tornar o roteamento manual custoso (a 15–30% de "coordination tax" começa a doer).

Até lá, o humano roteia e o doc-bridge basta.
