---
title: "Onion Guardrails — a camada de guardrails nomeada (lente sobre gates existentes)"
category: concepts
tags: [seguranca, guardrails, gate, a2a, trust, intake, execucao, prompt-injection, taxonomia, fail-safe, catraca, baseline, frescor, temporal, verified-at]
status: candidato
date: 2026-07-12
---

# Onion Guardrails — a camada de guardrails nomeada

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 0.1.0 (candidato) |
| **Categoria** | Concepts |
| **Aplicação** | Nomear, indexar e enquadrar os guardrails que o Onion já enforça; base para discutir cobertura por superfície |
| **Origem** | Discussão isolada `guardrails-nemo-lens` (2026-07-11/12): pesquisa de mercado → mineração de vetos → doutrina de escopo → design R15 → 3 checagens do core |
| **Consolida** | [`authorization-layers`](authorization-layers-intake-vs-execution.md) · `a2a-verify` · `trust-topology-check` · `metaspec-gate-keeper` · `.claude/validation/*` |
| **Registro de design** | `docs/discussions/guardrails-nemo-lens/` (registro de discussão isolado, interno do core). *Dimensão:* o dossiê da frente `discuss/guardrails-nemo-lens` — pesquisa de mercado, a taxonomia minerada com read-paths, o protótipo R15 em quarentena e as 3 checagens do core (reconciliação, refutador adversarial, escopo) que aterraram esta camada. |

> **`candidato` — entra pra ganhar core por USO, não por estar pronta.** Esta KB nomeia e enquadra; não
> reivindica maturidade nem capacidade ativa. Toda afirmação de cobertura de mercado é **provisória**.

## 1. O que é (e o que NÃO é)

**Onion Guardrails** é a **moldura que nomeia, indexa e enquadra** os guardrails que o Sistema Onion **já
enforça** — hoje dispersos por `a2a-verify`, `trust-topology-check`, `.claude/validation/*`, never-clobber,
`metaspec-gate-keeper` e a camada de liberação [intake×execução](authorization-layers-intake-vs-execution.md).

> **É uma LENTE/ÍNDICE sobre gates existentes — não um sistema paralelo.** A grande maioria das categorias
> **herda por read-path** de mecanismos que já rodam; a taxonomia apenas os dá um vocabulário comum. Não é
> código novo; é o **nome, a moldura e a superfície** que faltavam.

O que **NÃO** é:
- ❌ **Não é 4ª dimensão peer.** As três permanecem produto/engenharia/compliance. Guardrail é **transversal**
  às três — como Task Manager ou Forge.
- ❌ **Não é vertical nova.** Consolidação transversal (KB + índice), não um plugin/manifesto `onion-guardrails`.
- ❌ **Não é DSL configurável** (estilo Colang/RAIL) nem **classificador probabilístico** no caminho crítico.

## 2. Doutrina de escopo — a decisão semântica

Derivada do diferencial-âncora (**determinístico + gated + spec-as-code**):

1. **Moderação de conteúdo** (violência/ódio/etc., estilo Llama Guard) é **delegada ao runtime hospedeiro**
   (Claude Code + provedor do modelo). O Onion é framework de desenvolvimento, não chatbot de usuário final.
2. **Nenhum classificador probabilístico** (guard-model) no caminho crítico — trairia o motor determinístico.
3. **A fatia semântica in-scope** é **proveniência de conteúdo não-confiável**: tratar conteúdo externo
   (federação, repo adotado, inbound) como **dado, não instrução**; marcar origem; gatear o efeito. É a
   leitura Onion do OWASP LLM01 — determinística, estendendo a camada de liberação, **nunca** um detector de
   injeção. (Design: `r15-untrusted-content-provenance.md` (interno do core) — **em síntese:** R15 disciplina o
   *canal*, não o conteúdo: origem não-confiável nunca vira instrução nem efeito sem cruzar um gate
   (proveniência marcada + dado-não-instrução + efeito gated), fechando OWASP LLM01 sem classificador de
   injeção; protótipo em quarentena — **desenhado, não wired no core**.)

## 3. Os três modos de enforcement

Todo guardrail Onion enforça de um de **três modos** (não dois):

| Modo | Como veta | Custo de falha | Exemplo |
|------|-----------|----------------|---------|
| **Determinístico** | script emite string + `exit≠0`; sem LLM | baixo (falha ruidosa, testável) | `a2a-verify` → `bad-signature` |
| **Gated** | constituição textual que um LLM-agente obedece; abstém sem evidência | médio (depende do agente respeitar) | `metaspec-gate-keeper` REGRA ZERO |
| **Estrutural / silencioso** | previne por construção; **nunca emite** — a condição de erro é impossível por design | mínimo (não depende de *detectar* o erro) | `durable-commit` (staging por whitelist) |

Ordem de robustez para guardrails novos: **estrutural > determinístico > gated**. O modo estrutural é o mais
seguro porque não depende de a condição de erro ser detectada — ela não pode ocorrer.

## 4. A taxonomia ONION-R (índice)

A taxonomia **emergiu dos vetos reais** que os gates já emitem (não foi projetada). O catálogo completo — 14
categorias `ONION-R1..R14` + R15 (proposta), **148 vetos com a string real emitida e read-path** — vive na KB
companheira [`onion-r-taxonomy`](onion-r-taxonomy.md).

> **Como o catálogo entrou no core sem violar o próprio ONION-R1.** Um catálogo de `arquivo:linha` **perpétuo**
> violaria ONION-R1 (integridade de SSOT) — a própria categoria que ela define. A promoção (2026-07-19)
> resolveu isso **rebaixando os números de linha**: a KB `onion-r-taxonomy` ancora cada veto pelo **arquivo**
> (read-path estável a refactor) + pela **string de veto emitida** (identificador greppável), e declara-se
> **snapshot a revalidar via `/meta:kb-freshness`** (re-grep dirigido). Os line-anchors datados ficam no
> registro de design `taxonomy-onion-r.md` (interno do core) — o fio #1 da discussão, onde a taxonomia foi
> minerada por fan-out (8 mineradores, um por gate) com cada veto ancorado em `arquivo:linha` datado de 2026-07-12.

Índice compacto (placement · modo · análogo de mercado — *nem todos são guardrails de segurança*):

| ONION-Rn | Categoria | Placement | Modo | Análogo |
|---|---|---|---|---|
| R1 | Integridade de SSOT / drift | meta | determinístico | ~OWASP LLM03 (*não-seg.*) |
| R2 | Autenticidade cripto A2A | input/fed | determinístico | nativo |
| R3 | Conformância de spec-as-code | input | determinístico | OWASP LLM03 |
| R4 | SSRF / egress | input/fed | determinístico | OWASP LLM06 |
| R5 | Never-clobber / adoção (I3) | exec | estrutural | nativo (~LLM06) |
| R6 | Topologia de confiança | federação | determinístico | nativo |
| R7 | Higiene de entrada CLI | input | determinístico | *(não-seg.)* |
| R8 | Contrato de federação | input/meta | determinístico | ~OWASP LLM03 |
| R9 | Anti-alucinação (REGRA ZERO) | meta | gated | **OWASP LLM09** |
| R10 | Proveniência / pin | input/exec | determinístico | **OWASP LLM03+04** |
| R11 | Anti-replay / frescor | input/exec | determinístico | nativo |
| R12 | Acessibilidade / WCAG | output | determinístico | *(não-seg.)* |
| R13 | Invariantes de orquestração | exec | gated+determ. | OWASP LLM06 |
| R14 | Fronteira SDAAL / tool | exec | determinístico | OWASP LLM06 |
| **R15** *(proposta)* | Proveniência de conteúdo não-confiável | input/fed/adopt | estrutural+gated | **OWASP LLM01** |

**11 das 14 categorias destiladas HERDAM por read-path** de gates existentes (reconciliação vs
`authorization-layers`/`a2a-verify`/`trust`: `reconciliation-authorization-layers.md`, interno do core — a
checagem #1 do core que deu o veredito HERDA/ESTENDE/NOVO por categoria e concluiu *zero contradição* com as 3
âncoras: ONION-R é lente/índice sobre gates existentes, não um SSOT paralelo). Só **R15** traz design novo — e mesmo ele **estende** a linha da KB
[`authorization-layers`](authorization-layers-intake-vs-execution.md) §7 (o "próximo passo" que ela declarou
faltar), não a reinventa.

### 4.1 R15.3a — os effect-gates estruturais que o core JÁ enforça (nomeados, custo zero)

R15.3 diz: *efeito irreversível derivado de conteúdo não-confiável cruza o gate de execução.* Para os canais
de federação (C1) e doc-bridge (C2) **isso já é verdade hoje, por construção** — o efeito não é *checado*, é
*impossível* sem gate (modo **estrutural**). **R15.3a é puro vocabulário**: nomear guardas existentes como
membros de ONION-R15; nenhuma linha de código muda. (O canal **C3** — `adopt`/`reverse-consolidate` — **não**
tem gate estrutural; fica para **R15.3b**, gated — ver `r15-untrusted-content-provenance.md` §6 (interno do core).)

| Canal | Guarda estrutural existente | Invariante (string real, greppável) | Read-path (arquivo) |
|-------|-----------------------------|-------------------------------------|---------------------|
| **C1 — federação a2a** | `a2a-accept` transporta o registro verificado da fila para o inbox, mas **nunca aplica** | *"NUNCA aplica nada; só transporta fila→inbox"* | `.claude/utils/federation-transport/a2a-accept.sh` |
| **C2 — doc-bridge inbound** | `co-deliver`/`co-relay` escrevem **UNTRACKED** no `inbound/`, nunca commitam no repo alheio (invariante I3) | *"ENTREGA-SEM-COMMIT … NUNCA commita no repo alheio"* | `.claude/utils/co-evolution/co-deliver.sh` |

> **Anti-drift (mesma regra da [taxonomia](onion-r-taxonomy.md)):** read-path a nível de **arquivo** + a
> **string-invariante greppável**, sem número de linha perpétuo. Revalidável por `/meta:kb-freshness`.

**Ganho:** com esses dois rótulos `ONION-R15.3a`, o Onion afirma cobertura parcial de **OWASP LLM01** com
read-path confirmado — sem escrever código. É o exemplo canônico de que a camada é *consolidação
transversal*: metade do valor é **reconhecer e nomear** o que o dogfood já construiu.

### 4.2 R15.1 — proveniência marcada: o que é estrutural-por-construção vs o que é read-time (R15.2)

O design de R15.1 assumia "os helpers de transporte ganham a linha de wrap". Ao promover ao core, o **código
real** refinou onde a cerca estrutural genuinamente se aplica (achado de campo 2026-07-19):

| Canal | Realidade do transporte | Enforcement R15.1 |
|-------|-------------------------|-------------------|
| **C1 — `a2a-accept`** | **NÃO inlineia o corpo não-confiável** — só o **referencia** (*"o a2a-live transporta o SINAL, não o corpo"*, `.claude/utils/federation-transport/a2a-accept.sh`). Os campos interpolados (`from`/`kind`/`id`) vêm de envelope **cripto-verificado** (`a2a-verify`: RS256 + kid-binding). | **estrutural por construção** ✅ — o corpo adversário nunca entra no contexto do core (mais forte que cercar). Nomeado, zero código. |
| **C2 — `co-relay`** | **copia o arquivo verbatim** com dedup-por-conteúdo (`cmp -s`) + idempotência (invariante I3 entrega-sem-commit). Cercar-na-cópia quebraria o dedup, a idempotência e a fidelidade do artefato durável. | **read-time (R15.2)** — a proteção do corpo do doc-bridge vive na **constituição** que o core aplica ao **ler** (`/meta:co-evolve`), não no transporte. O helper `onion-untrusted-wrap.sh` é a ferramenta de cerca disponível nesse read. |
| **C3 — `adopt`/`reverse-consolidate`** | lê repo alheio via `Read` nativo — sem hook único. | **read-time (R15.2 + R15.3b)** — cerca não se aplica (já era o design). |

> **Lição (dogfood do core):** "estrutural > gated" **não** significa "cerca em todo transporte". Significa
> preferir a defesa que torna o ataque **impossível por construção** — e às vezes o código já a tem (C1
> não-inlineia; melhor que cercar), enquanto forçar a cerca onde o transporte é verbatim (C2) só quebraria
> invariantes tateados. A cerca (`onion-untrusted-wrap.sh`) é a ferramenta **do read** (R15.2), não uma
> emenda cega em todo `cp`.

## 5. Cobertura e fronteiras (provisório)

Mapeando contra OWASP LLM Top 10 — **cobertura com lastro real** (não hype):

- ✅ **LLM03** (R3/R8/R10) · **LLM04** (R10) · **LLM06** (R4/R13/R14) · **LLM09** (R9) — coberto, determinístico.
- 🟡 **LLM01** (R15, proposta/protótipo) · **LLM02/07** (fatia verificável por regra, futuro).
- ⚪ **Llama Guard S1–S14** (moderação de conteúdo) — **delegado ao host** (doutrina §2).
- **Braços nativos sem equivalente nas taxonomias OWASP/Llama Guard**: R2/R6/R11 (autenticação/topologia/
  frescor message-layer agente-a-agente) e R5 (never-clobber de coabitação). *(A ausência ali é esperada —
  são taxonomias de moderação/injeção, não de identidade/federação de agente.)*

## 6. Falar em linguagem de mercado sem trair o motor

Lente Aristóteles (`igual→transfere / diferente→desenha`):
- **Transfere:** a moldura de placement (NeMo), a taxonomia nomeada (Llama Guard → `ONION-R`), o vocabulário
  on-fail (Guardrails-AI → o loop `fix→re-dogfood` é um `FIX_REASK` determinístico), os rótulos OWASP LLM0X.
- **Desenha próprio:** o **motor** (determinístico/gated/estrutural, não Colang nem guard-model) e os
  conceitos nativos (trust topology, never-clobber, entrega-sem-commit).

## 7. A catraca — doutrina de introdução de gate em base viva

**Origem:** sinal de campo de um adotante regulado (2026-07-20, `2026-07-20-gate-proveniencia-invertido.md`,
inbox interno do core) — **em síntese:** o adotante mostrou que os 3 mecanismos do KG-SSOT protegem o grafo de
*estar errado* mas nenhum impede conhecimento de *nascer fora dele*, e propôs um gate de proveniência
**invertido** ("este relatório existe no grafo?") com **catraca** (baseline tolerado, doc novo sem nó = HARD,
baseline só encolhe). O mecanismo específico é deles; a forma de **introduzir
qualquer gate novo** contra um passivo existente é geral o bastante para virar doutrina desta casa.

**Tese.** Um gate novo que nasce reprovando o passivo é desligado no primeiro dia — reprovar dezenas de
artefatos pré-existentes de uma vez é ruído, não sinal, e o próximo maestro sob pressão desativa a regra em
vez de resolver o passivo. A forma adotável tem três peças:

1. **Baseline do passivo, tolerado.** Tudo que já existe antes do gate nascer entra numa lista/allowlist
   explícita e é aceito sem bloquear.
2. **Violação HARD para o artefato **NOVO** — e, por serem pressupostos da própria catraca, também para **baseline que CRESCE** e para **baseline ausente** (sem ele não há catraca, e sair verde seria bypass).** Depois que o gate nasce, nada novo pode entrar fora da regra —
   aí sim a falha é dura.
3. **O baseline só encolhe.** Ele nunca cresce; a única direção permitida é sair da lista (o item foi
   corrigido/migrado). Se algo tentasse *entrar* no baseline depois do dia de nascimento, o gate perdeu a
   função.

**A inversão da métrica.** A saúde do gate não é "está tudo verde" — é **o baseline diminuindo**. Um gate
100% verde com um baseline enorme e estático não está trabalhando: está anestesiado, só constatando que o
passivo continua lá. Meça o gate pelo tamanho do baseline ao longo do tempo, não pela taxa de PASS.

**Caso vivo desta casa (evidência de por que importa).** Em 2026-07-19, a REGRA 28 do lint
(`check_outbox_channel_exists`, `.claude/validation/lint-artifacts.sh`) nasceu para pegar anúncio de
federação em staging sem canal de entrega — e, ao rodar pela primeira vez contra a base real, encontrou 6
anúncios de passivo pré-existente. A regra foi desenhada **SOFT deliberado, nunca HARD**, com a razão de
design escrita no próprio código: *a decisão — dar canal ao membro, ou o `/meta:co-announce` pular membros
sem canal — é do maestro, não do lint*. Sem essa catraca, o gate teria nascido HARD, bloqueado o CI, e a
única saída teria sido desligar a regra inteira — por uma condição que só o maestro podia **decidir**, não
o CI **corrigir**. A REGRA 28 catraqueia por classe fixa (SOFT sempre) em vez de baseline-por-lista; a forma
completa (baseline explícito + HARD-para-novo) é o alvo desta doutrina para gates onde o veredito por item
*é* decidível objetivamente — como o de proveniência invertido de um adotante regulado.

**Quando um novo gate entra em base viva:** declare o baseline (lista explícita ou classe que a torna
implícita), gate HARD só o que é novo depois do dia de nascimento do gate, e reporte saúde pelo tamanho do
baseline caindo — nunca pela taxa de PASS.

## 8. REGRA 42 — declarado≠verificado contra o TEMPO (irmão temporal da REGRA 29)

> **Wired como REGRA 42** do lint (`.claude/validation/lint-artifacts.sh` · helper `doctrine-freshness.sh`).
> O número **30 já é outra regra** ("Segurança de PROJEÇÃO: nome comercial de membro privado não sai") — por
> isso o frescor doutrinário é a 42, não a 30; repetir número de duas regras seria o próprio drift que a casa gateia.

**Origem:** pergunta do maestro 2026-07-23 (frescor doutrinário) + a doutrina `verify-external-for-current`
("algo atual/emergente/popular deve ser buscado externo, nunca respondido do cutoff") — provada no próprio
dia por dogfood: um world-sync achou um tier de modelo inteiro acima do que a doutrina
registrava, tetos inferidos errados e **aspas fabricadas** numa KB — tudo em doutrina que "parecia fina", sem
uma linha do repo mudar.

**O nome.** A REGRA 29 (`kg-provenance-coverage`, gate de proveniência invertido — origem: sinal de campo de
um adotante regulado, 2026-07-20) pergunta *"este conhecimento existe no grafo?"* — **espacial**: fecha
conhecimento nascendo fora do KG. **REGRA 42** é o irmão **temporal**: fecha afirmação world-facing que **expirou
em silêncio**. As duas são a mesma classe — **declarado≠verificado** — testada contra eixos diferentes:

| Gate | Pergunta | Eixo |
|---|---|---|
| **REGRA 29** | "este conhecimento existe no grafo?" | espacial (existe / não existe) |
| **REGRA 42** | "esta afirmação world-facing tem verificação ainda fresca, ou expirou em silêncio?" | temporal (era verdade / ainda é verdade) |

**A armadilha a não cair.** REGRA 42 **não** consulta a web em CI ("esta afirmação ainda é verdade?") — isso é
**NO-OP** (runner sem rede) e indecidível por construção. O gate verifica só que toda afirmação
sensível-ao-tempo **carrega** `verified_at` + `source` e que essa data **não expirou** — ele força
**re-verificação periódica**; quem re-verifica é a sessão via `/meta:kb-freshness`, **nunca** o gate. É isso
que o mantém CI-safe e determinístico (mesma lição do STALE-OLD do `kg-radar.sh`: compara **datas**, nunca
consulta o mundo).

### 8.1 A convenção — frontmatter, granularidade por-doc

```yaml
---
verified_at: 2026-07-23     # AAAA-MM-DD — quando a afirmação foi cruzada contra a fonte primária
source: https://...          # URL da fonte primária consultada
---
```

- Granularidade **por-documento** (não por-afirmação): um doc world-facing carrega **um** `verified_at` que
  cobre todas as afirmações sensíveis-ao-tempo nele. Mais grosso que o KG (nó a nó), deliberado — prosa não
  tem endereço interno estável para pin fino.
- A **lista de docs world-facing** que o Nível A cobre é um **pressuposto enumerado no helper**, não uma
  heurística — ver REGRA DE ADMISSÃO (§8.4).

### 8.2 Dois níveis — só um é mecânico

| Nível | Escopo | Sem `verified_at` | `verified_at` STALE (>TTL) | Malformado / no futuro |
|---|---|---|---|---|
| **A — lista enumerada** | docs world-facing explicitamente listados no helper | **HARD** (via catraca) | **SOFT** "re-verifique" (atenção, não reprova — mesmo tom do radar) | **HARD** (erro estrutural) |
| **B — rede lexical** | qualquer doc **fora** da lista, com tokens-gatilho (*lineup vigente*, *versão atual*, *latest*, *modelo mais recente*, *generally available*, *atualmente*…) | **SOFT-only** | **SOFT-only** | **SOFT-only** |

- **Nível A é o único que reprova build.** É honesto porque a lista é fechada e auditável — o gate consegue
  provar exatamente o que cobriu.
- **Nível B é convenção-com-rede, não gate** — a mesma honestidade que um adotante regulado aplicou ao idioma de ids: um
  grep por vocabulário-gatilho pega candidato, não confirma cobertura, e por isso **nunca** é HARD. Existe
  para dar sinal cedo num doc que ainda não entrou na lista A (nem todo "atualmente" é, de fato, world-facing).

### 8.3 Reuse — nenhum mecanismo novo, três primos já existentes

- **A catraca (§7 desta KB).** REGRA 42-Nível A **é** a catraca aplicada a um eixo novo: baseline (docs sem
  `verified_at` hoje) tolerado; doc **NOVO** sem a tag → HARD; baseline só encolhe. Não é analogia — é a
  mesma forma de três peças, com o assunto trocado de "proveniência" para "frescor".
- **O STALE-OLD do `kg-radar.sh`.** REGRA 42 generaliza esse padrão — de **nó de grafo** (`verified_at` ×
  `baseline`, duas datas do próprio arquivo, sem tocar relógio) para **afirmação em prosa de KB**. Mesmo
  mecanismo de comparação de datas; muda só o que é comparado.
- **A guarda `clock-untrusted` do `a2a-verify.sh`.** É o **pressuposto** do gate inteiro: "recente" só vale
  com relógio provado (via `timedatectl`/`chronyc`/`ntpstat`). REGRA 42 herda a mesma desconfiança — comparar
  `verified_at` contra "hoje" sem relógio atestado é comparar contra um número que pode estar errado.

### 8.4 REGRA DE ADMISSÃO — os pressupostos do próprio gate, enumerados

Um gate que declara cobertura sem provar do que depende é o ponto cego que esta casa já nomeou
(`.claude/diary/2026-07-20-admission-rule-blindspot.md`): *"pressuposto não enumerado é rodada adversarial
futura."* REGRA 42 enumera os seus quatro, para nascer sem esse furo:

1. **A lista world-facing.** Fixa e auditável no helper — nunca inferida por heurística. Crescê-la é decisão
   humana (mesmo espírito do baseline: só o maestro decide o que entra em Nível A).
2. **O TTL (90 dias default).** É config, e config **é fixada pela fixture nos testes, nunca pela
   implementação** — a mesma lição já paga em T2.5e: um teste que lê o TTL real do sistema em vez de um
   valor injetado pela fixture é um teste que, mais cedo ou mais tarde, vira flake ou bomba-relógio.
3. **O relógio.** "Hoje" só vale com relógio provado — herdado do `a2a-verify` (§8.3). Sem essa prova,
   dizer que um `verified_at` "está velho" é uma afirmação sem lastro.
4. **O baseline.** Sem baseline explícito e versionado não há catraca — o gate sairia verde por *ausência*
   de regra, não por conformidade (mesmo aviso já registrado na REGRA 29: baseline ausente é HARD, nunca um
   passe livre).

### 8.5 O encaixe — de "coisa que se lembra" a forcing function

A doutrina `verify-external-for-current` já dizia *que* algo atual precisa de verificação externa — REGRA 42 é o
que torna isso **mecânico**: transforma "reatualizar-se do mundo" de intenção-que-se-esquece em **forcing
function** que o CI aplica sem depender de alguém lembrar. O gate **não** faz a re-verificação em si — só
força a cadência. Quem de fato re-verifica contra o vivo é a sessão, via `/meta:kb-freshness`; REGRA 42 é o alarme
que diz **quando**, `kb-freshness` é quem **responde**.

## 9. Status e próximos passos

- ✅ Doutrina, taxonomia (evidência) e design R15 fechados; 3 checagens do core passadas (reconciliação,
  refutador, escopo).
- ✅ **Doutrina da catraca** (§7) — promovida a partir do sinal de campo de um adotante regulado (2026-07-20).
- ✅ **Doutrina REGRA 42 — frescor doutrinário** (§8) — irmã temporal da catraca/REGRA 29; escrita a partir da pergunta
  do maestro 2026-07-23 e do dogfood de world-sync do mesmo dia (tier de modelo, tetos e aspas fabricadas,
  todos achados no mesmo ciclo). Wire-in mecânico (helper determinístico + catraca real + REGRA de lint) é
  trabalho futuro — hoje é só doutrina, deliberadamente.
- 🔜 **Gate anti-drift da taxonomia** (ONION-R1 sobre si mesma) — pré-requisito para promover o catálogo
  detalhado ao core.
- 🔜 **R15 (wire-in)** — cerca de proveniência + gate de efeito; hoje protótipo em quarentena, não wired.
- 🔜 **Superfície `/meta:guardrails`** (índice de leitura vs DSL) — questão de design aberta; fora de escopo.
