---
title: 'Resíduo — a doutrina não listava um repo público, e por isso não o protegia'
date: 2026-09-16
branch: docs/codex-is-a-live-line
reviewed_diff_sha256: 9be59d6d0a0b73c07b262d92b86ea2e7a9701e930461cb52348568758ad37770
findings_total: 10
findings_real: 10
findings_fixed: 10
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Mudança de DOUTRINA selada pelo maestro, não achado de revisão — por isso sem refutador: não há
  o que refutar numa decisão dele. Os três "achados" são fatos que a decisão obrigou a medir, e
  dois deles são omissões antigas que ninguém tinha visto porque ninguém tinha olhado a lista.
---

# Doutrina que não lista um repo não o protege

## A decisão

O maestro selou em 2026-09-16: **`onion-codex` é linha viva**, não congelado.

## Os três fatos que a decisão obrigou a medir

### 1. O repo nunca esteve na lista

O `CLAUDE.md` declarava a família como `onion`, `onion-cursor`, `onion-antigravity`,
`onion-copilot`, `onion-architect`, `onion-mini`, `onion-standalone`. O `onion-codex` **não
aparecia** — repo público, ativo, com 49 subagentes e 82 skills.

E a omissão não é cosmética. A REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente)
deriva os termos do `members.yaml` **e ignora nomes começados em `onion-`**. Um repo público com
esse prefixo, fora do registro, fica **sem varredura nenhuma** — é a migalha `vendor-scrub-blind-spot`
acontecendo em silêncio. Ele também **não está** no `members.yaml`; registrar segue pendente e é
ato de segurança, não burocracia.

### 2. "Linha viva" parecia revogar uma decisão de 2026-05-18, e não revoga

O `CLAUDE.md` declara, três linhas abaixo, que o multi-IDE foi *"formalmente abandonado em
2026-05-18"*. Deixar as duas afirmações lado a lado sem explicação seria plantar uma contradição
na constituição.

A diferença é de **objeto**: aquela decisão abandonou o **agnosticismo como direção de produto do
core** — parar de gastar energia em portabilidade para poder usar recursos de fronteira. Manter
**um** porte vivo é outra coisa: prova de portabilidade **executável**. O texto novo diz isso
explicitamente, para que a próxima leitura não conclua que uma linha cancela a outra.

### 3. A prova de portabilidade se pagou no primeiro dia

O porte revelou um buraco que o core não via: a REGRA 3 (Campo model: restrito à allowlist
sonnet|opus|haiku|fable) lê `model:` em **frontmatter** — e não enxergaria `model = "gpt-5.4"`
fixado em **TOML**, que foi exatamente o que quebrou o `@onion` lá. **Substrato diferente é o
único lugar onde se descobre o que a guarda do core assume sem dizer.**

Isto é o argumento mais forte a favor de manter o porte vivo, e ele é empírico, não retórico.

## Aufhebung no grafo

`C_CORE_NAO_E_FAMILIA` foi para `superseded` — **sem perder o label**, que continua correto sobre
o que era verdade em 2026-08-02. O nó novo `D_FAMILIA_TEM_DOIS_REGIMES_2026_09` carrega a decisão
e a aresta `SUPERSEDES`. Radar `--integrity --schema` exit 0 (93 nós / 108 arestas).

## Fica aberto

Registrar `onion-codex` no `members.yaml` — o que fecha o buraco da REGRA 36 (Superfície
VENDORIZADA sem nome comercial de cliente). Não entrou aqui porque mexe no registro da federação,
que tem validador e projeções próprias, e merece o seu próprio PR.

E o **contra-fluxo**: o `R-MODELO` que nasceu no porte não tem equivalente no core. Vira REGRA nova
aqui quando o maestro quiser — a lacuna está nomeada, não curada.

---

# Adendo — os dois fios fechados (2026-09-16, mesma branch)

## Fio 1 — `onion-codex` registrado

Entrada nova no `members.yaml` (17 membros, validador ✅), e com ela um **`kind` novo: `port`**.

Não usei `distillation`: destilação é reescrita curada da **mesma** doutrina no **mesmo** substrato;
porte é **tradução para outro substrato**. Chamar porte de destilação economizaria uma linha e
mentiria sobre o objeto — e é por **vocabulário**, não por lógica, que guarda de lista falha.
Projeções (`federation-map.md`, `federation-console.html`) regeneradas.

## Fio 2 — REGRA 83, o contra-fluxo

`REGRA 83 (Id de modelo VERSIONADO só na SSOT declarada)` — a guarda que **nasceu no porte** e o
core não tinha. Ela cobra versão literal de modelo em **configuração**, e declara três recortes:
prosa/KB que documenta catálogo de terceiro, **comentário** (registro histórico não é pin) e
**fixture** de bancada. As SSOTs onde o literal pode morar: `fallbackModel` no `settings.json` e
`env REVIEW_MODEL` nos workflows de review.

Achou e curou **2 pins reais** no `onion-review-diagnose.yml`, que repetia o modelo em vez de ler a
SSOT — diagnosticar com modelo diferente do que o revisor usa é diagnosticar outro sistema.

## Fio 3 (não pedido, mas era a causa de 4 reprovações no mesmo dia)

`regen-ssot-projections.sh` cobria `inventory.md` e `graph.md` e **não** `testing-state.md`. A
REGRA 81 (Painel de estado é GERADO dos produtores, nunca redigido) reprovou o CI **quatro vezes**
pela mesma causa. Quatro repetições da mesma correção é a definição de defeito que devia ser
mecanismo: o painel entrou na lista.

## A bancada me reprovou QUATRO vezes escrevendo esta guarda

Nenhum destes eu teria visto no olho, e os quatro estavam com a guarda escrita, plugada e "verde":

1. **O regex não casava NENHUMA forma real.** Exigia dois grupos numéricos e morria em `gpt-5.4`,
   onde o segundo é `.4`, não `-4`. Cobertura declarada e nula.
2. **`set -u` matou o lint no meio.** Ao curar a REGRA 60 (Identificador de código em INGLÊS) eu
   renomeei a variável no corpo e esqueci a do `read`. O lint morria na linha 2039 — e as guardas
   seguintes nem rodavam.
3. **`printf | grep -q && continue` sob `pipefail`.** Os dois filtros de falso-positivo não
   filtravam nada: o `grep -q` fecha cedo, o `printf` leva EPIPE, o status vira 141 e o `continue`
   não dispara. É a classe `pipefail-epipe-early-closer`, a mesma que me pegou no porte hoje.
4. **`find` cru em vez de `_find`.** O helper poda `.claude/worktrees/` e documenta a poda em dez
   linhas; eu abri varredura própria e passei a acusar o lint de **outra branch**. Guarda nova que
   abre a própria varredura herda zero calibração.

E a bancada da bancada: os casos (a)/(b) passavam com `--only` apontando para fora das raízes
varridas — mediam o **escopo**, não a guarda. Corrigido para apontar ao próprio mutante.

**Estado:** lint **0 HARD** / 12 SOFT · família `model_ssot` **4/4** · `members-validate` ✅ ·
registro de REGRAS regenerado (83 classificada em SSOT anti-drift).
