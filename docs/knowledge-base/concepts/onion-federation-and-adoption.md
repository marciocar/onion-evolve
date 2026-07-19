---
title: "Federação e adoção do Onion — guia de síntese"
date: 2026-07-06
type: concept
status: active
note: "Os perfis da §6 são ilustrativos (anonimizados para circulação pública)."
related:
  - multi-repo-federation.md
  - federation-usage-modes.md
  - source-vs-derivation.md
  - ../../evolution/federation/members.yaml
  - ../../../.claude/commands/meta/adopt.md
  - ../../../.claude/utils/trust/adapters/source.md
  - ../../../.claude/utils/trust/adapters/hub.md
  - ../../../.claude/utils/trust/adapters/standalone.md
  - ../../../.claude/utils/trust/adapters/consumer.md
---

# Federação e adoção do Onion — guia de síntese

> **O que este documento é — e o que não é.** É uma **derivação de leitura** (doutrina
> [fonte≠derivação](source-vs-derivation.md)): reúne, num só lugar e numa ordem pedagógica, o que
> já está espalhado — e correto — em seis fontes canônicas (listadas em `related:` acima). **Não**
> é uma segunda matriz concorrente: onde a matriz canônica de tipos de uso já existe
> ([federation-usage-modes.md](federation-usage-modes.md)), este guia **cita**, não reescreve. O
> valor novo aqui é a costura pedagógica: caminhar o processo real de `/meta:adopt` fase-a-fase, a
> tabela de permissão consolidada dos 4 adapters de trust, e os 5 perfis reais como estudo de caso —
> nenhum dos três existe hoje reunido em um só lugar. Se uma fonte citada mudar, corrija a fonte —
> este documento é descartável e reconstruível a partir dela. Camada de leitura irmã: o Artifact
> HTML "premium" derivado deste markdown (link entregue à parte, uso interno).

## 1. Dois sistemas, não um

O Onion tem **duas máquinas de coordenação entre repos**, com maturidade muito diferente. Confundi-las
é o erro mais comum ao explicar "a federação":

| | **Co-evolução / Adoção** | **Federação formal por contrato** |
|---|---|---|
| Estado | 🟢 **ativo, em uso real** — 5 membros registrados hoje | 🔒 **construído, não graduado** — 0 contratos, 1 adotante |
| Unidade | um **membro** (repo inteiro) | um **contrato** (uma integração específica entre 2 repos) |
| Mecanismo | `/meta:adopt`, `members.yaml` (tiers + trust), canais `inbox/`/`inbound/` | `contracts/<id>.md` num ledger git, `CHANGELOG.md` como inbox |
| Pergunta que responde | "este repo é do Onion — o que ele pode trocar com o resto?" | "esta API específica entre A e B pode mudar sem quebrar nada?" |
| Quando liga | sempre que alguém adota | só quando um contrato **pode quebrar consumers** ou há **3-5+ adotantes** ([gatilho](federation-usage-modes.md#4-gatilhos-de-graduação--tabela-única)) |

Este guia cobre os dois: §2-§6 são a Co-evolução/Adoção (o que está em uso); §7 é a Federação formal
(a capacidade latente, para quando o gatilho chegar).

## 2. Modelo mental (por que "federação", não "plataforma")

Fonte: [`multi-repo-federation.md` §1](multi-repo-federation.md#1-modelo-mental-peer-não-hub).

- **Peer, não hub-and-spoke.** Cada repo mantém seu Onion **soberano** — o core não hospeda nada dos
  adotantes, não roda dentro deles, não os controla remotamente.
- **Git-assíncrono.** Não há servidor, conexão viva ou API entre instâncias. A troca é sempre um
  arquivo markdown commitado (ou entregue sem-commit) em um canal convencionado.
- **O humano é o maestro.** Toda decisão de "levar isto de A para B" passa por uma pessoa.
- **Linha vermelha inegociável:** nunca IA-fala-IA em tempo real entre repos distintos (abandonada
  formalmente em 2026-05-18). O "Agent Card" A2A é, na melhor hipótese futura, uma *projeção de
  formato* one-way — nunca transporte vivo.

## 3. As camadas (tiers) — RFC-0003

Fonte: `members.yaml` (`role:` de cada membro) + os 4 adapters de trust
(`.claude/utils/trust/adapters/*.md`).

| Tier | Papel | Parent | Sub-adotados (downstream) |
|---|---|---|---|
| **T0 — source** | o core (`onion-evolve`) — autoridade emissora, lê tudo por papel | nenhum | qualquer membro |
| **T1 — hub** | adotou o core **e** tem seus próprios adotados | `source` | T2 (consumers) |
| **T2 — consumer** | adotou um **hub**, não o core diretamente — o hub é seu único ponto de contato upstream | um hub T1 específico | nenhum |
| **T3 — standalone** | adotou o core direto, sem sub-adotados — a instância mais simples | `source` | nenhum |

### 3.1 Quem pode falar com quem (a tabela que faltava consolidada)

Extraída literalmente dos 4 adapters — cada linha é uma regra real do arquivo-fonte, não inferida:

| De ↓ / Para → | Core (T0) | Hub T1 (peer) | Seu parent (se T2) | Seus T2 (se hub) | Outro T3 |
|---|---|---|---|---|---|
| **Core (T0)** | — | `relay`/`advise`/`correct` sempre autorizados (autoridade implícita) | idem | idem | idem |
| **Hub (T1)** | `relay` sempre; `advise`/`correct` só com concessão explícita em `trust:` | `relay`/`advise` só se **ambos** os lados concederem (`can_advise_to` + `can_receive_from` do peer); `correct` bloqueado por padrão, exige intermediação do core | — | `relay`/`advise`/`correct` sempre (hub tem autoridade sobre seus T2) | n/a |
| **Consumer (T2)** | **bloqueado** — sem canal direto; tudo passa pelo hub | n/a | `relay`/`advise` sempre; `correct` bloqueado por padrão | n/a | **bloqueado** sempre |
| **Standalone (T3)** | `relay` sempre; `advise`/`correct` só com concessão explícita | **bloqueado** por padrão (sem acesso lateral a T1) | n/a | n/a | **bloqueado** sempre — T3s são isolados entre si e nem sabem da existência uns dos outros |

**Visibilidade de classificação** (`private`/`protected`/`peer`/`downstream`/`public`/`collective`) segue
o mesmo funil: `private` é **imutável** — nem o core lê `private` de outro membro, em nenhuma
circunstância. `public`/`collective` fluem livremente para o core; `protected` só para quem está
em `diary_readable_by`; T3 só enxerga `public` de qualquer origem.

**Verificação, não confiança de leitura:** a máquina de trust não é papel — é script determinístico
(`.claude/validation/trust-topology-check.sh`, `--dry-run`). O mesmo vale para o **pin** de cada
membro (o commit do framework que ele diz ter): `pin-integrity-check.sh` verifica um canário
vendorizado contra o pin declarado antes de qualquer `--update` confiar nele — o incidente que
motivou isso (pin forjado por restore manual, 2026-06-30) está registrado como memória de família
"declarado≠verificado".

## 4. O processo de adoção, passo a passo

Fonte: [`/meta:adopt`](../../../.claude/commands/meta/adopt.md) (única via de entrada na federação —
"NÃO é CLI standalone", roda dentro de uma sessão Claude Code que já é a fonte).

### 4.1 Contrato de Segurança (antes de qualquer fase)
1. **Dry-run primeiro** — todo `diff` é mostrado antes de qualquer escrita.
2. **Branch dedicada** (`onion/adopt`) — nunca a branch default sem consentimento.
3. **Never-clobber implementado** — extrai para tmp, faz `diff` contra o alvo, só aplica após revisão;
   customização local do alvo aparece no diff em vez de ser sobrescrita.
4. **Idempotente** — re-adotar/atualizar aplica o delta, nunca duplica.

### 4.2 As fases
| Fase | O que faz |
|---|---|
| **PASSO 0** | Captura a identidade da fonte (`onion-version.sh`) **antes de qualquer cd/cópia**; resolve o alvo (path ou clone); detecta o modo (greenfield/legacy/regulated). |
| **Fase 1 — Engenharia reversa** | Pulada em greenfield. Em legacy/regulated, roda `/docs:reverse-consolidate` para alimentar o `technical-context` do alvo. |
| **Fase 2 — Instalar** | Cria a branch/worktree `onion/adopt`; aplica o Procedimento de cópia segura (manifesto filtrado → `git archive` → tmp → diff → `cp`). |
| **Fase 3 — Scaffold** | Cria `docs/{business,technical,compliance}-context/` vazios (governança **do alvo**, L1+); gera `CLAUDE.md` (never-clobber → `CLAUDE.onion.md` se já existir); registra hooks no `settings.json` (merge); cria o starter `docs/evolution/{inbox,inbound}/`; **gera `docs/onion/inventory.md` do alvo** — gap real descoberto no dogfood de um adotante (greenfield): o próprio hook recém-instalado bloqueava o 1º commit sem isso. |
| **Fase 4 — Integrações (`.env`)** | Roda **dentro do alvo** (não da fonte) — `/meta:setup-integration`. |
| **Fase 5 — Carimbar** | Escreve `.claude/.onion-version` no alvo com a identidade **da fonte capturada no PASSO 0** (nunca re-derivada do alvo). |
| **Fase 6 — Relatório** | Auto-emite um relatório em `docs/evolution/inbound/` do alvo (nunca no `inbox/` dele — canais têm direção); oferece registrar o alvo em `members.yaml`. |

### 4.3 Os três modos (eixo A — cenário do alvo no momento da adoção)

| Modo | O que muda |
|---|---|
| **greenfield** | scaffold + instalação direta; engenharia reversa mínima |
| **legacy** | engenharia reversa obrigatória; instala em **worktree** (isola do código legado); `CLAUDE.md` nunca sobrescreve o existente |
| **regulated** | tudo do legacy **+** `compliance-context` populado via `/docs:build-compliance-docs` + agentes de compliance (ISO 27001/22301/SOC2/PMBOK) já no manifesto |

`--in-place` é um quarto caminho **fora da federação por construção**: não instala nada, não carimba
versão, não entra em `members.yaml` — inspeção/operação efêmera.

## 5. O que cada perfil leva do core (e o que nunca leva)

Manifesto real copiado pela Fase 2 (`want=()` do Procedimento de cópia segura):

```
.claude/{agents,commands,skills,utils,validation,hooks}
docs/{meta-specs,knowledge-base,sdaal}
```

**Nunca vendorizado** (é do alvo, por definição): `docs/{business,technical,compliance}-context/`
(a governança L1+ do domínio dele), `docs/evolution/` (os canais são infraestrutura local — copiá-los
clobaria o inbox/inbound em uso), `.env`/`.env.example` (never-clobber por-arquivo, específico do
projeto), qualquer coisa em `docs/{analysis,materials,applying}` da fonte (nunca sai da árvore
rastreada por `git archive`).

## 6. Casos de uso reais — os 5 perfis hoje registrados

Fonte: [`members.yaml`](../../evolution/federation/members.yaml) — nenhum número inventado.

### 6.1 `onion-mini` — a exceção que define a fronteira
`role: standalone`, mas **`onion_version: n/a`**. Não é adoção — é **destilação curada**: reescreve a
doutrina (master-prompt como bytecode) sem vendorizar `.claude/`. Existe precisamente para marcar
onde "adotar" termina e "destilar/citar" começa — um standalone de verdade sempre tem um
`onion_version` verificável; este não tem porque não é o mesmo contrato.

### 6.2 Adotante greenfield padrão
`role: standalone`, `mode: greenfield`, `onion_version` **verificado** por `pin-integrity-check.sh`
na própria adoção. Organização externa real — o Onion **ajuda**, não é produto do Onion. Ciclo
completo rodado até F1 (vertical educacional).

### 6.3 Adotante hub (T1)
`role: hub`, **multi-linhagem** (`framework` em `develop`, `production` em `<adopter>/main` — cada
linhagem com seu próprio pin verificado). Na prática opera como standalone com potencial de crescer:
tem a *capacidade* de ter sub-adotados (T2), mas nenhum existe ainda — `exposes_downstream: []`.

### 6.4 Adotante regulado — trust elevado sem role elevado
`role: standalone`, `mode: regulated` (ambiente regulado real). Trust elevado incomum:
`can_correct_to: [onion-evolve]` — concedido não por hierarquia, mas por rigor comprovado: a mesma
falha de lint (`|| return` sem argumento, abortando sob `set -e`) foi achada e corrigida
independentemente lá **e** no core, no mesmo dia, com poucas horas de diferença, zero comunicação
entre as partes — descoberta convergente verificada via `git blame`. Ilustra a doutrina
[fonte≠derivação](source-vs-derivation.md) na prática: a pergunta "um adotante regulado deve ter seu
próprio `source`?" foi respondida **não** — existe uma só fonte; o que o ambiente regulado precisa
(controle deliberado de quando puxar updates) já é resolvido pelo campo `integration_branch: develop`
explícito, sem duplicar autoridade.

### 6.5 `onion-evolve` — o próprio core, também multi-linhagem
`role: source`, T0. Sem bloco `trust:` (lê tudo por papel, não por concessão). Também vive em mais
de um checkout — `workstation` (autoridade, sem pin: sua versão *é* a HEAD) e `vps-bridge` (linhagem
que trabalha de verdade, serve `app.onionevolve.com`, pin verificado via SSH).

## 7. Federação formal por contrato (capacidade latente — ainda não graduada)

Fonte: [`multi-repo-federation.md`](multi-repo-federation.md) completa.
Resolve um problema **diferente** do §2-§6: não "quem é membro", mas "esta integração específica X
entre o repo A e o repo B pode mudar sem quebrar o B".

- **Unidade:** um contrato em `contracts/<id>.md` num ledger git dedicado, com 8 seções obrigatórias
  — `id`, `version` (semver), `producer`, `consumers`, `interface`, `types`, e as duas que fecham o
  gate de verdade: **`tests`** (≥1 path de contract-test — sem teste é blocker) e **`fixtures`**
  (≥1 payload real — o que transforma "promessa sintática" em "gate comportamental").
- **Ciclo:** `/meta:federation-register` (valida+grava o contrato, sem anunciar) →
  `/meta:federation-publish` (único escritor do CHANGELOG/inbox — anuncia com checkpoint do maestro)
  → `/meta:federation-check` em cada consumer (veto de 1ª mão: `approved:false` ou saída ausente
  **bloqueia**, fail-safe) → `/meta:federation-status` (drift + CI, veredito SÃO/ATENÇÃO) → PRs
  coordenados pelo maestro (producer primeiro, consumers depois) → se quebrar,
  `/meta:federation-rollback` guia a reversão na ordem inversa.
- **Por que ainda não graduou:** o gatilho é "contrato que pode quebrar consumers **OU** 3-5+
  adotantes" — hoje há 1 adotante real de peso (os adotantes ainda não trocam contratos
  entre si) e 0 contratos registrados. O MVP mecânico existe e foi validado num ledger scratch;
  falta o ledger de produção com remote+concorrência real. Graduar antes disso seria especulação —
  o doc-bridge leve (§2-§6) já resolve o que existe hoje.

## Referências
- [multi-repo-federation.md](multi-repo-federation.md) — formato de contrato + ciclo da federação formal
- [federation-usage-modes.md](federation-usage-modes.md) — a matriz canônica dos 5 eixos (cenário/controle/tier/operação/topologia) + gatilhos de graduação
- [source-vs-derivation.md](source-vs-derivation.md) — a doutrina que rege como este próprio documento deve se comportar
- [`/meta:adopt`](../../../.claude/commands/meta/adopt.md) — o comando fonte de toda a §4
- [`members.yaml`](../../evolution/federation/members.yaml) — os perfis reais da §6 (uso interno)
