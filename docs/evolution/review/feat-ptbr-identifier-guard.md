---
title: 'Resíduo — a guarda da REGRA 60 tinha o mecanismo completo e o vocabulário vazio'
date: 2026-09-20
branch: feat/ptbr-identifier-guard
reviewed_diff_sha256: 4ba3ccc854b342177b4384b65066418a2a756acfa60d0b2363af83f111368a95
findings_total: 8
findings_real: 8
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Passada adversarial (opus, mandato de refutar, default REPROVADO) sobre o diff inteiro.
  REPROVOU com 7 achados reais, todos curados no mesmo PR. Dois deles atingiam a tese central:
  `ops/` estava fora do universo da guarda, e 13 identificadores pt-BR seguiam vivos DENTRO dele —
  o modo de falha que o PR alegava fechar continuava operando em escala menor.
---

# A guarda existia, estava ligada, e dizia zero

A **REGRA 60 (Identificador de código em INGLÊS)** tinha tudo: baseline com catraca no chão (zero
entradas toleradas), fail-loud se a lista sumisse, 7 casos de bancada, uma guarda-da-guarda contra
homógrafo, e estava ligada no lint desde 2026-08-09. Ela imprimia `0 HARD`.

Rodando o checker **novo** (153 termos) contra o `origin/main` **do mesmo dia**: **46 identificadores
pt-BR em 16 arquivos**. A lista tinha 102 termos e nenhum deles era palavra que aparece nos
identificadores deste repo.

| onde | quantos |
|---|---:|
| `.claude/validation/lint-selftest.sh` | 15 |
| `.claude/validation/lint-artifacts.sh` | 8 |
| `.claude/validation/review-verdict.sh` | 5 |
| `.claude/utils/adopt/vendor-manifest.sh` | 3 |
| `ops/**` (fora do universo) | 10 |
| outros 5 arquivos | 5 |

O custo tinha nome: enquanto a guarda gratuita dizia zero, o revisor semântico do CI achava esta
classe a **~US$ 0,80 o PR** — e o parecer dele é advisory, então o defeito era apontado, mergeado e
ficava. Pagava-se pela descoberta e não se recolhia a entrega.

## O que a passada adversarial derrubou

**REPROVADO — 7 achados reais**, todos curados aqui:

| # | achado | cura |
|---|---|---|
| 1 | 4 âncoras `sed` do harness citavam nomes renomeados → `command not found`; e 5 casos virariam **passes vácuos** com `2>/dev/null`, porque função ausente também produz `NAO` | âncoras corrigidas + montagem fail-loud + terceiro desfecho `SEM-FUNCAO:` + skip nomeado |
| 2 | `kg-read-index.tsv` não regenerado (REGRA 84, HARD) | regenerado |
| 3 | o `.kg.yaml` estava unstaged — o commit subiria o código sem o nó | staged |
| 4 | `ops/` fora do universo: 10 identificadores vivos, um deles com o segmento **já na lista** | universo consciente de papel + os 10 renomeados |
| 5 | 13 identificadores pt-BR ainda vivos DENTRO do universo, guarda ainda dizendo `0 HARD` | 9 segmentos novos (+flexões) e os 16 renomeados |
| 6 | caso (h) ancorava 10 de 13 segmentos — anti-encolhimento só no nome | ampliado para 22 |
| 7 | o `sed` do rename varreu uma linha de **prosa** pt-BR | restaurada |

## O que ela derrubou dos meus receios (medido, não argumentado)

- **Homógrafo**: os 32 termos da 1ª leva contra **2.684 identificadores de 235 scripts de sistema** e
  contra os 1.710 segmentos não-cobertos do repo → **zero colisões**. O casamento é por segmento
  exato, então `resto` não pega `restore`.
- **Contrato**: chaves de `$GITHUB_OUTPUT` (`revisou`, `motivo`, `turnos`, `custo`, `texto_chars`) e
  flags `--corpo`/`--texto`/`--selftest` intactas; `review-verdict.sh --selftest` 21/21 com os mutantes.
- **Caso (h) tautológico?** Mutado num sandbox (removi `viaja`+`nome`): o caso reporta exatamente
  esses dois como não-acusados e reprova.

## A exclusão também é vocabulário

O caso (g) proibia `nome` na lista **sem razão registrada** — não é palavra inglesa, entrou por
arrasto junto de `base`/`total`/`local`/`final`, que são. A prova do arrasto: `nomes` nunca foi
excluído. Guarda de lista falha pelo vocabulário nos **dois** sentidos, e o lado da exclusão é mais
silencioso porque parece prudência.

`todos` entrou na exclusão no lugar — e desta vez **com a razão medida ao lado**:
`effect@3.18.4`, `src/internal/fiberRuntime.ts:2186`, `let todos = Array.from(self).reverse()`, com 12
declarações inglesas num `node_modules` real. Teto declarado: o falso-positivo **não é alcançável
hoje** (a regra só lê `.sh`, e há zero `todos` inglês em 449 scripts de sistema desta máquina), mas o
critério do cabeçalho é sobre a palavra, não sobre o corpus do dia. O preço fica nomeado:
`lint-selftest.sh:5175` é pt-BR de verdade e a guarda não o cobra.

## A âncora de `sed` do harness mordeu TRÊS vezes — e virou mecanismo

O harness extrai predicados do runner por `sed -n '/^FUNCAO/,/^}/p'`. Neste PR, renomes mataram
**4 âncoras** de `role_scope` (via `lint-artifacts.sh`) e **2** de `kg_reconcile` (via `kg-radar.sh`).
O dano não é a quebra, é o **silêncio**: em `role_scope` os casos esperavam `NAO`, e função ausente
também produz `NAO` — só reprovaram porque o `command not found` sujou o stderr. Com `2>/dev/null`
seriam cinco passes vácuos sobre um predicado que não existe.

Não havia mecanismo conferindo âncora. Agora há: `selftest-lanes: (0)` extrai toda âncora das linhas
de **código** deste arquivo e exige que o símbolo exista em algum `.sh` de `.claude/validation/`.

**Duas rodadas de mutante acharam dois defeitos na própria guarda nova**, e nenhum por leitura:
1. o pote de busca incluía `lint-selftest.sh`, onde a linha da âncora **contém** o símbolo — a guarda
   se satisfazia sozinha e o mutante passava;
2. corrigido isso, ela passou a acusar `/^SIMBOLO/` — o placeholder do próprio comentário que a
   documenta. Extrator restrito a linhas de código.

## Defeitos meus que o próprio método pegou

- Renomeei funções em `lint-artifacts.sh` e deixei **7 referências órfãs** em `lint-selftest.sh`.
  Conferi ausência no arquivo que editei, não no repo — a lição diz exatamente o contrário.
- O `sed` do rename contaminou prosa pt-BR **duas vezes** (`# case_name | args…` e
  `O comentário nomeia O CHECK, o REASON e o HEAD`). Varredura de comentários alterados virou passo fixo.
- Primeiro extrator de identificadores era **cego nos dois casos conhecidos** (`_viaja`,
  `_PAPEL_DESTE_REPO`): só via `local X=` e `foo()`. Guarda cega justamente no que motivou construí-la.

## Declarado, não absorvido

- **2 HARD pré-existentes** (portas públicas por re-materializar, **REGRA 85 (Porta pública espelha o
  core, com catraca)**) falham idêntico em `main` e são local-only — o CI não as vê.
- `rules-registry: (f)` falha em `main` também, por estado local (grafo `vaultwarden-logto` vencido em
  09-09, deriva Claude Code 2.1.276→2.1.278).
