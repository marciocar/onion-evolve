---
date: 2026-07-19
instance: onion-evolve
type: innovation
classification: collective
tags: [onion-pessoal, onion-pessoal-app, f1, core-loop, chat-kg, kg-radar, multi-runtime, de-id, privacy, local-first, zero-knowledge, byok, hermes, dogfood]
affects: [engineering, product]
breadcrumb_for: []
share_with: []
next_recommended: "F1 quase fechado no onion-pessoal-app (só falta STT). PRÓXIMO substantivo antes do STT: GESTÃO DE PROMPTS do cérebro seguindo os NOSSOS conceitos — KG-SSOT-first + runtime (o prompt vive num SSOT, o runtime lê e verifica-contra-o-vivo) + dogfood (usar de verdade) + o padrão de mgmt de prompt mais popular/adotado de jul/2026 (verify-external antes de escolher). Hoje o prompt está hardcoded em llmAnthropic.ts — dívida consciente. Depois: STT (última peça F1) → então F2 (superfície + SSOT 6-camadas de inferência/P5, onde Q_METADATA_LEAK e o de-id-por-SLM moram). O app É o cliente KG-de-vida canônico (ver adopt-kg-life-g1-spike: adopt-para-KG NÃO se constrói)."
review_after: 2026-10-19
conflict_class: static
---

## Signal
O **onion-pessoal-app** (companheiro de vida, estrela `discuss/onion-pessoal-app`) saiu de PARK e teve o **F1
construído e provado no aparelho REAL** (Moto G54, Expo Go SDK 57, sem dev build), num único dia de dogfood
device-side. Registro aqui para a **sessão principal / Transformer** saberem o estado e a direção — o registro
técnico vivo é o KG da estrela (`research/stack-research-2026-07.kg.yaml`, radar exit 0).

## O que foi construído (todas as peças VERDES no G54)
- **F0 (fundação de dados):** cifra-em-repouso (XChaCha20-Poly1305 + scrypt via `@noble` — `age-encryption` JS
  usa Web Streams inviáveis no Hermes), **life-KG runtime-grade** (YAML sob Hermes provado), **sync** a um GitHub
  privado **zero-knowledge** (`marciocar/onion-pessoal-kg`, só ciphertext sobe).
- **F1 (motor privado):** **kg-radar JS** (gate de escrita D6), **de-id LOCAL**, e o **CORE LOOP** ponta-a-ponta
  com **cérebro REAL** (Anthropic direto, BYOK, sem tocar a VPS): `read(KG) → de-id → cérebro-cego → restore →
  radar-gate → write`. Teste geral de 2 turnos (chat↔KG): o KG cresce, o contexto carrega, o espelho responde
  com continuidade, e **a PII nunca sai** (o cérebro vê só tokens `[TERM_1]`; o KG em repouso é cifra).

## Aprendizados que TOCAM a doutrina do core (já sinalizados via inbox, o core respondeu)
1. **kg-radar multi-runtime — ABENÇOADO** (KB `knowledge-graph-sdaal` §Multi-runtime): o `.sh` é AUTORIDADE
   ÚNICA; delegar quando o runtime permite, **porta conformance-gated** quando PROÍBE (Hermes/on-device); o
   teste **JS↔sh** é o gate anti-drift. Refina `D_LOCAL_VALIDATOR_DOCTRINE`.
2. **Perfil leve de KG SANCIONADO** — mas **drive-to-verify** contra o `.sh` VIVO pegou que ele AINDA reprova
   `impact`+`status` ausentes (só `confidence`+`layer` são de fato opcionais). O store auto-preenche os
   obrigatórios (captura leve: user dá `id/node_type/label`). **E achei um bug no meu port**: reprovava
   `confidence` ausente (NaN) — o `.sh` aceita (0=válido); corrigido, conformance 8/8. **Lição:** a porta só é
   segura pelo conformance contra o VIVO, não pela leitura da doutrina.
3. **`Q_METADATA_LEAK`** — nossa cifra-de-conteúdo deixa metadados (msg/grafo/timestamps/**frequência** de commit)
   vazarem no remote; `git-remote-gcrypt` (whole-repo) fecha. É **doutrina do core → F2** (SSOT de mitigação de
   inferência/P5), **documentar não construir agora**. Prior-art destilado em `E_SYNC_PRIOR_ART`.

## Por que importa (o encaixe no todo)
A invariante-mãe se sustentou ponta-a-ponta num device real: **o dado mais sensível que existe (saúde/casamento)
é estruturado por IA de nuvem sem que a IA veja um byte de PII crua**; o KG soberano vive cifrado no aparelho.
Isso é a prova viva de "soberania por cifra" + "de-id LOCAL sempre" do ADR-003 (INVARIANTE 0 = C). Valida que
o Onion pessoal N=1 tem superfície executável — o loop coletar→KG→reconciliar deixou de ser Wizard-of-Oz.

## Dívida consciente (para não fingir que está pronto)
- **Prompt do cérebro hardcoded** (`llmAnthropic.ts`) — próximo passo é gestão de prompts KG-SSOT-first + runtime
  + dogfood (nota do maestro).
- **de-id é regra v1** (frágil por design; SLM on-device é F3/gated). Verticais sensíveis (Saúde/Relações) em
  over-redação; começa por Trabalho.
- **Push on-device flaky** (RN fetch + isomorphic-git `EmptyServerResponseError`) → retry com backoff; fix mais
  fundo = trocar o http client por `expo/fetch`.
- **STT** ainda não existe (última peça do F1).
