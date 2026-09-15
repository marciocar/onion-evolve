---
title: 'Resíduo — três medições, duas erradas, e a que quase apagou um defeito real'
date: 2026-09-15
branch: fix/adopt-docs-onion-mkdir
reviewed_diff_sha256: 2677a9c040e68146d1731806e6e9cecb1e4ea0e5a7345b23c4d6486b0bed31d5
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  O que domina este resíduo não é a cura do `mkdir` — é a CADEIA DE MEDIÇÃO. Um nó afirmava 4 HARD,
  um refutador mediu 0, eu re-medi e cheguei a 4 (confirmando o número errado por outro caminho), e
  só a simulação COMPLETA deu 0. Três medições, duas erradas, todas minhas. A quarta está rodando
  agora, em paralelo ao CI, com mandato explícito de dizer se a refutação apagou um defeito real.
---

# Três medições, duas erradas — e a que quase apagou doutrina do adotante

## A cadeia, na ordem em que aconteceu

| # | Quem | Resultado | Por quê |
|---|---|---|---|
| 1 | o nó (escrito ontem) | **4 HARD** | simulação parcial |
| 2 | refutador do PR #830 | **0 HARD** | seguiu mais passos |
| 3 | **eu, re-medindo** | **4 HARD** | **também pulei passos** — confirmei o erro por outro caminho |
| 4 | eu, simulação completa | **0 HARD** | o procedimento inteiro |

A #3 é a que dói. O maestro pediu re-medição **porque** havia divergência, e eu produzi uma terceira
medição que **concordava com a errada** — pelo mesmo motivo que a primeira estava errada.

## O que os 4 HARD eram

Artefato de simulação incompleta, e cada um tem um passo que o cura:

- **três ponteiros mortos** para `.claude/settings.json` → resolvem no **passo (1)** da Configuração
  pós-cópia, que **copia** o arquivo. Ele é rastreado no core mas **não viaja no manifesto**: quem o
  instala é o **procedimento**, não o transporte.
- **`research-lens.md` com glob que não casa** → carrega quando o **passo (2b)** roda o
  `starter-research-seed.sh`, helper que existe exatamente para isso.

## O fantasma mais caro

Eu estava a um passo de declarar **`research-lens` core-only** — tirando de todo adotante uma regra
que é **doutrina pura de framework** (corpus antes de busca externa, mercado invariante, tier de
fonte, bi-temporal, lacuna vira nó, grafo antes de prosa).

Teria sido uma cura que **remove capacidade** para resolver um defeito que **não existia**.

## A pergunta de desenho que isso respondeu

O maestro perguntou qual a diferença de o adotante ter ou não essas regras, e se as que devem ir
poderiam **se ajustar sozinhas**. A medição respondeu:

> **Regra path-scoped que deve viajar NÃO vira core-only quando o path não existe no destino — o
> transporte SEMEIA o path.**

E o mecanismo **já existia**. A tipologia completa do que viaja:

| Tipo | Como viaja |
|---|---|
| **Doutrina** (`research-lens`, `kg-grammar`) | com **semente** do path que a ativa |
| **Biografia** (diário, discussions, members) | **fora do manifesto** — allowlist falha fechada |
| **Config do alvo** (`settings.json`, `.env.example`) | never-clobber ou merge |
| **Licença** | **nome próprio** (`LICENSE-ONION`) |

## O defeito real que sobreviveu à refutação

O bloco (8)/(8b) redirecionava para `docs/onion/` **sem `mkdir`**, e o `|| true` engolia o
*"No such file or directory"* — o arquivo **nunca existia, em silêncio**.

**O bullet da Fase 3 TINHA o mkdir; o bloco shell NÃO.** O adotante nascia verde ou vermelho conforme
**qual metade do documento o operador seguisse**. Guarda cujo resultado depende de qual parágrafo se
leu não é guarda.

**Cura:** extraído para `regen-ssot-projections.sh` — uma implementação, um comportamento. A
REGRA 5 (Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal)) pediu
extração, e **a extração era a cura certa desde o começo**: 808 → **787** linhas, com folga.

## Curado junto, achado ao escrever a bancada

`_archive_staged` **não criava o destino** — o `tar` falhava, o `pipefail` propagava e a suíte
inteira morria com **exit 2**, sem somar nada. Sete chamadores dependiam de sorte.

## Bancada

Família `ssot_projections`, 5 casos, com mutante que prova o `mkdir` load-bearing:

```
(a)      alvo sem docs/onion → cria e gera
(a-MUT)  sem o mkdir o arquivo NÃO nasce e o erro é engolido
(b)      idempotente (o --update re-roda)
(c)      gerador que falha NÃO aborta a adoção (o "|| true" fica, e é deliberado)
(d)      o adopt invoca o helper, fora de comentário
```

⚠️ A fixture usa `_archive_staged` com a superfície vendorizada, **não** um `inventory.sh` pelado:
num sandbox sem `.claude/{commands,agents,skills}` o gerador sai rc=0 com **saída vazia**, e o caso
reprovaria por **fixture irreal** em vez de por defeito. Foi o primeiro erro ao escrever a família.

## Passada adversarial

Rodando **em paralelo ao CI**, com mandato explícito sobre a pergunta que importa: **o nó foi
corretamente refutado, ou a refutação apagou um defeito real?** Dado que três medições já
discordaram, o veredito dela entra neste PR — inclusive se for para **reabrir o nó**.

## Gate

```
bancada completa : 1242 pass · 0 fail · 0 skip   (1237 + 5 da família nova)
lint (LC_ALL=C)  : 0 HARD
radar / realign  : exit 0 / ALINHADO
nó               : REFUTADO com Aufhebung (evidência REFUTES; nada apagado), fora do backlog
commit           : SEM --no-verify
```
