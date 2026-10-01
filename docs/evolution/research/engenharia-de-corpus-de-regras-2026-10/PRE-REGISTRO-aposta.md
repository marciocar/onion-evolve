---
titulo: "Pré-registro da aposta — cobertura de regra como item de maior retorno"
data: 2026-10-01
run: wf_2361d115-99e
estado: ESCRITO ANTES DO RESULTADO
porque: "anti-HARKing. Aposta escrita depois do resultado não é aposta, é narrativa. O maestro pediu explicitamente para não perder o raciocínio PARA CONFRONTAR — logo o critério de refutação tem de estar aqui, não ser inventado quando os dados chegarem."
---

# A aposta

**Dos seis eixos que a rodada mede, o de maior retorno para o Onion é COBERTURA DE REGRA** — saber
quais das 91 guardas nunca dispararam —, **e ele se resolve por mecanismo próprio em shell, não por
ferramenta nova.**

# O raciocínio, em quatro passos

1. **O Onion já tem as partes difíceis.** Registro derivado do COMPORTAMENTO (não do comentário),
   catraca por baseline que só encolhe, 200 famílias de bancada, faixas paralelas, mapa família→arquivo
   derivado do corpo. O que falta nos seis eixos não é **execução** — é **observabilidade sobre o
   corpus de regras**.
2. **Cobertura é o mais barato dos seis**: um contador por regra dentro do motor que já existe. Zero
   dependência externa, zero acoplamento, roda em qualquer CI — não fere a postura de acoplamento.
3. **E destrava os outros**: detecção de conflito e taxa de falso positivo precisam de dado de
   disparo por regra como ENTRADA. Aposentadoria por métrica também.
4. **Responde uma pergunta que hoje ninguém aqui responde**: *destas 91 guardas, quantas estão vivas?*
   E a casa tem precedente medido de que **declarado-e-não-usado é a pior categoria** — o caso
   `SendMessage`, citado como a capacidade que comprava o acoplamento, devolvia **ZERO** ocorrências.

# O que REFUTA a aposta (escrito antes, para não poder recuar)

**R5 é a objeção que eu mesmo considero mais forte, e ela é contra mim:**

- **R5 — "nunca disparou" pode ser o caso de SUCESSO, não de morte.** Uma guarda que nunca disparou
  pode significar que o defeito nunca voltou — exatamente o que ela existe para fazer. Se for assim,
  cobertura mede a coisa errada, e o que importa é *"ela dispararia num mutante plantado?"* — que é a
  **bancada**, e a bancada **já existe** com 200 famílias. Nesse caso a aposta é redundante.
  *Como eu distinguiria*: a bancada prova **capacidade** (ela PODE disparar); o contador provaria
  **relevância** (ela ENCONTRA algo no mundo). Se a rodada mostrar que a comunidade trata as duas como
  a mesma coisa, ou que só a primeira importa, a aposta cai.
- **R3 — a dor real pode ser RUÍDO, não regra morta.** Regra morta é inerte; regra ruidosa faz
  **desligarem o gate**. A casa tem o precedente escrito: *"reprovar toda porta defasada nasceria
  vermelho (377) e seria desligada na primeira sexta-feira"*. Se a arte mostrar que falso positivo é o
  que mata adoção de gate, a prioridade inverte e a aposta cai.
- **R1 — cobertura pode NÃO destravar conflito.** Se a detecção de conflito do estado da arte for
  **estática sobre a definição** da regra (padrão/AST), e não sobre disparos, meu passo 3 é falso.
- **R2 — adotar pode ser mais barato que absorver.** Se SARIF + ferramenta existente der cobertura de
  graça com menos trabalho que instrumentar 91 guardas, "mecanismo próprio" perde por custo.
- **R4 — pode não ser barato.** As 91 guardas compartilham helpers, e a severidade é derivada do CORPO:
  um contador precisa da mesma associação header→função que o `rules-registry.sh` faz — e essa
  associação **falhou hoje**, no defeito da regra órfã. Se o ponto de disparo não for identificável sem
  reescrever o motor, "barato" é falso.

# Como vou confrontar

Ao chegar o resultado: para cada R1–R5, dizer **sobreviveu ou caiu, com a evidência da rodada**, antes
de recomendar qualquer coisa. Se a aposta cair, ela cai por escrito — não desaparece do relatório.

---

# EMENDA (2026-10-01, antes do resultado) — o reforço do maestro enfraquece a aposta

O maestro acrescentou o eixo que eu não tinha enquadrado: *"além da pergunta 'quantas estão vivas?'
está a questão de coisas como a **sobreposição, sequenciamento, dependências**, e outras questões que
**não podem complicar** e **não podem deixar de funcionar**"*.

**Por que isso muda a aposta, e não é detalhe:** "quantas estão vivas" trata o corpus como **LISTA**.
Sobreposição, sequenciamento e dependência o tratam como **SISTEMA** — e é no sistema que o dano desta
casa aconteceu.

## R6 — a objeção com CUSTO MEDIDO, e ela derruba a PRIORIDADE da aposta

Medido no repo em 2026-10-01: **93 chamadas de guarda, e nenhuma declara dependência de outra**. A
ordem existe apenas implícita na sequência do corpo do script; não há campo de dependência no registro
projetado, nem validação de ordem.

E o dano é recorrente e datado, **só nesta sessão**:

| ocorrência | o que aconteceu | custo |
|---|---|---|
| REGRA 81 (Painel de estado) | o painel **conta** o resíduo e foi gerado **antes** de o resíduo existir — commit `578b233d` se chama *"3ª vez"* | ciclo de CI |
| REGRA 56 (Resíduo da passada adversarial) | SHA carimbado antes de regenerar projeções → `ARTEFATO-CADUCO`, **duas** vezes | 2 ciclos |
| REGRA 62 / REGRA 80 (projeções geradas) | projeções julgadas antes de regeneradas | 1 ciclo |

**A assimetria que me refuta:** regra morta tem custo medido **zero** — ela é inerte. Erro de
**ordem** custou pelo menos **quatro ciclos de CI num único dia**, e a cura até agora foi sempre
**prosa** ("regenerar → stagear → carimbar → commitar de uma vez"), que é a forma de cura que esta casa
já declarou insuficiente. Pela régua de VALOR (mecanismo > guarda > instância, nunca pela atenção do
radar), **sequenciamento/dependência vem antes de cobertura**.

A aposta original não está errada no mecanismo — está errada na **ordem de prioridade**, e eu a
declarei antes de medir o custo comparado. Fica registrado assim.

## O critério de aceitação que o reforço impõe, e que eu não tinha escrito

*"não podem complicar e não podem deixar de funcionar"* — duas restrições de projeto, não desejos:

- **não complicar**: a solução não pode exigir que quem escreve uma guarda aprenda um grafo de
  dependências. Se a declaração de ordem não for derivável do que já existe (como a severidade já é
  derivada do CORPO, e o mapa família→arquivo já é derivado do corpo da família), ela envelhece —
  porque declaração à mão que ninguém confere é a classe `declarado ≠ verificado`.
- **não deixar de funcionar**: ordem errada hoje falha **tarde** (no CI, às vezes só no PR seguinte).
  O alvo é falhar **cedo e nomeando** — e o teto honesto é que isto é detecção, não prova.

## Como vou confrontar, agora com seis critérios

Para cada R1–R6: **sobreviveu ou caiu, com a evidência da rodada**. E para R6 especificamente, a
pergunta à arte é outra: *como a comunidade declara e valida ORDEM e DEPENDÊNCIA entre regras sem obrigar
quem escreve a regra a desenhar um DAG?* Se a resposta for "ninguém faz, todos sofrem em prosa", isso é
achado — e aí a superação é nossa para construir, não para adotar.
