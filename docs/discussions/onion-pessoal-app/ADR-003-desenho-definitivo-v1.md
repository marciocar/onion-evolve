---
title: "ADR-003 — Onion Pessoal: desenho definitivo v1 (do smoke-test ao companheiro N=1)"
status: proposto — aguarda ratificação do maestro
date: 2026-07-19
supersedes: none
depends_on: [ADR-001-arquitetura, ADR-002-vercel-ai-sdk]
kg_ssot: research/stack-research-2026-07.kg.yaml
decisao_pivo_do_maestro: "INVARIANTE 0 = Opção C (híbrido soberano) — lean confirmada 2026-07-19"
---

# ADR-003 — Onion Pessoal: desenho definitivo v1

> **O que muda daqui pra frente:** paramos de *provar plumbing* e passamos a *construir o produto*.
> Este ADR é o blueprint que transforma o scaffold validado (smoke-test) no **companheiro de vida do
> Marcio** — N=1, uso diário. Tudo aqui é **síntese** do que já foi decidido/provado, não invenção nova.

## 1. Contexto — onde estamos (validação COMPLETA)

O dogfood no **Moto G54** (device real, MediaTek, Expo Go SDK 57 — 2026-07-19) fechou os maiores riscos
técnicos **sem dev build**:

| Provado no device | Nó KG |
|---|---|
| git-on-device soberano (init/commit/log/status, estado persiste entre sessões) | `C_GITSYNC_LIGHT` · `E_GITPROBE_G54` |
| chat SSE end-to-end via BYOK (a chave do usuário paga) | `Q_PROTOCOL` · `E_GITPROBE_G54` |
| captura multimodal (foto→cérebro inline · mic · vídeo) | `C_MEDIA_CAPTURE` · `E_MEDIA_G54` |

Somado a: **ADR-001** (arquitetura: filho-não-parte, KG-SSOT-first, SDAAL, camadas, INVARIANTE 0),
**ADR-002** (Vercel AI SDK = interface-padrão de modelo), as **4 deep-researches** (stack/compat/standards/sync,
no KG-SSOT), o **life-KG** vivo (Trabalho/Saúde/Relações em `~/onion-pessoal/`) e o **desenho conceitual P1–P5**
(`docs/discussions/onion-pessoal-marcio/`).

**A lacuna que este ADR fecha:** o app de hoje é um *smoke-test* que fala com o **cérebro GENÉRICO do Onion
na VPS** (cwd=core). O companheiro definitivo fala com o **life-KG do Marcio** — e o KG cru (saúde, casamento)
**não pode viver em disco de terceiro/VPS**.

---

## 2. Decisão-pivô — INVARIANTE 0 = **Opção C (híbrido soberano)**

> Ratificada como lean do maestro em 2026-07-19.

- **O life-KG MORA no device** (repositório git local, sync soberano) — provado viável (`C_GITSYNC_LIGHT`).
- **O cérebro é LLM na nuvem via BYOK** — a chave do Marcio paga; ninguém mais custeia nem tabela (`Q_PROTOCOL`).
- **A INVARIANTE DURA (linha vermelha inegociável):** **NENHUM life-KG cru cruza a fronteira do device.**
  Só **contexto de-identificado** atravessa pro cérebro-nuvem.

### 2.1. As duas fronteiras de privacidade (NÃO confundir)
| Camada | v1 | Evolução | Regra |
|---|---|---|---|
| **De-id** (portão que protege o KG antes de sair) | **LOCAL por regra** (adapter `de-identification`, redação regex/dicionário, round-trip `restore(redact(t))===t`) | SLM on-device (melhor qualidade contextual) quando `Q_DEID`/`Q_PERF` fecharem (Poco) | **SEMPRE local** — de-id na nuvem vazaria o que devia proteger. `none` = fail-safe (bloqueia envio). |
| **STT** (transcrição de voz) | **externo/nuvem** (Whisper/Deepgram/Groq via adapter `speech-to-text`) — o áudio sai do device | STT on-device (executorch `useSpeechToText`, dev build) quando o SLM chegar | Vaza o áudio (aceito pelo maestro 2026-07-19, análogo ao cérebro-nuvem). Trocável sem tocar no resto. |

**Consequência topológica:** a VPS/bridge **não é** o cérebro privado. O `onion-bridge` genérico segue para o
**caminho público/federação** (dev/PM, A2A — ADR-001 D8); o **companheiro privado nunca lhe manda life-KG cru**.

---

## 3. Topologia de runtime — **app-orquestrado (C-direct)**

O loop `read → verify → act → write` roda **no device**, com o LLM como único ator externo (e cego ao KG cru):

```
[voz/foto/vídeo/texto]
      │  (captura — expo-camera/expo-audio/expo-video ✅ provado)
      ▼
  STT externo (se voz) ──► texto
      ▼
  read(life-KG on-device)  ── fatia relevante (isomorphic-git ✅ provado)
      ▼
  de-id LOCAL (redige PII → tokens)         ◄── portão de privacidade
      ▼
  LLM nuvem (Vercel AI SDK, BYOK)  ── vê SÓ contexto de-identificado
      ▼
  restore (des-redige a resposta, local)
      ▼
  act + write(life-KG on-device)  +  kg-radar (gate de integridade)
      ▼
  espelho na conversa (streaming)
```

- **Interface do LLM = Vercel AI SDK** (ADR-002) — provider trocável (Anthropic-nuvem agora → on-device depois),
  **direto do app** no caminho privado (não passa pela VPS). O `claude-agent-sdk`/bridge fica no caminho público.
- **kg-radar on-device:** precisa de um equivalente JS do gate de **integridade/schema** (subset determinístico do
  `.claude/validation/kg-radar.sh`). Item de build F1 — não reinventa o motor, porta o gate.
- **Sub-decisão deixada pro build (F1), com lean:** *quanto* do agent-loop o app reimplementa vs. um bridge no
  **nó confiável do Marcio** (notebook/mini-server) rodando Agent SDK sobre o life-KG. **Lean: C-direct** (app
  orquestra, zero servidor a manter) para o v1; promover a "bridge no nó confiável" só se o loop ficar complexo
  demais. Em nenhum caso a VPS toca o KG cru.

---

## 4. O core loop (o produto) — conversa-first

Captura e espelho são **o mesmo ato** (como a sessão que o Marcio viveu à mão). O app **É** o Claude com o
life-KG como memória persistente + o radar como órgão de reconciliação. Três batimentos, uma só conversa:

1. **Captura sem fricção** (input): voz (STT), foto (já vai inline ✅), vídeo (frame→imagem), texto. O *vivido*
   (PROD) entra sem virar mais um trabalho.
2. **Espelho** (reconciliação): o `read→de-id→LLM→write` estrutura o dump em nós do KG e o **kg-radar** aponta
   DEV×PROD, frescor, contradição — a "prévia-como-vista".
3. **Coach** (bright-lines/streaks): superfícies de apoio **penduradas na conversa**, não telas concorrentes.

Reúso vivo do core (ADR-001): o app **compõe** `kg-radar`, a prévia dialógica e o sensor `behavior-mapping-kg`
— não os reinventa (senão forka o framework, viola P3).

---

## 5. Build em camadas — do scaffold ao v1 de uso diário

Substância antes de superfície. Cada fase **dogfooda o artefato de verdade** (não só plano/lint).

- **F0 — Fundação de dados (barato, pré-requisito).** life-KG runtime-grade no device: schema + `verified_at`,
  sync git device↔`~/onion-pessoal/` (isomorphic-git). *Gate: kg-radar on-device exit 0.*
- **F1 — Motor privado (o coração do C).** Adapter `de-identification` LOCAL (regra) + `speech-to-text` (externo) +
  loop `read→de-id→Vercel-AI-SDK(BYOK)→restore→write` + kg-radar JS. *Gate: um dump de voz vira nós no life-KG,
  de-id'd, sem KG cru saindo (provar no proxy de rede).*
- **F2 — Superfície companheiro.** Conversa-first sobre F1; captura multimodal (já provada) fiada no loop;
  espelho/coach. *Gate: Marcio faz um check-in diário real e o KG reflete.*
- **F3 — Fronteira SLM (gated, Poco).** de-id e STT migram pra on-device (executorch); `Q_DEID`/`Q_PERF` fecham
  com dado real; dev build via EAS. *Gate: de-id on-device com round-trip + perf aceitável no Dimensity.*

---

## 6. Protocolo N=1 — Marcio como 1º usuário

- **Uso diário real** (não demo): check-in de manhã/noite; foto/voz do vivido; o espelho semanal via kg-radar.
- **Caveat intra-órbita (`C_ORBIT_CAVEAT`):** "funciona pro Marcio" ≠ "vende". A camada produto (ADR-001 F4)
  fica gated na evidência do N=1 — **não** se antecipa.
- **Métrica honesta:** o loop reduz a fricção de capturar o vivido? o espelho revela algo que o Marcio não veria?
  (não vaidade de features).

---

## 7. Consequências & fios abertos

- **Fecha:** onde o cérebro-privado roda (C), a topologia de runtime, o core loop, as duas fronteiras de
  privacidade, o build faseado, o protocolo N=1.
- **Gated (não bloqueia v1):** SLM on-device (`Q_DEID`/`Q_PERF`, F3, Poco); pesquisa de provider (WebSearch,
  sessão nova, cobrir LiteRT-LM); residuais do sync (`Q_GITSYNC` b/c/d: perf/merge N=1/Yjs).
- **Sub-decisão do build (F1):** C-direct (lean) vs bridge-no-nó-confiável — decide com o código na mão.
- **Herança do core (G1):** o app adota o *método* (não vendoriza `.claude/`); update-path docs-only segue
  como peça a desenhar (ADR-001 D1).

## 8. Rastreabilidade
ADR-001 (arquitetura, INVARIANTE 0) · ADR-002 (Vercel AI SDK) · KG: `C_GITSYNC_LIGHT`, `E_GITPROBE_G54`,
`C_MEDIA_CAPTURE`, `E_MEDIA_G54`, `D_SYNC`, `D_STACK`, `D_VERCEL`, `D_PLANB` · researches stack/compat/standards/sync
· conceitual P1–P5 (`onion-pessoal-marcio`) · app: github.com/marciocar/onion-pessoal-app (privado).
