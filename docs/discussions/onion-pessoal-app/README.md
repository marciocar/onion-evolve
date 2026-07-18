# App Onion Pessoal — estado da arte da discussão

> Discussão isolada (`discuss/onion-pessoal-app`, pushada). **Pensa-não-entrega** — nada ao core/produção sem pedir.
> Mapa de entrada: comece pelo KG-SSOT (`research/stack-research-2026-07.kg.yaml`, radar exit 0) — é a verdade
> reconciliada; esta prosa é o destilado. Atualizado 2026-07-18.

## O que é
App **companheiro conversacional** sobre o **life-KG** do Marcio (grafos em `~/onion-pessoal/`), na doutrina
**KG-SSOT-first + runtime SDAAL**, com câmera/mic e caminho pra SLM on-device. Ordem-mãe: **camadas pessoal→produto**.
Founding-question: **superfície nova, motor adotado, dado soberano** (ver `SEED.md`).

## Decisões (ADR-001 rev.2 — `ADR-001-arquitetura.md`)
- **D1** Filho, não parte (adopter que federa; `marcio-pessoal` no `members.yaml`). **D8** federação **continua** (/chat ⊥ /a2a).
- **D2** Stack **React Native + Expo (SDK 57)** + executorch/callstack p/ SLM. **Compat verificada, não defasado.**
- **D3** Cérebro = **onion-bridge reconfigurado por env** (cwd=core + LIFE_KG); **D4** chat = superfície verificada (contrato real lido).
- **D5** SLM on-device = adapter SDAAL `de-identification/local-slm`. **D6** KG-SSOT-first com kg-radar como **gate**.
- **D7** camadas + sequenciamento privacy-safe. **INVARIANTE 0:** cérebro sobre `private` roda em **nó confiável, nunca VPS**.
- **Endurecido por review adversarial orquestrado** (privacidade/P4 · doutrina · técnica) — pegou furos que a rev.1 tinha.

## As 4 pesquisas (deep-research, verificação adversarial — todas em `research/`)
| # | Pesquisa | Veredito | Task |
|---|---|---|---|
| 1 | **Stack** (`stack-research-2026-07.{md,kg.yaml}`) | RN + Expo + executorch (único que bate os 4 requisitos com fonte primária) | `wwujc53hz` |
| 2 | **Compat** (`compat-research-2026-07.md`) | SDK 57 é a última; executorch casa (New Arch); **não defasado** | `wte2k70qw` |
| 3 | **Standards + plano-B** (`standards-planb-research-2026-07.md`) | Não perder: **Vercel AI SDK** (falta adotar) + **MCP** (já alinhado). Plano-B = interface unificada + roteamento híbrido | `wzxz11dvf` |
| 4 | **Sync** (`sync-research-2026-07.md`) | **git FICA o SoT** (Ink&Switch valida); local-first-DBs desqualificados; caminho = isomorphic-git em nodejs-mobile | `wlgpeo1sj` |

## Contrato do bridge (verificado — `proto/chat-endpoint.md`)
`POST /chat` bearer + SSE (forwarding SDKMessage), `query()` API, **workspace-por-token com symlink do .claude do core**
(resolve o cwd-vs-tools). Lido do fonte real na VPS. Deltas de hardening p/ o life-KG registrados.

## Spikes restantes — ranqueados (o teto do autônomo; precisam device/ambiente)
1. **`Q_GITSYNC` (execução)** — nodejs-mobile + isomorphic-git no device: rota leve vs pesada, perf, merge N=1. *Destrava o sync soberano.*
2. **`Q_DEID`** (crítico, gated) — um SLM 0.6-3B faz de-id de PII bem o bastante? *Gate da privacidade local-first (P4).*
3. **Adotar Vercel AI SDK** (decisão, não spike) — a camada-interface que falta (C_ALIGN); maior risco de divergência dos standards.
4. **`Q_PERF`** — perf do executorch em Android mid-range (acopla com Q_DEID).
5. Menores: checar **Yjs** em RN (buffer CRDT futuro); `Q_ABSENT` (Tauri/KMP/Nano).

## Caminho near-term (o que NÃO está bloqueado)
O **shell** shipa já no SDK 57 (chat + câmera/mic + SSE + bridge-reconfig), **sem** SLM (adiado) e com git-sync v1 simples
(o bridge no nó confiável commita/pusha; app = cliente fino). Os spikes gateiam as **camadas futuras** (SLM on-device, git-no-device), não o nascimento do app.

## Processo / co-evolução
- Sinal de dogfood ao core **entregue na inbox da main** (`af5351d`): o harness `deep-research` não faz `write(KG)` automático → o core deve prever/wire (`/meta:orchestrate→/meta:kg`). + furo do hook beacon.
- Padrão seguido em todas as passadas: pesquisa orquestrada → `.md` (destilado) + `.kg.yaml` (SSOT, radar exit 0) → commit + push.
