# Linguagem Simples por superfície — a régua que o Onion segue quando um humano lê

> **Versão**: 1.0.0 | **Última atualização**: 2026-11-21 | **Categoria**: Conceitos
> Onde uma pessoa lê o texto (o maestro, quem lê a documentação, o commit, o card, o público), o Onion
> escreve em **Linguagem Simples**, segundo a norma ABNT NBR ISO 24495-1:2024. Onde só uma máquina ou outra
> sessão lê, a régua não se aplica, exceto a glosa de sigla. A régua tem 11 itens, cada um com o sinal que
> mostra se foi cumprido.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-11-21 |
| **Última Atualização** | 2026-11-21 |
| **Categoria** | Conceitos |
| **Origem** | Pedido do maestro em 2026-11-20: seguir a Linguagem Simples ABNT no ecossistema. A curadoria dissecou a norma, e o core selou o veredito **costurar** |
| **Grafo** | `docs/onion/graph/coordenacao-selos-arquivo-2026-11.kg.yaml` (decisão `D_PLAIN_LANGUAGE_STITCH_1121`). A dissecação mora no repo da curadoria: `docs/evolution/dissect/linguagem-simples-abnt-2026-11/` (veredito proposto `D_LS_VERDICT`, régua `C_N1_REGUA`) |
| **Padrões-irmãos** | Skill `language-standards` (idioma e tom) · glossário da casa (`.claude/validation/house-codes.tsv` e o hook `house-code-gloss.sh`) · [triagem de achados de revisão](../../../.claude/commands/common/prompts/review-triage.md) |
| **Revisão** | Pendente do maestro: o selo foi dado pelo core a pedido direto dele. Se ele discordar, a decisão se refaz |

---

## 1. O que muda

Nada de gate pesado. A norma entra por **costura**, ligada ao que o Onion já faz:

1. **Esta régua**, para quem escreve e para quem revisa. É doutrina, sem bloqueio.
2. **A glosa de sigla** (uma sigla da casa vem explicada na primeira menção) vai além da resposta ao maestro
   e chega ao corpo do commit e aos sinais entre sessões. Isso muda um hook e por isso vai num PR de guarda
   à parte, que o maestro aprova. Até ele entrar, a glosa nessas superfícies é doutrina, sem lembrete
   automático.
3. **Um item opcional na triagem de revisão**: em texto que um humano lê, o revisor pode apontar o problema
   de clareza como **LIMITE**. Limite é achado real que não segura o merge.

## 2. A norma, em uma tela

A norma é a **ABNT NBR ISO 24495-1:2024, Linguagem Simples, Parte 1: princípios e diretrizes** (1ª edição,
25/07/2024). É a adoção idêntica da ISO 24495-1:2023. Ela vale para documento em texto lido por pessoa e não
cobre acessibilidade, que é assunto da WCAG (Web Content Accessibility Guidelines) e da EN 301 549.

A norma diz que um documento está em Linguagem Simples quando o leitor **encontra** o que precisa,
**entende** o que encontrou e **usa** essa informação. Ela organiza isso em quatro princípios:

| Princípio | O que pede (paráfrase) | Seção |
|---|---|---|
| **Relevante** | o leitor e o que ele precisa vêm primeiro | §5.1 |
| **Localizável** | a estrutura leva o leitor ao que procura | §5.2 |
| **Compreensível** | palavras, frases e parágrafos que o leitor entende | §5.3 |
| **Usável** | o documento é avaliado e muda quando a realidade muda | §5.4 |

A lista de verificação da própria norma está no Anexo B (Tabela B.1).

> **Direito autoral:** a norma é protegida. Aqui só há paráfrase e o número da seção. Não se copia o texto
> dela nem se guarda o PDF no repositório.

## 3. A régua

Cada item tem a forma **"em tal superfície, verifique tal coisa; o sinal é tal; a seção é tal"**. O sinal é
como se mede.

| Item | Verifique | Sinal de que foi cumprido | Seção |
|---|---|---|---|
| **R1** | o resultado ou a decisão está na 1ª linha, antes de qualquer contexto | a 1ª linha diz o desfecho | §5.1.6, §5.2.2 |
| **R2** | todo bloco ajuda o leitor a decidir ou agir | não há bloco que se possa cortar sem perda | §5.1.6 |
| **L1** | o título diz o que o texto contém; três itens ou mais viram lista | título descritivo; lista presente | §5.2.2 a §5.2.4 |
| **L2** | o detalhe longo fica em nota, apêndice ou link | o corpo principal lê-se sem ele | §5.2.5 |
| **C1** | sigla ou termo especializado vem explicado na 1ª menção | medido pelo glossário da casa (hook) | §5.3.2 |
| **C2** | uma ideia por frase, na voz ativa | frase com duas ideias ou mais pede revisão | §5.3.3, §5.3.4 |
| **C3** | um assunto por parágrafo | o parágrafo cabe num título | §5.3.5 |
| **C4** | tom respeitoso, trato por "você", linguagem inclusiva | sem tom de ordem seca nem jargão de grupo | §5.3.3, §5.3.7 |
| **C5** | a ligação entre as partes está clara ("por isso", "mas", "então") | o leitor não precisa adivinhar a relação | §5.3.8 |
| **U1** | texto de uso longo tem data de revisita e sai quando a realidade muda | `review_after` ou cadência declarada | §5.4.4 |
| **U2** | na dúvida alta sobre o que o leitor precisa, pergunte a ele | pergunta ao maestro com opções | §5.4.3 |

## 4. Onde a régua vale

| Superfície | Força |
|---|---|
| Resposta ao maestro | **toda a régua** |
| Documentação em `docs/` (KB, síntese de estudo, README) | **toda a régua** |
| Commit (assunto e corpo) e descrição de PR | **toda a régua**; R1 e C1 pesam mais |
| Card do task manager e comentário nele | **toda a régua** |
| Superfície pública (as portas, os anúncios) | **toda a régua** |
| Instrução de comando, agente ou skill | **R1, L1, C1, C2**: o leitor é modelo, mas uma pessoa também lê |
| Mensagem entre sessões, sinal de inbox | **só C1 e U1**; o resto é opcional |
| Tráfego de máquina (JSON, TSV, log, saída de script) | **fora da régua** |

### Por que o tráfego de máquina fica de fora

A norma foi feita para leitor humano, e boa parte do tráfego do Onion é de máquina: uma sessão lê o sinal de
outra, um script lê o TSV de outro. Ali a régua custaria sem trazer ganho. A curadoria registrou essa
objeção (`E_OBJECAO_TRAFEGO_MAQUINA`), e ela **restringe** o escopo sem derrubar o veredito.

Duas exceções sobrevivem, porque o texto de máquina acaba chegando a um humano:

- **C1**: a outra sessão repassa a mensagem ao maestro, e a sigla sem glosa chega junto.
- **U1**: sinal velho que ninguém retira engana quem o lê depois.

A mensagem ao usuário que um script imprime é superfície humana. O log de depuração não é.

## 5. O que o Onion já tinha

A régua não reconstrói nada disto. Ela aponta para lá:

| Item | Onde já vive |
|---|---|
| idioma, tom, "você" (parte do C4) | skill `language-standards` e CLAUDE.md |
| rótulo de id opaco na 1ª menção (C1) | `language-standards`, seção "Legibilidade — referências opacas" |
| glosa de sigla da casa (C1) | glossário `house-codes.tsv` e hook `house-code-gloss.sh`: lembra na resposta ao maestro, na mensagem `SendMessage` e no `.md` de estudo |
| revisita e retirada (U1) | `review_after` dos grafos, REGRA 67 (Grafo de pesquisa com REVISITA carimbada), `/meta:kg-freshness`, `/meta:kb-freshness` |
| consulta ao leitor (U2) | pergunta ao maestro com opções (`AskUserQuestion`, `/meta:decide`) |
| estrutura (L1) | títulos e listas em markdown, nos docs e nos cards |

O que faltava: R1, R2, C2, C3 e C5 escritos como régua, e a glosa de sigla no commit e nas mensagens que
não passam por `SendMessage`.

## 6. Como medir

O sinal de cada item (tabela da seção 3) é o que se mede. O protocolo vem do teste da curadoria:

1. Pegue um texto real de uma superfície humana.
2. Percorra os itens que valem para aquela superfície e marque **passa** ou **falha**, com o trecho.
3. Compare com o controle "parece claro?", lido de uma vez só.
4. Conte **P1**: os problemas que a régua achou e o controle não achou.
5. Anote o **contra-sinal**: reprovar texto que já estava claro pesa contra a régua, porque vira cerimônia.

O teste da curadoria (n = 2 textos, um codificador só) achou **P1 = 3** num corpo de commit: decisão
enterrada no 3º parágrafo (R1), quatro termos sem glosa (C1) e uma frase com quatro ideias (C2). O texto que
já estava claro passou sem nenhum sinal falso. É pouco para tornar a régua obrigatória, e foi por isso que o
veredito é costurar, não absorver.

Hoje só o C1 é medido por máquina (o glossário da casa). Os outros itens são doutrina e item opcional de
revisão. Se o uso mostrar um item que falha com frequência e tem sinal mecânico, ele vira candidato a
lembrete, nunca direto a bloqueio.

## 7. Exemplo

**Antes** (commit):

> docs(kg): ajusta o nó após a r26
>
> Depois de rodar o radar e conferir o E3 com o juiz, que refutou dois achados e manteve o terceiro, e
> considerando a Aufhebung pendente, o nó foi marcado como superado.

**Depois:**

> docs(kg): o nó do radar fica superado pela rodada 26
>
> A rodada 26 do radar do Claude Code (eixo E3) superou o nó. O juiz refutou dois achados e manteve um.
> A superação está registrada como aresta SUPERSEDES no grafo.

O que mudou: o desfecho foi para a 1ª linha (R1), as siglas ganharam explicação (C1) e a frase longa virou
três frases curtas (C2).
