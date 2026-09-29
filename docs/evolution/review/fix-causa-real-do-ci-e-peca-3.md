---
title: 'Três diagnósticos meus estavam errados, e os três estavam a um comando de distância'
date: 2026-09-29
branch: fix/causa-real-do-ci-e-peca-3
reviewed_diff_sha256: 053b31a541e1de795ae98fa7c45201b845fbf5013d39860578dc3248ec23fd73
elenxo: nao
findings_total: 3
findings_real: 3
verdict: CORRIGIDO
tokens: 0
duration_min: 0
agents: 0
nota: 'SEM refutador, e a ausência é declarada com o motivo: os três achados são CORREÇÕES DE FATO obtidas por medição direta (HTTP 200 da chave, budget lido no painel, contagem no corpus, e o conteúdo real da SKILL), não teses que precisem de refutação. Quem reprovou aqui fui eu mesmo, medindo o que havia afirmado. A chave de API voltou a responder nesta sessão, então o refutador estava disponível — a escolha de não usá-lo é de proporção, não de impossibilidade.'
---

# Resíduo — os três diagnósticos errados, e o formato comum

## 1. A causa do CI morto: eu inventei "cota de Actions"

Atribuí o `startup_failure` à cota de Actions em **quatro dispensas de merge** (#882, #883, #884, #885)
e num resíduo. A leitura de billing falhava por falta de escopo `user` no token, e eu segui com o
palpite como se fosse fato.

**Medido em 2026-09-29:** o budget de Actions da conta tem **`stop usage: No`** e **$50,19 de $65,00** —
não bloqueia, e sem "stop usage" o GitHub apenas notifica por e-mail. A causa é **incidente de
plataforma do GitHub**: relatos independentes, de repositórios sem relação entre si, publicados em
26–27/09/2026, com padrão idêntico (`startup_failure`, zero jobs, nome de workflow vazio, sem runner,
sem logs, atingindo push/pull_request/workflow_run/schedule) —
[community #201113](https://github.com/orgs/community/discussions/201113) e
[#208832](https://github.com/orgs/community/discussions/208832).

Consistente com o local: **nenhuma mudança em `.github/workflows/` desde 25/09 16:06**, permissões
`enabled`, e os 5 YAML parseiam sob loader **estrito** — o `safe_load` que eu usara antes **aceita chave
duplicada em silêncio**, então meu "YAML descartado" original também não era descarte.

As cinco ocorrências foram corrigidas: o resíduo com o texto RISCADO no lugar, e os quatro PRs com
comentário de correção. Causa errada em registro de auditoria é dívida que alguém cita depois.

## 2. A chave de API: diagnostiquei "sem saldo" a partir de um cache em claro

O erro migrou de `400 credit balance too low` para `401 invalid x-api-key` e eu tratei os dois como
saldo. Na verdade: **o valor no `pass` sempre foi o bom**, e o `~/.anthropic-key` guardava uma cópia
velha, divergente do SSOT. Re-copiando do `pass`, `HTTP 200`.

Dois agravantes meus:
- **eu tinha uma memória própria** (`ci-anthropic-key-is-repo-secret.md`) dizendo que o CI usa o
  **secret do repo**, não a conta da sessão, e apontando `onion-review-diagnose.yml` como diagnóstico
  de um comando. Não a li antes de concluir;
- eu ofereci o comando de troca **por arquivo em claro** quando a casa usa `pass` — e o cache estava
  `-rw-rw----` numa VPS de 5 contas (agora `-rw-------`).

**Fio declarado:** o consumidor do `~/.anthropic-key` dentro do core é ZERO (varredura em `ops/` e
`.claude/`); quem o lê é `onion-vps-librechat/docker-compose.yml`, outro repo (I3 — não toco).
GATILHO para curar: a próxima vez que um diagnóstico depender desse arquivo, ele lê do `pass` ou o
arquivo deixa de existir.

## 3. A peça 3 do censo: quatro versões erradas do mesmo predicado

Eu procurava o **bloco medido no arquivo**. Ele nunca está lá: a superfície carrega
`` !`comando` `` e o **harness executa na carga**, injetando o resultado. O bloco de corpus que eu
"via" era o **renderizado na minha janela de contexto**, não a fonte — confundir a projeção com a
fonte é exatamente o que este censo existe para não fazer.

As quatro tentativas: (1) o título da seção — o próprio `forge.md` pontuava; (2) `bash <script>` em
qualquer lugar, que é passo de procedimento; (3) `**Hoje:` sozinho, linha digitável, e a passada
adversarial anterior provou o fantasma forjando-a; (4) data + versão juntas, que reprovou a instância
de referência. O predicado agora mede a **diretiva**, que não se digita — ela roda.

Efeito: peça 3 em **3 candidatos** (`onion-research`, `create-skill`, `onion`), fantasma digitado em
**0**, e a sandbox da bancada passou a usar a diretiva real — o harness espelha o artefato.

## O formato comum, que é o achado de verdade

Os três são a mesma coisa: **afirmei a partir do que eu imaginava, quando o que o artefato faz estava
a um comando de distância** — `pass show`, o painel de budgets, `grep` no próprio arquivo. Não é falta
de cuidado pontual; é a classe que esta sessão inteira exercitou, e o custo aqui foi cinco registros de
auditoria com causa falsa.

## Contrato de custo: a doutrina se corrige com medição

`forge-doctrine.md` citava **4,8%** (2 de 42 runs, medido 2026-08-06) como a métrica de falha do
contrato. Re-medido pela mesma régua em 2026-09-29: **22 de 111 = 19,8%**, quatro vezes mais. O
contrato PEGOU — logo a peça 5 não é invariante por ser a que mais falha, e sim porque destino sem
contrato não deixa série histórica. Razão de desenho, não de defeito.

## Gates

- `lint-artifacts.sh` → **0 HARD** / 16 SOFT (pré-existentes)
- `lint-selftest.sh --jobs auto` → **1513 ✓ / 0 ✗**
- mutante da peça 3 provado: predicado sempre-falso ⇒ `forge: (a)` vermelho nomeando `contexto`
- `/meta:realign` → ALINHADO em `fios-abertos` e no grafo da forja
- CI: incidente de plataforma (item 1). Merge pelo `--ci-inoperante`, agora com a causa **medida**

## Declarado aberto

- **Budget "All AI Credit SKUs" em $0 com `stop usage: Yes`** — bloqueia qualquer AI credit do GitHub.
  Não afeta o Actions; é bloqueio real de pé, e é do maestro decidir.
- **A divergência de `paths:` entre `git ls-files` e o matcher do harness** segue medida e **não curada**
  (4 formas, todas confirmadas por sonda: `*` não cruza `/`, braces expandem, escalar e flow-list são
  aceitos). A cura mexe em guarda HARD e o maestro ainda não selou o COMO.
