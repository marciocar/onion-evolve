---
title: "ADR-003 — Onion Pessoal: desenho definitivo v1 (do smoke-test ao companheiro N=1)"
status: aceito — ratificado pelo maestro 2026-07-19 (após revisão adversarial; 3 furos incorporados)
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

**Sequenciamento por sensibilidade (revisão 2026-07-19, Furo 1):** de-id por regra é **FRÁGIL** (perde
identificadores indiretos, nomes fora do dicionário). Portanto o **v1 NÃO expõe as verticais mais sensíveis
(Saúde, Relações) ao cérebro-nuvem via de-id-de-regra**: começa por **Trabalho** (menor dano se vazar); as
sensíveis operam em **over-redação** (redige agressivo, aceita perda de contexto) ou ficam **gated no de-id por
SLM on-device (F3)**. `none`=fail-safe bloqueia o envio se o de-id não rodar. — o portão frágil não guarda o
cofre mais caro até endurecer.

### 2.2. Onde o life-KG persiste e sincroniza (revisão 2026-07-19, Furo 2)
O life-KG cru vive no **device** (primário) e num **nó confiável do Marcio** (secundário/backup — notebook/
mini-server). O **remote git de origem NÃO é a VPS** (disco de terceiro). Se um remote de nuvem for usado p/
durabilidade (ex.: GitHub privado), o KG cru vai **cifrado em repouso** — cifra = **SOPS+age** (recomendação de
mercado jul/2026, verificada via fallback SDAAL de busca; envelope-encryption **filter-light** → encaixa no
isomorphic-git melhor que git-crypt, que depende de filtros clean/smudge). *Repo privado ≠ soberano; só cifrado
conta*. **Hoje `~/onion-pessoal/` mora na VPS (estado pré-definitivo)** → **F0 inclui migrar
a origem soberana p/ FORA da VPS** (device + nó confiável; a VPS deixa de ser guardiã do KG cru). Ink&Switch
valida device=primário, servidor=secundário.

**Reconciliação com a `D_SYNC` (2026-07-19, busca fresca via fallback SDAAL):** o mercado local-first 2026
convergiu em **CRDT + sync-engines E2EE** (`any-sync`, `MindooDB` — "*servers can store and sync, but cannot
read*"). Isso **VALIDA** o princípio *soberania por cifra / server-can't-read* — não o refuta. A `D_SYNC`
desqualificou local-first-DBs por "server vira SoT plaintext" (PowerSync/ElectricSQL); essa desqualificação
**NÃO se aplica aos zero-knowledge** (MindooDB/any-sync). **Mantemos git-as-SoT** (o KG-SSOT é git-native — reúso
do substrato do core + `kg-radar`; vantagem estrutural que nenhum engine dá), MAS `any-sync`/`MindooDB` entram
como **watch-items a avaliar** na pesquisa de sync (sessão nova; **RN-compat é make-or-break, ainda não
verificado**) — inclusive como possível **transporte cifrado sob o KG**. Divergência do mercado (CRDT) é
consciente e justificada, não ignorância.

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
  - **Risco (revisão 2026-07-19, Furo 3):** C-direct **reimplementa** o agent-loop (tool-calling, sessão,
    reconciliação) → pode inflar F1; e o **kg-radar JS arrisca DIVERGIR** do canônico (`.sh`). Mitigação: portar
    só o **subset de integridade/schema** (não a reconciliação inteira) + **teste de conformidade JS↔sh** (mesmo
    `.kg.yaml`, mesmo veredito); **fallback pronto** = bridge no nó confiável (reusa Agent SDK + o radar canônico
    sem porta). **Gatilho de troca:** se o loop app-side exceder o esforço do fallback já em F1, promove o bridge.

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

- **F0 — Fundação de dados (barato, pré-requisito).** life-KG runtime-grade: schema + `verified_at`; **migrar a
  origem soberana p/ FORA da VPS** (device primário + nó confiável; cifrado se em remote de nuvem — §2.2); sync
  git via isomorphic-git. **Spike obrigatório: `isomorphic-git × SOPS+age`** — provar cifra-em-repouso no
  git-on-device (age é filter-light; validar clone/push/pull cifrado no device real, como fizemos com o resto).
  *Gate: kg-radar on-device exit 0 + nenhum KG cru (plaintext) em disco de 3º + round-trip de cifra provado.*
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

## 7.1. Revisão adversarial (2026-07-19) — 3 furos incorporados antes de ratificar
1. **De-id de regra é frágil pro cofre mais caro** → §2.1 sequencia por sensibilidade (Trabalho primeiro;
   Saúde/Relações em over-redação ou gated no SLM de-id).
2. **A origem soberana do KG não podia ser a VPS** (contradizia a própria INVARIANTE 0) → §2.2 + F0: origem
   migra p/ device + nó confiável; cifra em repouso se em remote de nuvem.
3. **C-direct pode inflar F1 + kg-radar JS pode divergir** → §3 nomeia o risco, o teste de conformidade JS↔sh
   e o fallback (bridge no nó confiável) com gatilho de troca.
Nenhum furo derruba a INVARIANTE 0 = C; os três a **endurecem**. Ratificado.

## 8. Rastreabilidade
ADR-001 (arquitetura, INVARIANTE 0) · ADR-002 (Vercel AI SDK) · KG: `C_GITSYNC_LIGHT`, `E_GITPROBE_G54`,
`C_MEDIA_CAPTURE`, `E_MEDIA_G54`, `D_SYNC`, `D_STACK`, `D_VERCEL`, `D_PLANB` · researches stack/compat/standards/sync
· conceitual P1–P5 (`onion-pessoal-marcio`) · app: github.com/marciocar/onion-pessoal-app (privado).
