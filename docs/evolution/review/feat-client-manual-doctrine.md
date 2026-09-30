---
branch: feat/client-manual-doctrine
reviewed_diff_sha256: 33328ed06270777d7a48627edb481f410439414a2e9d279809cb0e96ee3908fd
elenxo: sim
verdict: REPROVADO_E_CURADO
findings_total: 24
findings_real: 23
tokens: 187494
duration_min: 20
nota: "Refutador opus/high em worktree isolada, mandato REFUTAR, default REPROVADO. 4 BLOQUEANTES, 9 IMPORTANTES, 6 MENORES, 5 lacunas de cobertura. 23 confirmados por medicao propria e curados; 1 (sintaxe de allowed-tools) ele mesmo mediu e descartou como nao-achado. Dois bloqueantes eram invisiveis ao lint: o frontmatter que o gate nao lia e a busca que esvaziava a pagina."
---

# Resíduo da passada adversarial — doutrina de material para cliente

Refutador `opus`, mandato **REFUTAR**, default **REPROVADO na dúvida**, em worktree isolada. Veredito
dele: **REPROVADO**, e os quatro bloqueantes eram reais.

## Os bloqueantes

| # | achado | evidência que ele executou | cura |
|---|---|---|---|
| **B1** | o PR entregava **2 HARD**: editei a KB-fonte `onion-framework-identity.md` (107→108) sem regenerar o plugin que a empacota | `lint-artifacts.sh` → 2× REGRA 19; `diff` do plugin contra a regeneração mostrando o delta ser só do PR; `tree_sha` 21af228b0e76 × 311b27436e18 | `assemble-plugin.sh` — quem instalasse o plugin receberia "107 KBs" com o core em 108 |
| **B2** | a proveniência da doutrina era **link morto em 3 sítios** (`inbox/_processed/...` inexistente), e os artefatos declaravam "processado" enquanto o hook contava **2 não-lidos** | `ls` do caminho + `co-evolution-inbox-check.sh` | sinal movido para `_processed/`; hook agora conta 1, e os 3 links resolvem |
| **B3** | **o `verified_at` da KB era PROSA, não frontmatter** — a linha 1 era o título, não `---`, então o gate que a própria KB invoca não conseguia lê-lo | rodou o extrator literal de `doctrine-freshness.sh:230-241`: vazio na minha KB, `2026-07-23` numa irmã | frontmatter cercado com `---` |
| **B4** | a busca do esqueleto **esvaziava a página do cliente** ao digitar sem acento, sem mensagem e sem anúncio a leitor de tela | Chromium headless: buscar `duvidas` → 0 seções visíveis, `ariaLive: 0`, e o original tinha `norm()` pronto na l.1122 | `norm()` NFD + estado-vazio com `role="status"` e `aria-live="polite"` |

**O B3 teve efeito além deste PR**: eu havia preparado o `applies_to` recém-selado para as 3 KBs do
adotante **no mesmo formato inválido**. O achado salvou o campo de nascer invisível ao gate.

## O achado que não é bug, e é o que mais importa

A mensagem do commit afirmava *"o material já separava forma de domínio — 8 GENÉRICO contra 10
DOMINIO"*. Medido nos dois arquivos: o original tem **7 DOMINIO contra 2 GENÉRICO** — invertido. O "10"
era o total bruto de um `grep` lido como população. E a verdade **reforça** a objeção "N=1 não
generaliza" em vez de derrubá-la.

Pior: eu havia **afrouxado 5 seções** de DOMINIO para SEMIGENÉRICO/GENÉRICO **sem declarar** — o
esqueleto não evitou petrificar a primeira instância, ele relaxou o critério dela para parecer mais
reusável. Revertidas ao julgamento de quem escreveu o manual real; a única mudança que sobreviveu é
`acesso`, que subiu de GENÉRICO para SEMIGENÉRICO (mais rigor, e com razão escrita). A lição ficou no
topo do template, porque muda como se lê o artefato: ele é sobretudo **ordem e forma**.

A decisão do maestro sobre "padrão é melhor que sorte" não estava em julgamento e segue de pé — ela
não dependia daquele número. O defeito foi eu apoiá-la em medição que não existia.

## Importantes e menores, todos curados

- **I1**: declarei que o corte para 11 KB foi CSS, e **61 linhas de JS** (comportamento) saíram sem
  declaração — Copiar com fallback de seleção, tema com persistência, índice off-canvas, filtragem por
  linha. Portei o que é comportamento; o que fica de fora agora está **escrito** na KB.
- **I2**: `.copy` tinha CSS e zero handler; `:root[data-theme="dark"]` era ramo **inalcançável** (sem
  quem definisse o atributo). Os dois ganharam o código que faltava.
- **I3**: sem `@media print`, imprimir com a busca ativa saía **em branco**, com a barra lateral
  carimbada. Folha de impressão revela o que a busca escondeu.
- **I5**: a KB prometia capacidades que o esqueleto não tinha. Agora tem — e as **duas diferenças**
  (índice estático abaixo de 860 px; busca por seção, não por linha) ficaram declaradas.
- **I6**: `allowed-tools` não cobria o navegador headless da etapa 6 nem a fonte viva da etapa 2, e
  declarava `git`, que nenhuma etapa usa. Trocado por `WebFetch` + `node`/`npx`/`chromium`.
- **I7**: o comando que existe para resolver "o poder existe e ninguém alcança" era **ele mesmo
  inalcançável** — ausente do README da categoria e do guia de comandos. Registrado nos dois.
- **I8**: sobrou `93` Knowledge Bases **na mesma frase** em que eu atualizei 110→111. A REGRA 16 não
  cobre esse sítio.
- **I9 / N1 / N2 / N5**: a doutrina não declarava a tensão com `evidence-source-interest` (ela manda
  produzir, para o cliente, o enquadramento calibrado por interesse que a casa ensina a descontar) e
  não dizia **nada** sobre confidencialidade do material preenchido — NDA, git, link público —, que ele
  chamou de lacuna mais séria. Três cláusulas novas: confidencialidade, dever de avisar quando o
  limite é material, e rota de escape quando o cliente pede o que a doutrina proíbe.
- **M1/M2**: borda de controle em **1,37:1** contra o mínimo de 3:1 (WCAG 1.4.11), herdada do
  original; token `--edge` novo dá 4,40:1 e 5,44:1. `:focus-visible` restaurado.
- **M3**: `nota_de_transporte` inaugurava um **terceiro** vocabulário de chave de frontmatter no canal
  de sinais. Agora `transport_note`, em inglês, como o `code-standards` manda.
- **M4/M5**: carimbo `v0.8.8` igualado a `rc4` com a razão do escopo mais largo; fronteira de
  `output_path` declarada (dois comandos escreviam na mesma árvore sem dono).

## O que ele mediu e NÃO acusou

- **Zero vazamento** de nome de instalação do cliente do adotante: `SNCM` e `CD Serra` não aparecem no
  diff, nos arquivos novos nem no repo rastreado. O corpo do sinal **descreve** que a KB de origem os
  traz, sem reproduzi-los.
- As 13 seções do original estão **todas** mantidas (uma renomeada). O que se perdeu foi comportamento
  e critério, não estrutura.
- Sintaxe de `allowed-tools` por espaço: ele conferiu que 106 de 112 comandos da casa usam espaço, e
  **descartou** como não-achado. É o tipo de descarte que dá confiança no resto.
- As demais contagens (111 / 51 / 13 / 108, `docs/` 12, 30 fragmentos) batem byte a byte com o gerador.

## Notas de método

- **A bancada reprovou `review-ledger: (c)` na corrida cheia e passa isolada** (337 = 202+135+0) — a
  classe flaky já registrada nesta casa, de ambiente herdado, não regressão deste diff.
- O refutador declarou que a árvore principal **mudou sob ele** durante a revisão (eu regenerei o
  plugin enquanto ele media) e que só percebeu por reconferir a fonte autoritativa em vez do próprio
  snapshot. É o custo de revisar trabalho em curso, e ele o tratou certo.
