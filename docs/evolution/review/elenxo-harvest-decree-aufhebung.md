---
title: "Elenxo — o decreto da colheita, e a derrubada da minha própria conclusão"
date: 2026-08-29
branch: elenxo/harvest-decree-aufhebung
reviewer: "Elenxo completo (5 etapas): 4 lentes CEGAS entre si + refutador com mandato de destruir e default REPROVADO; medições reproduzidas de forma independente pelo condutor"
reviewed_diff_sha256: 6c6a8aff5bc1123a98bd422663f2d31cb1af903ec26c7d93b844772a0e681f39
findings_total: 9
findings_real: 9
verdict: APROVADO
tokens: 480000
duration_min: 71
---

# Resíduo — REGRA 56 · Elenxo

Alvo: o **decreto da colheita** (*"colher = DELETAR; a história fica no git e no artefato de
revisão"*) — o único invariante da maquinaria **exercido sem nunca ter sido testado**. Quem o
exerceu fui eu, na colheita de ontem, declarando no próprio resíduo que não o validara.

## As 5 etapas, cumpridas

| # | etapa | como foi cumprida |
|---|---|---|
| 1 | fan-out de lentes **independentes** | 4 lentes, cada uma com eixo próprio, **cegas entre si** e instruídas a não se procurarem: doutrina · instrumento · prior-art · adversarial-de-forja |
| 2 | steelman | cada lente recebeu o melhor argumento do lado oposto no próprio prompt |
| 3 | **refutação adversarial** | worker com mandato de **destruir** a conclusão emergente, **default REPROVADO na dúvida** |
| 4 | síntese que arbitra por razão e **preserva dissenso** | o dissenso mais forte **contra a conclusão** virou nó `open` |
| 5 | `write(KG)` | 8 nós + 8 arestas em `fios-abertos.kg.yaml`; radar exit 0 |

## Veredito: SOBREVIVE EM FORMA MAIS FRACA

O refutador derrubou **4 das 8 evidências** e **2 dos 3 benefícios** da cura que eu propunha.

### O que caiu — e cada queda é contra mim

| evidência minha | veredito | medição que a derrubou |
|---|---|---|
| "colher mata o relógio de re-teste" | **CAI** | o relógio **não estava andando**: pré-colheita = **20 OK / 0 STALE**. `STALE-OLD` é relativo à `meta.baseline`, não ao tempo |
| "as teses que creditam o autor ficaram; os erros dele sumiram" | **CAI — era insinuação** | `C_RENAME_MATA_ANCORA_EM_SILENCIO` (um `C_` de erro do autor) **foi colhido junto**; e o arquivo tinha **zero nós `open`**. A regra foi "fechado sai, tese fica" e levou erro e crédito **uniformemente** |
| "o teto causou desvio de 1696 ids" | **CAI a inferência** | o `meta:` diz em caixa-alta *"NENHUM FATO NASCE AQUI"* — ids noutros grafos são o **desenho**. **Zero** evidência de alguém bloqueado |
| "o prior-art externo (ADR/RFC) condena" | **substituída** | o que vale é o **interno**: `git log --diff-filter=D -- '*.kg.yaml'` é **vazio**. Nenhum grafo jamais deletado; o único precedente é o marcador `archive` |

### O que sobreviveu — o dano real

**A promessa é METADE falsa.** O git cumpre a letra; o **resíduo de revisão não cumpre nada**. O da
colheita de ontem — que **eu** escrevi — nomeia **2 ids (os preservados) e zero dos 18 apagados**, e
**14 dos 18 conceitos não existem hoje em nenhum artefato consultável**.

### A cura mudou, e não é a minha

Descartado *"mover os nós para um `.kg.yaml` irmão"* — que era, inclusive, **erro de categoria**
(`git mv` move arquivos, não nós). Medido: preserva conteúdo, mas **não** preserva envelhecimento
(dilema fechado da baseline) nem arestas cross-arquivo (86%), e `archive: on` **já produziu o
cemitério previsto**: 319 nós **abertos** invisíveis à projeção humana.

**Cura escolhida:** *mecanizar a promessa que já está escrita* — o commit de colheita **emite os ids
colhidos com label** no resíduo. Gate sobre artefato que já existe; sem segundo grafo; sem inventar
relógio que o freshness provadamente não tem. Fica `open`, com gatilho: **a próxima colheita**.

## Dissenso preservado (etapa 4, obrigatória)

> **Arquivar troca uma perda que se SABE ter por um passivo que NÃO se sabe ter.** Deleção é perda
> visível, datada e auditável; arquivamento é retenção **sem consumidor, sem relógio e fora da
> projeção** — já medido nesta casa, com 319 fios abertos invisíveis. E reter os 18 poria uma onda
> **ENTREGUE** no topo do radar por puro grau: a régua deixaria de responder *"o que custa caro estar
> errado"*.

Fica `open` porque **não foi resolvido**. Quem retomar o decreto tem de enfrentá-lo antes de mexer.

## Erros meus registrados no caminho

1. **Aleguei "63% de um backlog era ruído histórico"** no steelman que escrevi para as lentes. Esse
   número **não existe**; a medição fundadora é **33%**, e o único "63%" do corpus é um que esta casa
   **já refutou como fabricado**. Alimentei uma lente com número inventado — o modo de falha exato
   que o decreto diz combater.
2. **Propus uma cura errada** e a defendi por duas lentes até o refutador medi-la.
3. **Escrevi o resíduo que prova o dano** — a metade vazia da promessa é obra minha, de ontem.

## Verificação

`kg-radar --integrity --schema` **exit 0** (14 nós, 13 arestas) · **REGRA 58 OK 14/20** ·
`realign --check` ALINHADO · `lint` **0 HARD** · `fios-abertos` segue **YAML válido**.

## Teto declarado

Um Elenxo **não** torna o decreto certo — torna-o **testado**. O decreto segue de pé na forma fraca, o
dano nomeado segue **sem cura implementada** (a decisão está `open` com gatilho), e o dissenso segue
**sem resposta**. Quem ler isto como "resolvido" está lendo errado.
