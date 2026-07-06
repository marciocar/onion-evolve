---
title: 'ADR — Grana.Ai: onde o Onion se consolidou como potência (não a origem)'
date: 2026-07-06
type: adr
status: aceito — Fase 0 CONFIRMADA (2026-07-06); Fase 3 aguardando sinal de execução
decision-scope: meta / federação / confidencialidade / identidade
supersedes: none
deciders: maestro
context_freshness: 2026-07-06
confidentiality: INTERNO — não citar em site/materiais públicos até decisão explícita em contrário
related:
  - docs/evolution/federation/members.yaml (registro do membro granaai)
  - docs/knowledge-base/concepts/onion-dogfooding-doctrine.md
---

# ADR — Grana.Ai na linhagem do Onion

> **Correção de moldura do maestro (2026-07-06):** Grana.Ai **não é "a origem"** do Onion — é onde
> o framework **se consolidou como potência real**, provando que vai além de código: cuida de
> negócio e compliance junto com engenharia (as 3 dimensões peer da própria identidade do Onion,
> exercitadas juntas, em produção, numa fintech regulada).

## Contexto

Linha que permaneceu **separada** da federação até esta semana:

- **`onion-docs`** (branch em `GranaAi/granaai`, autoria **Marcio Carvalho**, 2025-10-03) — o
  próprio maestro já documentava a Grana.Ai com Onion há 9 meses.
- **`feature/onion-integration`** (Leonardo Melo, 2025-11-06) — "integração com o onion".
- **2026-07-01**: **Marcio Carvalho — CTO da Grana.Ai, criador do Onion e mentor do Onion
  Evolve — convidou Mauricio Matos a se conectar com o Onion Evolve.** A partir do convite,
  Mauricio baixou o core, adotou e organizou o repo da Grana.Ai a partir da própria máquina.

## Fatos verificados (read-only, via `gh api` — nada suposto)

- `GranaAi/granaai`: privado, ativo, produção real (app.grana.ai — fintech de crédito/
  antecipação de recebíveis, **domínio regulado**).
- Branches `onion/adopt` e `onion/granaai-ssot` compartilham o mesmo HEAD (`d70f06c26d`).
  `.claude/.onion-version` no branch confirma adoção real:
  ```
  framework: onion-evolve
  source_commit: 4332ac8d1884 (2026-07-01)
  role: adopted
  mode: regulated
  adopted_from: git@github-pessoal:marciocar/onion-evolve.git
  integration_branch: develop
  ```
- **O "onion delta" real é 13 commits** (não os 342 de divergência bruta do branch — esses
  incluem trabalho normal de produto de outros membros do time, Leonardo Melo/mauriciogranaai,
  já mergeado alhures). Os 13, todos de **Mauricio Matos em 2026-07-01, das 17h53 às 21h48
  (BRT)** — quase 4h contínuas:
  adoção → relatório de adoção → update de framework → lint fix → **sinal upstream** → Fase 0
  (baseline) → Fase 1 (28 dossiês) → Fase 2 (reconciliação técnica 19→45 apps) → Fase 3 (RFT-001
  piloto + 8 RFTs + ADRs 006-009) → Fase 4 (grafo do ecossistema) → Fase 5 (canonicalização SSOT).
- **Resultado da canonicalização** (relatório final lido do branch): 25 artefatos re-auditados,
  **24 CURRENT / 1 STALE** (falso-positivo de contagem em ADR-007, identificado e explicado pelo
  próprio processo — a mesma disciplina "declarado≠verificado" desta sessão); 9 ADRs + 8 RFTs
  regenerados; grafo do ecossistema (spec-as-code + Mermaid); stamp/alias 100% conformes.
  Coautoria: **Claude Opus 4.8 (1M context)** — sessão diferente desta.

## O achado que valida a doutrina: descoberta convergente independente

Mauricio reportou um **sinal upstream real**: `lint-artifacts.sh` tinha 13 guardas com `|| return`
(sem argumento) que, sob `set -e`, abortavam o script inteiro em máquina sem `jq` — o oposto da
intenção ("pula gracioso"). Ele aplicou o fix localmente (`|| return 0`) às **16h00 BRT**.

**Verificação no nosso histórico:** o commit `21842a5` (PR #215, "orchestrated audit + blocker
fixes") corrigiu **o mesmo bug, byte-a-byte o mesmo padrão**, às **23h41 BRT — 7h41min depois**,
sem qualquer comunicação entre as partes. Duas instâncias do mesmo framework, numa empresa e numa
sessão completamente desconectadas, convergiram no mesmo dia para o mesmo diagnóstico e o mesmo
fix. Confirmado via `git blame` — nada suposto.

## Decisões

### D1 — Moldura: consolidação, não origem
A Grana.Ai não é tratada como "berço" do Onion em nenhum material futuro — é onde o framework
**provou** as 3 dimensões peer juntas em produção regulada. Distinção vinculante.

### D2 — Confidencialidade: interno por enquanto
Nada deste ADR vai para `/historia/#origem` ou qualquer superfície pública nesta rodada. Reversível
no sentido publicar-depois; não no sentido despublicar-depois — por isso o default é conter.

### D3 — Reconciliação técnica: GATED até alinhamento humano — ✅ CONFIRMADA 2026-07-06
O branch `onion/adopt`/`onion/granaai-ssot` está **divergido** (342 à frente / 232 atrás do
`develop` real) e **sem PR aberto** — trabalho de valor real em risco de apodrecer. Fase 0
concluída: o maestro confirmou levar o trabalho adiante ("vamos refinar juntos"), e **Mauricio
Matos é o responsável por revisar/mergear no `develop`** real do time. A Fase 3 (cherry-pick,
já preparada e verificada sem conflito) aguarda só o sinal de execução — não mais alinhamento.

### D4 — Grana.Ai NÃO recebe `role: source` próprio
Pergunta do maestro: "a Grana.Ai deve ter seu core ou source?" — **Não.** Doutrina
[fonte≠derivação](../knowledge-base/concepts/source-vs-derivation.md) é explícita: existe **uma
só fonte** (`onion-evolve`, T0); duas fontes cria a pergunta sem resposta de qual doutrina vale
quando divergirem. O que a Grana.Ai tem, e que endereça a mesma necessidade sem violar a doutrina:
- **`.claude/` vendorizado já É "o core deles" no dia a dia** — o time nunca olha pro
  onion-evolve diretamente, só pro que está no próprio repo (verdade para todo `role: adopted`).
- **`integration_branch: develop` explícito** — controle deliberado de QUANDO puxar updates
  (nunca live-pull automático), o que um ambiente `mode: regulated` exige.
- **Trust elevado, não role elevado**: `can_correct_to: [onion-evolve]` adicionado — o achado do
  bug do lint (descoberta convergente, D-anterior) prova rigor técnico real; reconhecido como
  confiança, não como uma segunda autoridade de fonte.

## Próximos passos
1. ~~**Fase 0**~~ — ✅ CONFIRMADA 2026-07-06 (ver D3).
2. **Fase 3**: aguardando o maestro dar o sinal de execução (não mais alinhamento humano) — plano
   já pronto (cherry-pick dos 13 commits, zero conflito verificado).
2. **Fase 3** (pós-alinhamento) — **preparada, não executada** (ver detalhamento abaixo).
3. Considerar: uma vez reconciliado, criar canal de co-evolução real (inbox/outbox) para que
   sinais como o do lint não dependam de descoberta arqueológica — o próximo "sinal upstream" real
   deveria chegar em horas, não ser achado 5 dias depois numa investigação read-only.

## Fase 3 preparada (read-only, pronta para o dia que a Fase 0 destravar)

Verificado (`gh api compare onion/adopt...develop`): o `develop` real mudou **300 arquivos** desde
que `onion/adopt` divergiu — **zero** deles em `.claude/`, `docs/adr/`, `docs/rft/`,
`docs/technical-context/`, `docs/analysis/` ou `docs/INDEX.md`. Os **13 commits Onion-específicos
são cherry-pickáveis limpos**, sem conflito esperado.

**Estratégia recomendada** (a confirmar com Mauricio na Fase 0, não a decidir sozinho):
1. Branch novo a partir do `develop` **atual** (não do ponto onde `onion/adopt` nasceu — evita
   trazer os 232 commits já divergidos).
2. Cherry-pick dos 13 commits, na ordem: `1286bf91` → `ded5e31a` → `6989f73e` → `6e0f7445` →
   `629fd657` → `17b3cf7a` → `c26429c6` → `6618a750` → `f35ed0ea` → `069347c5` → `bd55eef3` →
   `27655e54` → `d70f06c2`.
3. **Re-verificar o ground-truth pós-cherry-pick**: a canonicalização mediu 45 apps/453 libs/34
   integrações no ponto de divergência; como `develop` andou 300 arquivos, esses números podem
   ter mudado — rodar a Fase 5 (canonicalização) de novo contra o código atual antes de declarar
   "24/25 CURRENT" válido no novo estado.
4. PR normal contra `develop` para revisão do time deles.

Nada disto foi executado — é plano pronto, não ação.

## Histórico
| Data | Mudança |
|---|---|
| 2026-07-06 | ADR aceito; linhagem registrada em `members.yaml`; reconciliação técnica gated |
| 2026-07-06 | **Fase 0 CONFIRMADA**: maestro decide levar `onion/adopt`+`onion/granaai-ssot` adiante; Mauricio Matos é o revisor/mergeador designado. **D4 nova**: Grana.Ai NÃO recebe `role: source` (doutrina fonte≠derivação) — recebe `integration_branch` explícito + trust elevado (`can_correct_to`) em vez disso. Fase 3 aguarda só o sinal de execução |
