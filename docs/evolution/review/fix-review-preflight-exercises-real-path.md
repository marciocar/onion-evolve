---
title: 'Resíduo — o pré-voo media a coisa adjacente, e por isso a falha chegava muda'
date: 2026-09-16
branch: fix/review-preflight-exercises-real-path
reviewed_diff_sha256: PENDENTE
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  PR de mecanismo, nascido de uma investigação com medição — não de leitura de código. As três
  hipóteses concorrentes foram REFUTADAS por execução antes de eu escrever a cura, e a que ficou
  não é "achei que fosse": é o que sobra depois que o repositório foi eliminado como causa.
  Sem Elenxo de refutador: o artefato é curto e as hipóteses já apanharam de medição.
---

# O pré-voo dizia 200 e o revisor morria em 413 ms

## O sintoma

`onion-review-verdict` reprovando o PR #836, com o revisor morto nas duas tentativas. A mensagem
que a maquinaria devolvia era `is-error` — e nada mais.

## O que eu medi antes de tocar em qualquer coisa

| sinal | valor |
|---|---|
| pré-voo em `/v1/models` | **HTTP 200** |
| sessão | inicializa (`Claude Code initialized`, `claude-sonnet-5`) |
| morte | **413 ms**, `num_turns: 1`, **`total_cost_usd: 0`**, `permission_denials: 0`, sem mensagem |

Custo zero com morte instantânea é a assinatura de uma chamada **rejeitada antes de faturar**.

## As três hipóteses, e as duas que a medição derrubou

1. **Hooks do core matando a sessão** — a action carrega `settingSources: user, project, local`, então
   os 14 hooks do repo rodam no runner. **REFUTADA:** os 4 de `SessionStart` saem `rc=0` em ambiente nu
   (`env -i`, `HOME` falso).
2. **`fallbackModel` em forma de array quebrando a partida** — o `settings.json` do core traz
   `["claude-opus-5", "claude-sonnet-5"]`, e a documentação fala em string. **REFUTADA:** rodei a CLI
   com esse settings e saiu `is_error: false`.
3. **A credencial do runner** — restou. Reproduzi a invocação **idêntica** (mesmos flags, mesma CLI
   2.1.273, clone raso da própria branch, settings e 14 hooks presentes) e saiu `is_error: false`,
   custo 0,26. **O repositório não é a causa.** Aqui roda na assinatura; lá, na `ANTHROPIC_API_KEY`.

## O defeito de mecanismo por trás — e é ele que este PR cura

O pré-voo existia desde 2026-08-04 justamente para converter "6 minutos de mistério em 1 segundo de
causa dita". Ele escolheu `/v1/models` **por não consumir tokens** — e é exatamente isso que o torna
mudo: listar modelos é uma leitura que uma chave sem saldo, ou sem permissão para o modelo do revisor
naquele workspace, responde **200 do mesmo jeito**.

É `behavior-over-declaration` dentro da guarda que existia para não confiar em declaração: ela
confiava no que um endpoint **adjacente** declarava, em vez do que o caminho real **faz**.

## A cura

1. O pré-voo passa a exercitar o **caminho real**: `POST /v1/messages`, mesmo modelo do revisor,
   `max_tokens: 1`. Custa fração de centavo e responde a única pergunta que importa — *"esta chave
   consegue rodar ESTE modelo agora?"*.
2. Ele **imprime o corpo do erro** da API. Provado com chave inválida:
   `{"type":"error","error":{"type":"authentication_error","message":"API key is invalid."}}` — a causa
   deixa de ser adivinhada. "Chave inválida", "saldo insuficiente" e "modelo não permitido no
   workspace" têm **consertos diferentes**, e antes as três chegavam como o mesmo silêncio.
3. O modelo do revisor vira **SSOT** (`env.REVIEW_MODEL`). Estava escrito duas vezes e a cura criaria
   uma terceira — e um pré-voo que exercita modelo **diferente** do que o revisor usa é pior que
   pré-voo nenhum: aprova o caminho errado.

## Teto declarado

O pré-voo prova que a chave **roda um turno**. Não prova que aguenta a revisão inteira: teto de
turnos, timeout e queda no meio continuam possíveis — e continuam cobertos pelo veredito
(`review-verdict.sh`), que lê `is_error` e distingue `error_max_turns` de crash. Este PR cura a
partida muda, não o percurso.

Também não conserta a causa do #836: **isso é do maestro**, no Console — saldo e permissão de modelo
da chave gravada no repo. O que este PR garante é que da próxima vez a guarda diga qual das duas.

## Defeito meu, pego no caminho

A primeira redação embutia um `python3 -c` de várias linhas dentro do bloco `run: |`. A indentação do
YAML quebrou em silêncio e o arquivo parou de parsear. Trocado por `tr`/`cut`. Guarda de sintaxe usada:
`yaml.safe_load` antes de commitar — a mesma classe que a bancada já registra para script embutido.
