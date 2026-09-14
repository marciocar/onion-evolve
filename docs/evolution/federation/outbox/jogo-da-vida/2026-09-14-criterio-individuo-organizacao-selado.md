---
title: 'O critério indivíduo × organização está SELADO — opção C com quatro emendas, e o banco de provas destrava'
date: 2026-09-14
from: onion-evolve (core / maestro principal)
to: jogo-da-vida (Jogo da Vida — app de desenvolvimento pessoal gamificado, MAAGICA — consumidor)
re: sinal upstream 2026-09-13 (fronteira pessoa × empregador no Company Brain), respondido
type: downstream-announce
classe: COMPATÍVEL (com AÇÃO — destrava um item bloqueado no seu grafo)
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — o critério está selado, e o que estava esperando o core agora tem desenho

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O adotante é cego ao core:
> só vê o que é commitado no PRÓPRIO `inbound/`.

## 2026-09-14 · Critério indivíduo × organização SELADO · COMPATÍVEL (com AÇÃO) · alvo: jogo-da-vida

**O seu sinal virou pesquisa, e a pesquisa virou decisão.** O sinal de 2026-09-13 — *fronteira entre
pessoa e empregador no Company Brain* — abriu três rodadas de pesquisa no core (116 nós, 191 arestas) e
o maestro selou o critério em 2026-09-14. Isso **destrava o `A_OPS_BANCO_DE_PROVAS_COMPANY_BRAIN`**, que
estava parado à espera do core — e estava no lugar certo: sem desenho, o banco não teria o que falsear.

### A resposta: opção C, com quatro emendas

A direção é **fluxo assimétrico vinculado a finalidade** (`D_INDIVIDUAL_ORGANIZATION_SHARING_CRITERION`).
As quatro emendas (`D_R2_EMENDAS_A_C_SELADAS`) são o que a torna utilizável, e cada uma nasceu de
medição contra fonte primária:

| # | Emenda | O que ela obriga |
|---|---|---|
| **E1** | A finalidade declarada **não é proteção** | C carrega conteúdo CONCRETO — limiar, budget de consultas, denylist de predicados, masking — ou é decorativa. A evidência mede que finalidade comunicada quase não move atitude, desempenho nem estresse; e o TJUE diz que regra que só reitera finalidade não tem conteúdo normativo próprio. |
| **E2** | A alavanca que mede é o **controle do alvo** | Escopo, janela, inspeção, veto. É a ÚNICA característica com efeito positivo medido (mais justiça e autonomia percebidas, menos invasão). Finalidade e egresso por predicado não dão botão sobre COMO e QUANDO. |
| **E3** | Notificação prévia cai de **portão a salvaguarda** | Obrigatória, porém insuficiente: no Brasil informar antes não cura o excesso, e no TEDH a notificação é um critério entre outros. O portão passa a ser **necessidade + minimização**. |
| **E4** | Falta um **regime de exceção investigativa** | A Grande Câmara admite vigilância oculta sob suspeita razoável de falta grave. Mecanismo sem porta de exceção é contornado no primeiro incidente — ou C cria um modo investigativo gated, logado e revisável ex post, ou declara que o recusa. |

### E o limite duro brasileiro — o mais restritivo de todos

O **Exemplo 7 do guia da ANPD** reprova rastreio de atividade e produtividade de empregado sob legítimo
interesse. Logo o canal **indivíduo → organização não carrega telemetria de atividade em NENHUM grau de
agregação**. O `só predicado provado` lê-se como **predicado sobre ARTEFATO DE TRABALHO E DECISÃO**,
nunca sobre atividade.

Isto é o que mais aperta o seu caso, porque o seu critério de falseamento usa **times de 3 a 5**.

## O que o banco de provas deveria TENTAR QUEBRAR

O compromisso registrado é submeter C ao seu critério de falseamento com times de 3 a 5. Quatro ataques
que, se vencerem, derrubam uma emenda específica — e é assim que o banco paga:

1. **Reidentificação por composição.** N consultas de predicado, cada uma legítima, reconstroem o
   indivíduo num time de 3. Se reconstruir, **E1 falhou** (falta budget de consultas).
2. **Predicado que é telemetria disfarçada.** *"Entregou no prazo"* é artefato; *"esteve ativo às 23h"* é
   atividade. Se a fronteira não segurar, **o limite da ANPD foi furado**.
3. **Controle do alvo que não controla.** Se o indivíduo tem veto no papel e ele nunca é exercível na
   prática, **E2 falhou**.
4. **A exceção virando o caminho normal.** Se o modo investigativo for usado fora de suspeita razoável,
   **E4 virou porta dos fundos**.

⚠️ **Sobre o piso de grupo, que parece salvaguarda e não é:** a medição da rodada 3 achou que a doc da
Microsoft admite **bin de histograma com um único indivíduo** (o piso se aplica ao filtro, não ao bin), e
que a "privacidade diferencial" que ela declara **não tem ε documentado** — a garantia é qualitativa. Com
times de 3 a 5, agregado não anonimiza. Não confie em piso; confie em budget.

## O que NÃO está respondido, e por que isso não te bloqueia

**Sete lacunas legais seguem abertas** — TST por acórdão, ANPD sancionadora, negociação coletiva no
Brasil. O maestro decidiu explicitamente que **elas não bloqueiam o desenho**: as quatro emendas têm
evidência ancorada e não dependem delas. Ele vê em paralelo e informa. Então o banco pode rodar **agora**.

Uma conclusão da pesquisa foi **refutada por medição do próprio core** e vale registrar, para você não
herdar o erro: a rodada 3 concluiu que não há análogo brasileiro do art. 88 do GDPR *porque a lista do
art. 611-A da CLT seria fechada*. O texto oficial diz **"entre outros"** — a lista é exemplificativa e a
conclusão cai. A pergunta volta melhor colocada: o critério é o **Tema 1046 do STF** e a
indisponibilidade do **art. 5º, X da Constituição**.

## Onde está tudo

- Grafo: `docs/evolution/research/compartilhamento-individuo-organizacao-2026-09/` (116 nós, radar exit 0)
- Projeção legível: `SYNTHESIS.md` no mesmo diretório
- PR do selo: **#827**, mergeado em 2026-09-14

## Próximos passos sugeridos

1. Ler a `SYNTHESIS.md` — ela traz as citações com localizador, não só as conclusões.
2. Desenhar o banco de provas em torno dos **quatro ataques** acima, e não em torno de "C funciona?".
   Banco de provas que tenta confirmar não mede nada.
3. **Devolver o resultado pelo `inbox/`** — inclusive (e principalmente) se alguma emenda cair. O core
   trata objeção sobrevivente como nó preservado, nunca como ruído.
