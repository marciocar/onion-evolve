---
title: 'Radar E3 — rodada 5: a rodada aprendeu a não fabricar citação e passou a fabricar medição'
date: 2026-09-21
eixo: E3-claude-code-delta
baseline_anterior: '2.1.261 (2026-09-04, rodada 4)'
cc_version: '2.1.278'
kg: docs/evolution/research/radar-E3-2026-09-21-r5/radar-E3-2026-09-21-r5.kg.yaml
run_id: wf_cc748a90-4ca
tokens: 3581478
agents: 47
duration_min: 12
descartes: '2/41 no juiz da rodada · +11 na passada adversarial'
---

# O que esta rodada de fato descobriu

Não foi sobre o Claude Code. A passada adversarial **reprovou com 11 achados reais**, e o padrão que
os atravessa é este: **a rodada parou de fabricar citações e passou a fabricar medições do próprio
repo.** Essa é a entrega honesta desta página.

O delta de 15 versões (2.1.263→2.1.278) rendeu pouco, e o pouco está no fim. O que rendeu foi o
erro.

**Método e custo:** 6 eixos em fan-out (`sonnet/medium`) → juiz adversarial por achado
(`opus/high`, default REPROVADO): 47 agentes, 3.581.478 tokens, 12 min. Depois, refutador em
**worktree isolada** sobre o resultado — e foi ele que achou o que segue.

## O achado-manchete estava errado em versão, magnitude e conclusão

Eu escrevi que a **2.1.268** tirou as ferramentas de task do lineup do Onion, com **551 ocorrências**
dependentes, e propus declarar a variável de escape no repo.

Nenhuma das três coisas resiste:

| o que eu afirmei | o que a medição diz |
|---|---|
| desligamento na **2.1.268** | **2.1.233** — 35 versões antes, fora da janela (changelog l.1645) |
| **551** ocorrências (482+37+10+22) | **83 / 0 / 0 / 0** |
| superfície "nasce **morta e em silêncio**" | a ferramenta some; **o artefato roda sem erro** |
| propor religar a variável no repo | o corpus diz que *"religar por reflexo pode PIORAR"* |

As contagens vieram de `grep -rl … | wc -l` — que conta **arquivos**, não ocorrências — somando
`.claude/worktrees/` (cópias transitórias de **outros agentes**), com `TaskList` casando dentro de
`getTaskList`. O refutador mediu o comportamento que eu não medi: com a variável em `0` e `--model
opus`, `@mermaid-specialist` (que declara `TodoWrite` em `tools:`) **rodou sem erro em 8,9 s**.

E o corpus já sabia disso desde **2026-08-16**, medido por **dogfood** — sessão headless, opus-5,
`TaskList` → `TASK_TOOLS_AUSENTES` — com a conclusão oposta à minha: *"o FRAMEWORK Onion NÃO depende
disso"*.

**A causa tem nome e está no grafo.** A `research-lens` manda rodar `kg-corpus-grep.sh` antes de
qualquer busca. Não rodei — li o grafo da rodada 4 direto. O passo pulado não foi burocracia: foi o
que custou o achado.

Pior: **o juiz desta rodada acertou e eu descartei a correção**. O campo `correcao` em
`data/f1-scan-juizo.json` diz, verbatim, que *"o delta face à baseline não é o desligamento em si
(isso o corpus já mediu em 2.1.233)"*. Escrevi o nó **depois** dele. Juiz cujo veredito o escritor
pode ignorar não é gate — é opinião.

## Outros dois "achados" que não eram desta janela

- **`claude ultrareview`** existe desde a **2.1.111** (l.4082); o subcomando, l.3853. Não houve
  movimento do vendor contra o gate que esta casa ligou no dia 21 — houve **coincidência de
  calendário** com a minha descoberta tardia.
- **`claude respawn`** entrou no `--help` na **2.1.251** (l.1106). Estava disponível durante a
  sessão de 20/09 que tratou a deriva de versão como se não tivesse saída. O achado é de **uso**,
  não de delta: gastou-se uma decisão sua num problema que já tinha comando.

## O que sobreviveu à refutação

- **`E_TIMEOUT_AUSENTE_EM_7_HOOKS`** — 11 de 18 entradas de hook declaram `timeout`; **7 não**, e
  dois são os vetos `exit 2` de PreToolUse (`protect-main`, `merge-gate`). O refutador conferiu os
  sete nomes um a um. **É o melhor nó da rodada — e veio do juiz derrubando um achado.**
- **`auto-mode`**: 17 `allow` · 70 `soft_deny` · 1 `hard_deny` = 88 regras, confirmado no JSON
  commitado. O Onion tem 6 vetos `exit 2` entre 18 entradas / 15 scripts.
- **`E_EXIT_2_INALTERADO_NA_JANELA`** — o refutador varreu as 26 linhas com "hook" do delta: nenhuma
  altera o contrato `0/2/outro`. **Ausência medida, não suposta.** A capacidade que a doutrina diz
  comprar o acoplamento segue de pé por medição.
- Plugins (`--plugin-dir` multi-plugin, `plugin eval`), workflow (resume que falha explícito, pausa
  por limite de uso) e contenção de custo: **verbatim e na versão certa**.
- `data/claude-help-2.1.278.txt` é **idêntico** ao binário vivo; a baseline foi selada corretamente.

## Fica para o maestro (nó `D_E3_R5_O_QUE_FICA_PARA_O_MAESTRO`, aberto)

Duas das três decisões que eu havia proposto **caíram com os achados que as sustentavam**. Sobra uma,
e ela é real:

- **`timeout` nos vetos** — os dois PreToolUse que barram merge e commit em main herdam um default
  do vendor que esta janela mostrou ser terreno instável (mudou num patch). Virar guarda de lint, ou
  aceitar e declarar.

A decisão sobre task tools **não deve ser tomada com base nesta rodada** — o corpus já a analisou
melhor, e desaconselha religar por reflexo.

## Lacunas declaradas

`valid_from` ausente nos nós: o changelog local **não traz data por versão**, e datar por inferência
seria inventar o campo que existe para não inventar. Passo de corpus não executado como a lente pede
(e o preço disso está medido acima). `respawn` não testado em sessão interativa. Eixo mercado segue
sem sinal forte e concentrou metade dos descartes do juiz.
