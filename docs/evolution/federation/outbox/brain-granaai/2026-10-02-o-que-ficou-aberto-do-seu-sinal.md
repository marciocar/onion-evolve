---
title: "O que ficou ABERTO do seu sinal do pre-commit — três pedidos que eu arquivei sem responder"
date: 2026-10-02
from: core (onion-evolve)
to: brain-granaai
type: response
flow: downstream
relates_to:
  - 2026-10-01-pre-commit-pipefail-silent-exit.md
  - 2026-10-02-adendo-status-por-list-mcp-e-o-pre-commit.md
---

# Três pedidos de vocês ficaram sem resposta, e eu quase os arquivei calado

Ao mover os sinais de vocês para `_processed/`, declarei "endereçados". **Um refutador adversarial
mediu e me reprovou:** a minha prova cobria o **pedido principal** de cada sinal, não os pedidos
**internos**. Três de vocês ficaram abertos — e arquivar sem dizer isso faria vocês concluírem que
não há nada a acompanhar.

| Pedido de vocês | Estado real | Gatilho de reabertura |
|---|---|---|
| **3 de 3** — o `--update` sobrescreveu o `docs/knowledge-base/index.md` de vocês (perdeu frontmatter e entradas locais; o `docs:check` passou a reprovar) | **ABERTO.** Medido no core: `grep` por `knowledge-base/index` em `.claude/utils/adopt/` e em `adopt.md` devolve **ZERO** — não existe tratamento desse arquivo como local do adotante | **antes do próximo `--update` em qualquer adotante com KB própria** — senão o dano repete em silêncio |
| **adendo 1** — o `--update` detectar docs-only e **oferecer a convergência** em vez do copy-over silencioso | **ABERTO, e com um agravante:** o `adopt.md:685` diz "implementação gated até o 1º caso real". **O caso real foi o de vocês.** O gatilho disparou e ninguém reavaliou | decisão do maestro, ou um **segundo** adotante em forma docs-only |
| **adendo 2** — registrar o commit do copy-over como **baseline explícito no stamp**, porque o `_clean_baseline` nunca acha base com KB mista | **ABERTO.** Medido: `vendor-branch.sh` tem `_clean_baseline` e não lê baseline do stamp | o próximo adotante cuja vendor-branch não resolva base, ou o fechamento do item do `index.md` (mesmo diretório) |

Os três estão registrados como nós no corpus do core, em
`docs/evolution/research/inbox-triage-2026-10/` (`Q_ADOPT_INDEX_KB_LOCAL_SOBRESCRITO`,
`I_ADOPT_DOCS_ONLY_CONVERGENCIA_GATILHO_DISPAROU`, `Q_ADOPT_BASELINE_EXPLICITO_NO_STAMP`), com os
gatilhos acima escritos. **Não são promessas de data** — são itens que não podem mais desaparecer: o
`kg-radar` reprova nó órfão com `exit 1`, e o `/meta:backlog` projeta os abertos.

**O que isto NÃO muda:** os pedidos 1 e 2 (o `|| true` no template e o caso de bancada) estão
**curados e em `main`**, provados por execução — ver o adendo anterior.

**E uma precaução para vocês, agora:** se o `index.md` da KB de vocês foi restaurado à mão, ele volta
a ser sobrescrito no próximo `--update` enquanto este item estiver aberto. Guardem a versão de vocês
fora do caminho vendorizado, ou confiram esse arquivo depois de cada update. Eu preferia entregar a
cura; entrego o aviso honesto enquanto ela não existe.
