---
status: snapshot
type: evolution-backlog
date: 2026-06-27
topic: "Como trabalhamos — método de trabalho como artefato de 1ª classe"
method: discovery (fan-out-and-synthesize, 5 lentes, frota onion-fleet/Workflow run wf_fe33d451-db3)
scope: read-only research — propõe, não muta (exceto este relatório)
---

# Pesquisa de evolução — Tópico 1: "Como trabalhamos"

> **Discovery, não execução.** Destila o *método de trabalho* do Onion (loop de dogfood, revisão
> adversarial, disciplina operacional, gestão de memória) e propõe **como o framework deve codificá-lo
> como artefato de 1ª classe** — não só praticá-lo implicitamente. Pedido do maestro de 2026-06-25.
> Frota de 5 lentes (read-only); síntese com **filtro crítico** (validação adversarial é insumo, não ordem).

## Sumário executivo (veredito)

**O achado é convergente e sólido: o método não está ausente — está FRAGMENTADO.** As 5 lentes,
independentes, chegaram ao mesmo diagnóstico: a doutrina de trabalho do Onion vive espalhada por
**6 lugares sem ponto de síntese**:

1. `~/.claude/rules/working-discipline.md` — regra global (disciplina do executor, multi-projeto)
2. memórias de feedback/projeto (`~/.claude/projects/<repo>/memory/*.md`)
3. `docs/knowledge-base/concepts/onion-dogfooding-doctrine.md` — KB canônica (dogfood)
4. `.claude/skills/onion-patterns/SKILL.md` — playbooks recognition-primed (RFC-0002, PR #164)
5. ADRs (`onion-adr-phased-resumable-pattern`, `onion-adr-comms-transport-vs-execution`)
6. `CLAUDE.md` §Dogfood — recall conciso

**O artefato de 1ª classe que falta é UM ponto de síntese navegável — uma KB integrada**
(`onion-working-method.md`) que articula as camadas do método e **aponta** (não duplica) as fontes.
**Não** são N meta-specs, comandos e guardas automáticas novas — várias propostas da frota nessa
direção são **over-engineering que contradiz a própria doutrina do Onion** (ver §Rejeitados).

## As 5 lentes (prática atual destilada)

| Lente | O que o método JÁ é | Onde vive hoje | Gap central |
|-------|---------------------|----------------|-------------|
| **Loop de dogfood** | Rodar o artefato de verdade; testar modo-de-falha (não happy-path); fix→re-dogfood no mesmo loop; gate mecânico determinístico (`.claude/validation/`) vs gate de uso (invocar e observar) | dogfooding-doctrine.md (canônico) + CLAUDE.md §Dogfood + CONTRIBUTING.md (checklist) | Sem protocolo de **captura** dos findings de modo-de-falha; fronteira gate-mecânico/gate-de-uso é só textual |
| **Revisão adversarial + fechar o loop** | Revisão independente com prompt neutro; veredito é **hipótese a verificar com evidência** (rejeitar falso-positivo); re-revisar o fix (regressão) | dogfooding-doctrine + working-discipline §Validação + metaspec-gate-keeper "REGRA ZERO" + fleet | Nunca nomeado como **unidade**; cada fan-out reinventa seu schema de veredito |
| **Disciplina operacional** | Git (PR-merged antes de deletar branch; add seletivo em repo com inbox); localização multi-repo (anunciar); rotular refs opacas; fan-out (detectar=dever, executar=opt-in) | working-discipline (global) + 4 memórias de feedback + prosa inline em comandos | Espalhada; "REGRA DE OURO" em `pr.md` é re-invenção local; sem porta de entrada única |
| **Gestão de memória** | Híbrido (feedback→silencioso+aviso; project→mostrar antes); recall automático; checagem leve de coerência; override do usuário | working-discipline §Memória + MEMORY.md (índice) + hooks de worklog | Diretiva sem mecanização; "silencioso/avisar" e "checagem de coerência" são tácitos |
| **Síntese (integradora)** | Seleção (catálogo/playbooks) + Execução (PFR faseado retomável) + Validação (dogfood) + Disciplina | fragmentado nos 5 acima; nenhum os articula | **Sem KB/ponto único** que mostre o método como sistema |

## O achado central — fragmentação, não ausência

O método do Onion é **maduro e praticado** (há doutrina canônica, regra global carregada toda sessão,
memórias, playbooks). O que falta é **coesão de 1ª classe**: um novato (ou um agente novo) não tem
**uma porta de entrada** que diga "é assim que o Onion decide e executa um trabalho". A fragmentação
gera os sintomas que as lentes acharam: re-invenção local (a "REGRA DE OURO" do `pr.md` redescobre o
add-seletivo genérico), schemas de veredito ad-hoc, e doutrina que só existe como prosa dispersa.

## Recomendação priorizada (régua P0-P3 do toolbox)

> Aplico a **régua de classificação do próprio Onion** (`onion/SKILL.md`, ADR toolbox-lifecycle):
> P0 script determinístico · P1 comando (juízo/quando) · P2 skill (recall) · P3 KB/doutrina.

### ✅ P3 — RECOMENDADO agora: KB integrada `docs/knowledge-base/concepts/onion-working-method.md`

O artefato de 1ª classe que falta. **Conhecimento, não lei** (KB, não meta-spec L0). Articula 3 camadas,
**citando** as fontes existentes (anti-duplicação — aponta, não copia):

- **Camada 1 — Seleção:** reconhecimento → playbook (catálogo-first, RFC-0002). Lista os 5-6 playbooks
  canônicos de `onion-patterns` como índice.
- **Camada 2 — Execução:** o Padrão Faseado Retomável (PFR) como esqueleto (sessão durável, `STATE.md`
  Tier-0, retomada fria/quente) — cita `onion-adr-phased-resumable-pattern` + `worklog-protocol.md`.
- **Camada 3 — Validação:** o loop de dogfood (gate mecânico + gate de uso) + a revisão adversarial
  (veredito-como-hipótese, fechar o loop) — cita `onion-dogfooding-doctrine.md`.
- **Transversal — Disciplina:** aponta `working-discipline.md` (global) como a fonte canônica do executor.

**Por que KB e não meta-spec:** o método é conhecimento operável (como navegar/decidir), não invariante
constitucional. Meta-spec L0 são contratos que o `@metaspec-gate-keeper` valida; o método é guia, não gate.

### 🟡 P1/P2 — backlog (gatilho já quase batido), não agora

- **Destilar os 5-6 playbooks em `onion-patterns`** como exemplos worked (não só prosa). Já decidido em
  RFC-0002; materialização parcial (~30-40%). A KB integrada cria a demanda concreta por eles.
- **`/meta:create-phased-command` (scaffolder PFR):** o PFR é invariante e **13+ comandos o usam**, mas
  novos nascem por cópia-à-mão (risco de deriva). Gatilho do ADR-PFR (≥2 scaffolds OU strategy-ADR) está
  perto. Promover quando a KB nomear o PFR e o próximo comando faseado surgir.

### ❌ REJEITADOS (over-engineering — contradizem a doutrina do próprio Onion)

A frota propôs, eu refuto com evidência (a doutrina anti-inchaço é a régua):

- **`operational-discipline-check.sh` (guarda automática que detecta `git add -A`, stale branch,
  orphaned monitor):** sedutor, mas é exatamente o **"guarda-hard que vira atrito ou bypass"** que o
  veredito RFC-0002 (laço-sem-guarda, CHANGELOG 2026-06-23) **já rejeitou** — o mecanismo recognition-primed
  (recall no momento certo) é mais robusto que bloqueio heurístico (que gera falso-positivo/atrito). A
  working-discipline **já foi elevada a regra global** carregada toda sessão — esse É o mecanismo de recall.
- **`/meta:dogfood` (comando scaffolder do gate de uso):** o gate de uso é **julgamento contextual humano
  por design** (dogfooding-doctrine: "invoque o artefato e observe"). Mecanizá-lo num comando adiciona
  superfície sem capturar o que importa. Adiar até haver gatilho de uso real.
- **meta-spec `memory-management.md` com type-system formal + schema YAML validado + hooks de captura
  automática:** a gestão de memória **já funciona** (híbrido + recall + índice). Schema validado por lint +
  captura automática = produto sem dogfood, contra o princípio "não implementar como produto sem dogfood".
- **`schema-verdict-cral.json` + `lint-review-verdicts.sh` (formalizar veredito adversarial em schema
  validável):** o veredito-como-hipótese é uma **disciplina de pensamento**, não um artefato a validar por
  lint. Formalizar em schema é inchaço; o valor está na prática, não no registro estruturado.

**Princípio comum das rejeições:** o Onion já decidiu (catálogo-first, dogfood-antes-de-produto,
anti-inchaço da régua toolbox) que **doutrina + recall recognition-primed > guarda-hard mecânica** para
comportamento. Codificar o método como **conhecimento navegável (KB)** respeita isso; codificá-lo como
**N gates/comandos/schemas** o viola.

## Conexão com o Tópico 2 (Harness + Ledger nos 3 modos)

A Camada 2 (Execução/PFR) e a disciplina de comunicação (co-evolução, transporte vs execução) são o
ponto de contato: o **harness** (sessões, subagentes, Workflow) é o substrato de execução do método, e o
**Ledger** é a camada de comunicação que se generaliza por modo (solo/equipe/federação). O Tópico 2
aprofunda isso. A KB integrada deste tópico deve **referenciar** o resultado do Tópico 2, não duplicá-lo.

## Próximo passo (decisão do maestro)

Discovery entregue. Se aprovado, o **P0 acionável** é escrever a KB `onion-working-method.md` (1 PR,
consolidação que cita as fontes) — um trabalho de **síntese**, não de nova infra. Os itens P1/P2 entram
no backlog com seus gatilhos. Os rejeitados ficam registrados aqui para **não voltarem a ser propostos**.
