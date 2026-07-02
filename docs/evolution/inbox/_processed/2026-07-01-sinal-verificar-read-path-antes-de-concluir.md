---
title: 'Sinal de campo — disciplina de auditoria: verificar o read-path no código antes de concluir sobre dados'
date: 2026-07-01
from: rhilo-metagamify (adotante standalone)
to: onion-evolve (core / "mestre")
re: padrões de frota/exploração (onion-fleet, Explore) e verificação adversarial em auditorias data-driven
type: federation-doc-bridge (sinal de método — não-solicitado)
status: aprendido em campo numa auditoria real (integração RHILO↔MetaGamify); memórias locais gravadas; proposta de promoção ao core
---

# Sinal de campo ao core — "verifique o read-path antes de concluir" (2026-07-01)

> Doc-bridge derivado→core. Não é bug de framework: é um **padrão de método** que uma auditoria real
> expôs e que vale endurecer nos guias de frota/exploração do Onion. Modo `standalone`: o core consome
> quando rodar a co-evolução do seu lado.

## Contexto (o problema real que revelou o padrão)

Numa auditoria de um deploy quebrado (Modo Equilíbrio do WRR), rodamos uma **frota de ontologia**
(5 agentes Explore paralelos) + forense de git + forense de banco (túnel read-only). O objetivo era
achar por que "o que foi testado" divergiu de "o que subiu".

Durante a forense de banco, quase cravamos uma conclusão **falsa**: *"a config da journey está vazia —
sem doseControl, sem monthlyDefaults"*. A conclusão veio de consultar a tabela de nome óbvio
(`WRRJourneyConfig`), que de fato estava quase vazia e congelada há um mês.

**O motor não lê essa tabela.** O caminho vivo do `decide()` lê **outra** tabela (`Journey.config`,
com `as any`, sem passar pelo cache/validação). Nessa, a config estava **completa**. As duas coexistem
e divergem ("split-brain"). A conclusão certa não era "config vazia" — era "há duas fontes e o motor usa
a que ninguém audita".

O que evitou o erro: **parar e rastrear no código de onde o runtime lê o dado** antes de concluir a
partir do banco. Um resumo anterior de um agente de exploração havia afirmado a tabela errada como
"fonte de config"; seguir essa afirmação sem verificar teria produzido um veredito de auditoria errado.

## O padrão (generalizável, não específico do WRR)

> **Regra:** numa auditoria data-driven, a afirmação de um agente sobre *onde um dado vive* é uma
> **hipótese** até ser confirmada contra o **read-path real no código**. Antes de concluir a partir de
> um store (tabela, arquivo, cache, env), rastreie qual caminho de runtime efetivamente lê aquele dado
> na operação sob auditoria — e consulte **esse** store, não o de nome mais óbvio.

Corolários:
- **Split-brain é comum e invisível:** quando existe uma camada "nova" (repo + cache + validação) e um
  caminho "legado" que lê o store cru, eles divergem em silêncio. Auditar só o novo dá falso-verde.
- **Resumo de sub-agente ≠ evidência:** o que uma frota reporta como "fonte de X" entra no dossiê como
  *claim a verificar*, com citação `arquivo:linha` do read-path — nunca como fato herdado.
- **Verificação adversarial vale para dados, não só para código:** o mesmo hábito que aplica-se a
  "esse achado de bug é real?" aplica-se a "esse número do banco significa o que eu acho?".

## Proposta de promoção ao core (radar: `assess` → `trial`)

1. **`onion-fleet` / guias de exploração:** acrescentar ao contrato do agente extrator uma coluna/etapa
   obrigatória **"read-path verificado (arquivo:linha)"** para toda afirmação de *localização de dado*.
   Sem isso, o item nasce marcado como hipótese, não como nó confirmado.
2. **Padrão de auditoria data-driven (KB/patterns):** documentar o "verify-the-read-path-first" como
   padrão nomeado, com este caso como golden (o antipadrão: concluir a partir da tabela de nome óbvio).
3. **Checklist de síntese de frota:** o sintetizador deve sinalizar quando dois extratores (ou um
   extrator e o banco) discordam sobre a fonte de um dado — divergência de fonte é achado, não ruído.

## Evidência (neste adotante)

- Read-path vivo: `apps/api/src/services/wrr-distribution.service.ts:2596` (`getJourneyConfig` lê
  `Journey.config` com `as any`) → consumido em `:408`→`:773` (`decide(decisionInput)`); o serviço
  **não** importa `JourneyConfigRepository`.
- Store paralelo não-lido pelo motor: `WRRJourneyConfig` (usado só por `wrr.routes.ts`,
  `wrr-admin.routes.ts`, scripts) — em HML, `version 1`, `updatedAt 2026-06-02`, sem dose/monthly/share.
- Registrado no dossiê da auditoria: `docs/rhilo/07-ontologia-integracao.md` (ponto de auditoria P1-9)
  e nas memórias de projeto `wrr-flag-suffix-mismatch`, `wrr-override-reset-intencional`.
