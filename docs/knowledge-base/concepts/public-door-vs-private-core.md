# Porta pública ≠ core privado — a fronteira entre onde a família se adota e onde ela evolui

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-19 | **Categoria**: Conceitos
> Doutrina de **topologia de repositórios** batizada em 2026-07-19 (investigação
> "rescue-adopters-core-vs-hub"): a verificação ao vivo revelou que a *porta pública Claude*
> (`onion-claude`) e o *core privado de evolução* (`onion-evolve`) eram o **mesmo repo privado**.
> É [`fonte ≠ derivação`](source-vs-derivation.md) aplicado a **repositórios de distribuição** —
> e irmã de [`declarado ≠ verificado`](../agentic-patterns/ai-strategies/verify-read-path-first.md)
> aplicada ao **próprio marketing público** da família.

---

## 1. O princípio

**Onde a família se ADOTA e onde ela EVOLUI são repositórios fisicamente separados.**

- **Core privado** (`onion-evolve`) — a **fonte** que evolui (push diário), Claude-Code-only,
  **não-distribuída** (`CLAUDE.md` §Identidade). Sua versão é a HEAD; não se carimba
  ([`onion-version.sh`](../../../.claude/validation/onion-version.sh)).
- **Porta pública** — a **derivação estável** que um adotante externo aponta e adota, sem precisar
  de acesso ao core. Para outras plataformas, a porta é um port real (Cursor/Codex/Copilot/Zed/
  Antigravity — primitivo nativo diferente); para Claude, a "porta" é a mais traiçoeira, porque o
  primitivo é o mesmo do core — o que **convida ao colapso** porta↔core.

**Litmus test:** *"um adotante que só tem a história pública consegue chegar a algo adotável e
estável?"* — se a resposta é "cai num repo privado" ou "cai num snapshot congelado", a fronteira
colapsou.

## 2. O modo de falha que a batizou (evidência)

Verificado ao vivo via `gh` em 2026-07-19:

| Repo | Visibilidade | Último push | Papel real |
|---|---|---|---|
| `onion-evolve` (≡ redirect de `onion-claude`) | 🔒 **PRIVATE** | diário | core vivo — a fonte |
| `onion` (hub) | 🌐 public | **congelado 2026-06-04** | meta/história das 6 portas |
| `onion-cursor/codex/copilot/zed/antigravity` | 🌐 public | congelados 2026-06-04 | 5 destilações públicas |
| `onion-mini` | 🌐 public | 2026-07-06 | destilação de entrada |

**Dois colapsos simultâneos:**
1. **Porta↔core:** `onion-claude` (a porta pública anunciada pelo hub) **foi renomeada e virou** o
   core privado `onion-evolve`. Cold-adopter que segue o hub → clica na "porta Claude" → **repo
   privado** (sem acesso). A porta pública Claude, na prática, **não existe**.
2. **Vitrine congelada:** o hub e as 5 portas de plataforma foram empurrados **uma vez** (04-06) e
   nunca mais. O rosto público da família descreve um estado de 6 semanas atrás — `declarado ≠
   verificado` aplicado ao marketing.

> Sutileza que o próprio hub admite (README, congelado): *"Não é 'o Onion do Claude' (essa é a
> porta onion-claude); o `.claude/` aqui é apenas tooling."* — a doutrina **já estava escrita**;
> só a topologia real a contradizia.

## 3. A regra (o que a fronteira exige)

1. **A fonte pode ser privada; a porta, não.** Adoção externa **nunca** deve depender de acesso ao
   core. Se o core é privado por design, a porta pública é **obrigatória** (ou a família assume, por
   escrito, que só há adoção assistida via [`/meta:adopt`](../../../.claude/commands/meta/adopt.md)
   — o que é uma decisão, não um acidente).
2. **A porta é derivação — cita/deriva, não é a fonte.** Um port público (destilação/espelho) segue
   [`fonte ≠ derivação`](source-vs-derivation.md): "uma só fonte". Publicar uma porta **não** é
   distribuir o core; é publicar uma **derivação** dele (como as 5 outras plataformas já são).
3. **Vitrine viva ou datada, nunca silenciosamente stale.** Se a face pública não sincroniza com a
   fonte, ela **declara** seu recorte ("snapshot de AAAA-MM-DD"); senão mente por omissão.
4. **Adotante ancorado na fonte viva ≠ adotante preso.** Quem tem acesso e vendoriza `.claude/` do
   core vivo (adotantes ancorados na fonte viva) está **correto por design** — não confundir "vendoriza
   do core" com "preso a um fork de incubação". O problema é **só** do cold-adopter externo
   (thread `Q_COLD_ADOPTER`, aberto em `members.yaml`).

## 4. Relação com as irmãs

| Doutrina | Trata de | O colapso que evita |
|---|---|---|
| [`fonte ≠ derivação`](source-vs-derivation.md) | **conhecimento** (fonte vs nossa leitura) | derivação reescreve a fonte → duas fontes divergem |
| [`declarado ≠ verificado`](../agentic-patterns/ai-strategies/verify-read-path-first.md) | **estado** (stamp/doc vs artefato vivo) | confiar no carimbo em vez de verificar o vivo |
| **porta ≠ core** (esta) | **topologia de repos** (adoção vs evolução) | porta pública e core privado colapsam num repo só |

## 5. Os tipos de repo da família (aplicação da doutrina ao split)

Quando o core é selado e a família vira um **ecossistema de repos**, a fronteira porta≠core se aplica
**por tipo**. O recorte não é "uma fatia do SSOT" (isso criaria segunda fonte, vetada por
[RFC-0004](../../evolution/rfc/rfc-0004-a2a-live-interop.md) single-source + `fonte≠derivação`) — é
**derivação que cita**, keyed ao tipo. Ratificado em
[ADR family-repo-topology](../../analysis/onion-adr-family-repo-topology-2026-07.md).

| Tipo | Repos | O que da doutrina viaja | Mecanismo |
|---|---|---|---|
| **Porta de framework** | `onion-standalone` ≡ `onion-claude` | recorte **operacional**: KBs dos verticais do bundle `standalone` (eng/product/testing/docs), com proveniência (`tree_sha`/pin) que **cita** o core. **Nunca**: meta-factory, KBs de auto-análise, memória privada, `.kg.yaml` | `/meta:adopt` role-scoped + `--update` |
| **Meta/vitrine** | `onion-hub` | a **narrativa** (derivação da identity KB) | adopt-tooling + autoral |
| **Destilação curada** | `onion-mini`, `onion-personal` | doutrina **reescrita** (essência), não KBs verbatim; nunca vendoriza `.claude/` | co-evolução curada |
| **App de runtime** | `onion-bridge`, `onion-site`, `onion-app`, `onion-personal-app` | **zero** doutrina — janela sobre um SSOT ao vivo (framework vs cérebro pessoal) / deploy puro | split como repo-fonte |

**Os KGs são soberanos por repo.** Os `.kg.yaml` do core (investigações/domínio) são privados e **não
viajam** (só destilado circula). Um door que investigue gera os **seus** `.kg.yaml` locais — estado dele,
não fatia do core. **Litmus:** doutrina editada em **um** lugar (core); cada repo é projeção que cita e se
refresca; KG de cada um fica no seu repo.

## 6. Relações

- Topologia de repos da família (ratifica os tipos): [`onion-adr-family-repo-topology-2026-07`](../../analysis/onion-adr-family-repo-topology-2026-07.md)
- ADR que decide o destino da porta Claude: [`onion-adr-claude-door-topology-2026-07`](../../analysis/onion-adr-claude-door-topology-2026-07.md)
- Fonte da tese: [`source-vs-derivation.md`](source-vs-derivation.md) · registro: [`members.yaml`](../../evolution/federation/members.yaml)
- Distribuição/destilação: [`onion-adr-mini-distillation-2026-07`](../../analysis/onion-adr-mini-distillation-2026-07.md) · [`onion-distribution-strategy-2026-06`](../../analysis/onion-distribution-strategy-2026-06.md)
