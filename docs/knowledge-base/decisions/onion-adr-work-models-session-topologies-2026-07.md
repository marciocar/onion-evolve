# ADR — Modelos de trabalho: topologias de sessão da federação Onion

> **Status:** ACEITO (2026-07-02) · **Tipo:** decisão durável (permanece em `docs/analysis/` como ADR)
> **Decisor:** maestro (checkpoint 2026-07-02, 2 decisões confirmadas à luz de pesquisa fundamentada)
> **Insumos:** pesquisa deep-research (core-only) (24 claims verificados 3-votos) ·
> [ADR comms-transport-vs-execution](onion-adr-comms-transport-vs-execution-2026-06.md) (os 3 atos) ·
> [KB federation-usage-modes](../../knowledge-base/concepts/federation-usage-modes.md) (eixos A-D)
> **Contexto:** reconstrução do planejamento "modelos de trabalho" — de onde se trabalha em quê, entre
> source e adotados — perdido em sessão de outro notebook; fragmentos existiam em 5 artefatos sem nome de eixo.

## 1. Decisão central — o Eixo E (topologia de sessão; valores W1-W7)

Fica instituído o **Eixo E — modelo de trabalho/sessão** (valores W1-W7), complementar aos eixos A-D da
[KB federation-usage-modes](../../knowledge-base/concepts/federation-usage-modes.md). Ele responde **"quem
trabalha onde, a partir de onde"** — pergunta que os outros eixos não respondem (A/B = momento da adoção;
C = posição na rede; D = cada comando).

| W | Topologia | O que é | Status | Doutrina de origem |
|---|-----------|---------|--------|--------------------|
| **W1** | **Source-driven por path** | A sessão do core opera o alvo **por path**, sem sessão lá. Subcasos: (i) fases por-path do `/meta:adopt` (cópia/carimbo); (ii) `--in-place` (additional working dir, efêmero); (iii) **cobertura de ponta adormecida** — commit isolado no repo coberto + log de quem fez | 🟢 | `adopt.md` §Transição de Contexto · `docs/evolution/README.md` (ritual §4) |
| **W2** | **Sessão do alvo** (canônico) | Cada repo tem sua sessão dona ("um escritor por repo", I3). O core **indica**, nunca executa no alvo; a Fase 4 do adopt e toda a vida da instância rodam **lá** | 🟢 | I3 (RFC-0001) · `adopt.md:375` |
| **W3** | **Duas sessões, mesmo repo** | Concorrência intra-repo. Duas formas: (i) **handoff por worktree** (um escritor por escopo, handoff commitado); (ii) **sala de design / sala de obra** (partição por função: decisão vs implementação; "uma instância por arquivo por vez") | 🟢 | fluxo handoff (RFC-0001) · `onion-repositioning-sdaal-session-2026-06-17.md` |
| **W4** | **Par local (1 máquina)** | Duas sessões, dois repos, mesmo filesystem — carteiro-local automatiza transporte+notificação (`co-deliver`/`co-relay`, entrega-sem-commit) | 🟢 | ADR ledger §3.3 · comandos co-deliver/co-relay |
| **W5** | **Membro remoto** | Sessões em máquinas distintas — sem carteiro-local; git-async mediado pelo maestro (`local_path` ausente desliga os atalhos, não muda o tier) | 🟢 | `onboarding-remote-member.md` |
| **W6** | **Responder-gated** | A sessão do destino, ao ver 📬/📥/⏰ no boot, **propõe o rascunho** de resposta/triagem no canal certo; o maestro **confirma num gesto**. Atos 1-2 automáticos; o ato 3 vira *propor→confirmar* (nunca auto-executar) | 🟢 **decidido agora** (ver §2) | ADR comms `:99` + pesquisa (padrão Squad) |
| **W7** | **Sessão agendada (cron/daemon)** | Agente acorda sozinho por relógio/evento e age | 🔴 **rejeitado como base** (ver §3) — o equivalente soberano é o trigger *lazy por sessão* (hooks), já em W6 | pesquisa (achados 1, 3, 4, 9) |

As topologias **compõem**: um par W4 pode ter W3 dentro de cada repo; W6 opera sobre W2/W4/W5.

## 2. Decisão — W6 responder-gated é o modelo (c)

O "um responder ao outro" fica instituído como **responder-gated**: o `/meta:co-evolve` ganha o passo
**"propor rascunho"** — havendo mensagem pendente, a sessão redige a resposta/triagem como rascunho no
canal correto (core: veredito de triagem + esboço de anúncio; consumidor: processamento + esboço de sinal
upstream) e **para**, aguardando a confirmação do maestro antes de mover/entregar qualquer coisa.

**Fundamentação (pesquisa):** o caso documentado mais completo (Squad) é explicitamente *"collaborative
orchestration, not autonomous execution"* — guardrails por **hook determinístico** ("prompts can be
ignored; hooks are code") + revisão humana em todo merge. Vendors provam o contra-caso: autonomia é o
default e o HITL é exceção opt-in (Jules `requirePlanApproval`) ou post-hoc (routines sem permission-mode).

**Invariantes preservadas:** I3 (rascunho nasce no repo da sessão que propõe, ou entrega-sem-commit);
ato 3 humano; git-async. Ideia transplantável registrada para o futuro: **gate git-nativo por prefixo de
branch** (push restrito + branch protection) se um dia houver automação que commite.

## 3. Decisão — W7 (cron) rejeitado como base; lazy-por-sessão é o padrão soberano

Sessão agendada vendor exige **serviço vivo** e **autonomia durante a run** (routines: cloud-only, sem
prompts de aprovação; HITL só post-hoc) — incompatível com o fluxo soberano sempre-gated. A pesquisa
valida o substituto que o Onion já pratica: **cadência lazy acionada por sessão** — a consolidação/aviso
acontece quando (e só quando) o humano abre sessão (hooks SessionStart/End; caso claude-memory-compiler).

**Gatilho de reabertura** (não fechar a porta para sempre): W7 só volta à mesa se surgir necessidade
nomeada que o lazy-por-sessão comprovadamente não cobre (ex.: SLA de resposta entre membros remotos) — e,
mesmo então, na forma *rascunho-only* (agente agendado que só produz propostas, nunca executa).

## 4. Decisão — gatilho invariável de reflexão = ⏰ + protocolo de re-teste

Fica instituído como **invariante do ciclo de aprendizado**:

1. **Sinal (atos 1-2, automático):** o hook `co-evolution-inbox-check.sh` conta migalhas do diário com
   `review_after` vencido e emite **⏰** no boot (implementado 2026-07-02; guardas no lint-selftest modo
   `mail-hook`). Sem daemon — lazy por sessão.
2. **Re-teste (ato 3, humano):** migalha vencida é **RE-TESTADA contra evidência atual**, nunca
   re-carimbada às cegas — protocolo `review` no `/meta:diary`: válida → novo `review_after`; inválida →
   marcada `superseded` (nunca apagada — história); parcial → reescrita. Confirmação do maestro sempre.

**Fundamentação:** risco nº1 documentado da auto-melhoria é a **reflexão falsa persistida** (erro
auto-reforçante, "can be catastrophic"); e o gargalo da memória é a **absorção** (recall ativo 40-60%),
mitigada por consolidação estruturada — o re-teste é o quality-gate que a literatura descreve como
necessário e subdesenvolvido. O Onion o institui com gate humano.

## 5. Roadmap de enablers (cada um com gatilho — eficiência > cerimônia)

| Enabler | Estado | Gatilho para construir/ativar |
|---|---|---|
| ⏰ reflexão no hook | 🟢 feito (2026-07-02) | — |
| W6 responder-gated no `/meta:co-evolve` + protocolo `review` no `/meta:diary` | 🟢 nesta entrega | — |
| Consolidação estruturada do diário (estágios, estilo REMIND) | 🔒 | volume: diário com 30+ migalhas ativas OU F4 (synthesize-collective) abrir |
| Gate git-nativo por prefixo de branch p/ automação que commita | 🔒 | 1ª automação que produz commits sem humano na sessão |
| W7 rascunho-only agendado | 🔒 | necessidade nomeada que lazy-por-sessão não cobre (ex.: SLA entre membros remotos) |
| Carteiro distribuído (entre máquinas) | 🔒 (já no ADR ledger) | gatilho de graduação da federação |

## 6. Consequências

- KB `federation-usage-modes` ganha o **Eixo E** e a matriz passa a cruzar tier × topologia.
- `co-evolve.md` e `diary.md` ganham os passos de W6/re-teste (vendorizados → chegam aos adotantes via `--update`).
- A RFC-0003 §5 ganha resposta implícita para "trigger da síntese coletiva": **on-demand/lazy-por-sessão**
  (cron rejeitado como base) — a registrar na próxima revisão da RFC.
- O Onion está **à frente da literatura** no recorte drop-box cross-repo (nenhuma fonte mediu) — o
  trust-log + CHANGELOG + diário nos posicionam para publicar o post-mortem que falta (oportunidade, não compromisso).

## 7. Adendo 2026-07-02 (mesmo dia, campo) — colisão W1×W2 e o FAROL DE SESSÃO

**Incidente:** horas depois deste ADR, a primeira operação W1 real (sessão do core operando o rhilo
por path para o `--update` + processamento co-evolução) fez `git checkout` na working tree do alvo
**enquanto uma sessão W2 estava viva lá** (auditoria WRR em `audit/oraculo-integration`). Nada se
perdeu (a sessão do alvo protegeu o próprio trabalho), mas ficou provado: **I3 ("um escritor por
repo") inclui SESSÕES VIVAS, não só commits** — checar `git status` limpo não basta; a branch corrente
é contexto de quem está trabalhando, e checkout alheio é interferência mesmo sem perder bytes.

**Decisão — farol de sessão (session beacon), sinal e não trava:**

1. **Mecanismo** (`.claude/validation/session-beacon.sh` + hook `session-beacon-hook.sh`): cada sessão
   **acende** um farol no boot (`SessionStart`), **refresca** a cada prompt (`UserPromptSubmit`) e
   **apaga** no fim (`SessionEnd`). Beacons vivem em `.claude/beacons/` e são **git-invisíveis**
   (`.git/info/exclude` local ao clone — runtime state, nunca commitado).
2. **Detecção de colisão no boot:** se ao acender há OUTRO farol fresco no repo, o hook avisa
   🕯️ com branch/hat/idade — a topologia W3 (duas sessões no mesmo repo) deixa de ser invisível.
3. **Disciplina W1 (cross-repo):** antes de checkout/escrita na working tree de repo alheio, rodar
   `session-beacon.sh check <repo>` — exit 1 (farol vivo) = **parar e coordenar com o maestro**.
   Entrega em `inbound/` (untracked, sem checkout) segue segura e dispensa o check.
4. **Sinal, não trava:** farol stale (> `ONION_BEACON_TTL_MIN`, default 480min) é listado mas não
   bloqueia — sessão morta sem cleanup não pode travar o repo; `sweep` limpa. O gate é humano (I3 +
   ato 3), o farol só dá o dado que faltava.
5. **Dupla serventia:** o mesmo farol responde à demanda de visibilidade do maestro ("você parece ser
   muitos") — `check` em cada repo = mapa de quem está onde, com chapéu e idade.

Guardas: lint-selftest modo `session-beacon` (7 casos, incl. regressão da colisão). Diário:
`2026-07-02-live-session-collision-farol.md`. Chega aos adotantes vendorizado no próximo `--update`
(hook registrado via merge idempotente do settings.json).

---

## Adendo (2026-07-10) — localização/nomenclatura de worktree DECIDIDA (convenção umbrella)

O comportamento de W3 (um escritor por escopo, handoff commitado) sempre foi doutrina; a **localização**
dos worktrees duráveis do maestro era ad-hoc (`~/<nome>-atual` no manual, sem regra). Codificado em
`worktree-convention-2026.md` (core-only): layout umbrella
**`~/worktrees/<repo>/<branch-slug>/`** (crédito: prática de campo de um adotante; padrão de mercado
gwq para fluxos paralelos com agentes IA). Efêmeros tool-managed (vendor-branch/mktemp, adopt legacy,
`Workflow isolation`, `.claude/worktrees/` do harness) ficam fora — continuam gerenciados por quem os
cria. Caveat registrado na convenção: o farol de sessão é por working-tree — worktrees irmãs não se
veem via beacon; o handoff entre elas confia na convenção + commit (slice futuro anotado).
