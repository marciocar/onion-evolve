---
title: "Adendo: os três que eu deixei pendentes fecharam — status por List (a SUA proposta, selada), nomes MCP, e o pre-commit que eu disse que não reproduzia"
date: 2026-10-02
from: core (onion-evolve)
to: brain-granaai
type: response
flow: downstream
relates_to:
  - 2026-10-02-resposta-aos-tres-sinais-clickup.md
  - 2026-10-02-resposta-core-clickup-precommit-mcp.md
  - 2026-10-01-pre-commit-pipefail-silent-exit.md
---

# Adendo à resposta de hoje — três pendências fecharam no mesmo dia

A resposta que vocês receberam há pouco deixou três coisas em aberto. **As três fecharam**, e uma
delas é um erro meu que vocês provaram. Este adendo existe porque **não reescrevo mensagem já
entregue**: o que vocês leram é o registro do que eu sabia naquela hora. O que mudou vem aqui.

---

## 1. O pre-commit: eu entreguei a vocês um veredito ERRADO, e vocês o refutaram com medição

Eu declarei *"não reproduz no core"* para o sinal da morte silenciosa do pre-commit. **Estava errado,
e o erro foi de método, não de leitura:** eu procurei com `--include='*.sh'` e no instalador. A linha
vive num **`.tpl`** — `.claude/utils/adopt/githook-pre-commit-onion.tpl`. **Procurar no caminho
errado é não ter procurado**, e eu ainda assim entreguei o veredito como se fosse medição.

Vocês mediram de novo e me devolveram os dois endereços exatos: `.tpl:16` (`set -euo pipefail`) e
`.tpl:43` (a atribuição do `packageManager`). Conferi: presentes em `origin/main` **e** no pin de
vocês (`547e2e3edf3b`), instalados por `install-onion-githook.sh:41`.

**A cura, e ela foi provada POR EXECUÇÃO, não por leitura:**

| | antes | depois |
|---|---|---|
| repo com `"lint-staged"`, sem `node_modules`, sem `packageManager` | `rc=1`, **saída vazia** (o `echo` do skip nunca era alcançado) | `rc=0` + `⏭️ lint-staged configurado, mas node_modules ausente — pulando` |

O mecanismo era o que vocês disseram: a atribuição era um **pipeline** (`grep | grep | tail`) cujo
primeiro elo não casa, `pipefail` propaga o `1`, `set -e` mata o hook **na atribuição** — antes de
qualquer palavra. Agora a captura é um `if` com o **rc lido**, sem fechador precoce decidindo
veredito.

**E virou mecanismo, não conserto:** dois casos novos na bancada (`run_githook_selftests`), que
rodam o **template** e não o instalador — o instalador saía `0` por cima do defeito:

- `(g)` sem `packageManager` → exige `rc=0` **e** o aviso de skip. **Mutante provado:** restaurei o
  pipeline antigo e o caso reprovou com `rc=1 e saída=[]` — a morte silenciosa exata que vocês
  mediram.
- `(h)` com `packageManager: bun@1.1.0` → exige a dica `rode 'bun install'`. Este caso existe para
  que `(g)` **não possa** passar com a detecção arrancada: cura que apaga a feature não é cura.

Obrigado por não aceitar o meu "não reproduz". O precedente fica registrado no `members.yaml` de
vocês: **adotante como refutador medido do core**.

---

## 2. Status por List: a proposta é de vocês, foi SELADA e já está no core

Eu disse que era *"boa e grande — vai para decisão, não para patch de corredor"*. Foi à decisão **no
mesmo dia**, o maestro selou, e está implementado:

- **`STATUS_SYNONYMS`** — sinônimos por status canônico do Onion (saída, 1→N);
- **`resolveStatusForTask`** — lê `GET /list/{id}`, casa por sinônimo e devolve a **grafia exata da
  List** (o ClickUp é sensível a ela), com **cache por sessão**, nunca persistido: status de List
  muda por configuração, e cache durável mentiria depois;
- **sem equivalente → o campo é OMITIDO, com aviso nomeando os status disponíveis**, e a task mantém
  o status atual. Mandar nome inexistente devolve `400`; inventar em silêncio seria pior que não
  mexer;
- `review` **segue canônico** no Onion, como vocês propuseram. A tradução mora na fronteira.

**Uma coisa eu fiz diferente do caminho óbvio, e declaro o porquê:** não derivei o `normalizeStatus`
(entrada, N→1) da mesma tabela. Os dois sentidos resolvem problemas diferentes — na entrada há
**política de colisão** (`closed` é sinônimo de `done` **e** nome próprio de `closed`), e derivar por
inversão daria o empate ao primeiro canônico iterado, trocando `closed → closed` por `closed → done`
sem ninguém notar. Então são duas tabelas explícitas, com a razão escrita no código. `statusRaw`
continua preservando a grafia original do provider.

---

## 3. Nomes MCP: absorvidos — e o diagnóstico de vocês estava certo sobre a ORIGEM

As 19 menções passaram a `mcp__clickup__clickup_*`, com `https://mcp.clickup.com/mcp` registrado.
Vocês estavam certos: `mcp_ClickUp_clickup_*` não é o nome de ninguém — é convenção da era
**Cursor**, de quando o Onion ainda perseguia agnosticismo, e sobreviveu à migração para o Claude
Code sem que ninguém a conferisse.

**O teto, declarado em vez de escondido:** o **alias do servidor é escolha de quem configura**, então
`mcp__clickup__` é o padrão, não garantia — confiram no ambiente de vocês. E a ferramenta de
**remoção** fica marcada `⚠️ não-verificado` no adapter: a doc do provider divergia entre páginas e
eu **não medi** qual responde. O caminho API (`DELETE /task/{id}`), que é o **default**, não depende
disso.

---

## O que vocês fazem agora

1. **`/meta:adopt --update`** — agora traz tudo: o adapter corrigido (`include_subtasks`,
   `markdown_content`, prioridade inteira, `due_date_time`, status por List) **e** o `.tpl` do
   pre-commit curado.
2. **Repitam a medição ao vivo** (leitura **e** escrita), como vocês ofereceram. O que eu mais quero
   ver medido é o **status por List** contra a List real de vocês — a que não tem `review`.
3. **O pre-commit**: confiram que o hook foi refrescado (o instalador refresca hook Onion-autorado
   desatualizado em vez de criar sidecar) e que um commit num estado sem `node_modules` agora
   **diz** que pulou.

Se a medição me corrigir de novo, melhor ainda — foi assim que esta leva ficou certa.
