---
title: 'Spec do deck do Onion — os 9 atos, as 3 fases e a escada de dependência'
date: 2026-09-24
kg: docs/evolution/research/deck-patterns-2026-09/deck-patterns-2026-09.kg.yaml
artifact: https://claude.ai/artifact/Ceu8n8e7Xg7B5EAwmXFLxt
verified_at: '2026-09-24'
---

# Spec do deck — por que ela existe, e o que ela decide

O deck vivia **só como Artifact**, fora do alcance de qualquer guarda: sem lint, sem catraca, sem
resíduo. Para um framework cuja tese é *mecanismo verificável*, o material que apresenta essa tese
estar fora do mecanismo é contradição — e foi a pesquisa que a apontou. Esta spec é a **estrutura**
versionada; o Artifact é a **renderização**.

## A decisão, e o caminho errado que eu tomei primeiro

Rodada `deck-patterns-2026-09` (21 nós, radar exit 0), modo `decision`: **4 claims confirmadas
contra 24 refutadas**, e o padrão da refutação é de uma peça — **toda tentativa de afirmar ORDEM
caiu**: Diátaxis como escada, Rails Doctrine, os anéis do Thoughtworks Radar, a ordem da doc oficial
do Claude Code.

O grafo fechou com **sete opções nomeadas** (A–G) e uma recomendação do Elenxo. **A primeira versão
desta spec ignorou isso** e implementou a **opção (E)** — "aplicar literalmente os 4 achados" —, que
o Elenxo graduou **REPROVADA, confiança 0,1**, por três razões independentes, cada uma suficiente:
o objeto declarado não existia no repo; os "4 achados" eram **2 fontes contadas duas vezes**; e as
duas recomendações aplicáveis **já estavam implementadas** no deck medido (delta acionável = zero).

O erro tem nome nesta casa: agir pelo **resumo** em vez do que a pesquisa **decidiu**. Corrigido em
2026-09-24, no mesmo dia, depois de o maestro apontar.

## A ordem selada: opção (G) — fusão A+D+C, confiança 0,75

Três pernas com divisão de trabalho, que é o que faz ser fusão e não colagem:

**(A) dá a RETÓRICA e a espinha MEDIDA.** Nove atos *problem-first*, de
`docs/evolution/decks/iftl-frameworks-agentes-2026-08.html` (branch `docs/deck-iftl-rebased`,
52 slides, 18 `short:1`) — o **único** arco do conjunto que existe como artefato e **já rodou em
treino real**. A ordem dele faz o que nenhuma fonte externa soube recomendar: abre por **gancho**,
põe a tese-núcleo (**declarado ≠ verificado**) no **Ato 3** e chega à maquinaria só no **Ato 4**.

**(D) dá a LEI DE ORDEM**, e é a única autoridade sobre ordem verificada com arquivo e linha:
`onion-guided-lifecycle.md:51-52` → **Orient → Activate → Reinforce**; `:45` → "progressive
disclosure: 3 perguntas críticas + avançado adiado", que **é** o teto de 2 camadas da NN/g, já
dimensionado aqui e datado de jul/2026. Mais `onion-onboarding/SKILL.md:43-45`, a lei **"comece pelo
papel DELE"**, que resolve o público duplo com **dois caminhos declarados** em vez de um arco médio
que não serve nenhum. E `educational-design-guidelines.md` v1.3.0: 9 diretrizes vinculantes, a 2ª
ancorada em RCT peer-reviewed (Fan et al. 2025, BJET 56(2), DOI 10.1111/bjet.13544, N=117).

**(C) dá a ESCADA DE DEPENDÊNCIA técnica** — **memória → skills → hooks → agentes/SDK** — que é o
único candidato a responder *"qual é a relação progressiva quando os conceitos têm dependência"*.
⚠️ Entra como **HIPÓTESE**: as 3 claims tier 9 que a sustentavam foram **refutadas sem
contra-evidência**. A opção pode estar certa e a rodada não provou nada a favor dela.

## A estrutura

| fase | ato | slides | o que o ato faz |
|---|---|---|---|
| **ORIENT** | 0 · O gancho | 2 | o gargalo mudou de lugar: gerar é barato, **confiar é caro** |
| **ORIENT** | 1 · Os dois caminhos | 1 | contrato de navegação — aluno-adotante × equipe de cliente |
| **ORIENT** | 2 · De onde o Onion veio | 4 | identidade, três dimensões peer, Bulbo, verticais |
| **ACTIVATE** | 3 · Declarado ≠ verificado | 4 | **a tese-núcleo, ANTES do mecanismo que a sustenta** |
| **ACTIVATE** | 4 · A maquinaria | 11 | escada (C): onde manda → skills/agentes → hooks → Elenxo |
| **ACTIVATE** | 5 · Rodar o ciclo | 11 | a 1ª ação de valor: comandos, sessões, task manager, 3 ciclos |
| **ACTIVATE** | 6 · Adoção e federação | 5 | core → porta → adotante, branches, MCPs |
| **REINFORCE** | 7 · O conhecimento como estado | 22 | KB × KG, grafo por dentro, radar, orquestração, drive |
| **REINFORCE** | 8 · O que muda · Sua vez | 3 | fecha o laço do Ato 0, com 3 passos **por perfil** |
| **APÊNDICE** | Referência | 12 | consulta — **não se apresenta ao vivo** |

**Colorimetria por fase**, e ela é o contrato de navegação virando sinal visual (achado 3-0 da NN/g):
ORIENT âmbar `#D97706`/`#B45309` · ACTIVATE ciano `#22D3EE`/`#0E7490` · REINFORCE verde
`#34D399`/`#047857` · APÊNDICE violeta `#A78BFA`/`#7C3AED`. O chip no topo de cada slide carrega
`FASE · Ato N · assunto` na cor da fase — 71 dos 75 slides o têm (a capa, o gancho, o fecho e o
divisor do apêndice trazem o seu próprio por desenho).

## Contrato por slide

- **`tipo`** — `tutorial` | `how-to` | `reference` | `explanation`. Um slide, **um** tipo; slide que
  precisa de dois **vira dois**. (Divio 3-0 · Canonical 3-0: a prescrição é **separação**, não ordem.)
- **`fase`** — `orient` | `activate` | `reinforce` | `apêndice`.
- **`ato`** — 0 a 8, ou apêndice.

## O que a pesquisa NÃO sustenta, dito em vez de escondido

- **Nenhuma fonte confirmada fala de DECK.** Diátaxis é sobre documentação navegável; um deck é
  artefato **linear** que mistura tutorial e explanation no mesmo stream por construção — o que
  Diátaxis proíbe. Foi a razão nº 2 da reprovação da opção (E).
- **Nenhuma tem `validFrom` em 2025-2026**: Divio 2017, Canonical 2020, NN/g sem data.
- **O eixo mercado devolveu ZERO** — ausência de medição, não medição de ausência. A invariante
  *follow-the-money* não foi satisfeita nesta rodada.
- **Nada verificado cobre audiência dupla** no mesmo artefato. A solução aqui vem da casa (a lei
  "comece pelo papel DELE"), não de fora.

## Fios abertos, com gatilho nomeado

- **A perna (C) é hipótese.** Gatilho: leitura **integral** de `code.claude.com/docs/en/overview`
  (não snippet), ou uma rodada `primaries` com os 6 comparadores que o plano nomeou e não leu —
  Kubernetes, Terraform, React, Rails Getting Started, Docker, Stripe.
- **O gate (F) foi satisfeito por MEDIÇÃO, não por rodada nova**: a pesquisa afirmou que o deck de
  65 slides "não existe neste repo" e estava **certa** — ele existe como Artifact, que é o que ela
  não podia ver. O alvo real está identificado e versionado nesta spec.
- **Onde o deck de campo passa a viver** segue aberto: ele está em duas branches de `docs/`, nunca
  em `main`. Adotar (A) implica decidir isso.
- **Nenhuma guarda lê esta spec ainda.** Gatilho: quando ela e o Artifact divergirem a primeira vez,
  nasce a guarda de paridade — e não antes, porque catraca sem drift medido é cerimônia.
