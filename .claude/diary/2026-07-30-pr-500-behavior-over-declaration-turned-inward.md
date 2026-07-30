---
date: 2026-07-30
instance: onion-evolve
type: learning
classification: collective
tags: [behavior-over-declaration, milestone-pr-500, fix-must-become-mechanism, kg-diagnose, adopter-relay, self-review, gated-work, sovereignty]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: "A dúvida NÃO para no trabalho antigo — vira-a contra o que você acabou de escrever, no mesmo turno. Nesta sessão o behavior-over-declaration pegou, em ordem: a memória, o sinal do adotante (2 de 7 produtos já existiam), a minha própria triagem (o #6 'wrapper fino' era o de maior alavancagem), a minha doc recém-escrita (o over-claim 'o radar pegou sozinho'), e o meu próprio PLANO aprovado ('o skeleton passa o --schema' — falso; skeleton vazio reprova o radar de propósito). Regra dura: ao escrever um claim verificável — inclusive num plano/doc que você mesmo acabou de aprovar — RODE-O antes de commitar. O claim errado vira feature (o selftest c1/c2 nasceu de descobrir que o skeleton vazio reprova). A cura nunca é 'ter mais cuidado'; é o selftest/gate que verifica por você — e ele se aplica ao seu próprio output mais fresco, não só ao alheio."
review_after: 2026-10-30
conflict_class: static
significance: "PR #500 — e ele carrega a lição da sessão inteira: behavior-over-declaration virado PARA DENTRO, mordendo a própria cauda até o plano recém-aprovado. A sessão fechou o relato de campo de um adotante de ponta a ponta: bug do kg-radar (aspas simples que o prettier gera) corrigido de raiz; retro do processo dele coletada, relayada client-safe e triada; os 7 produtos deriváveis RESOLVIDOS (2 já existiam — behavior-over-declaration; 4 construídos; 1 estendido); e o doctrine-freshness curado de raiz (o guard pula code fences). O #500 é o modo /meta:kg diagnose + a automação parcial do seu pipeline — o KG-SDAAL aplicado ao DIAGNÓSTICO de engajamento de negócio (o radar --domain estado-absorvente = gargalo do cliente), com a PAUSA humana preservada como linha vermelha (scaffold do mecânico, NUNCA um --auto que gere KG caixa-preta). O marco não é o número redondo; é onde a disciplina fechou o círculo: cada verdade dos meus erros ficou registrada NO GRAFO (a triagem tem os REFUTES/SUPERSEDES dos meus vereditos errados), e o dogfood de cada entrega reconcilia contra si mesmo."
---

## O que fechou (a jornada de campo de um adotante, inteira)

Da mensagem "e tem mensagem do Arandek" ao #500:

- **Bug do `kg-radar` corrigido de raiz** (#491): `trim()` só tirava aspas duplas; o prettier normaliza
  `"1"`→`'1'` no pre-commit → todo `.kg.yaml` nascia reprovando o próprio gate de schema. Fix no parser
  (não nos arquivos) + fixture + selftest fechando o flanco que a suíte não pegava.
- **A retro do processo do adotante** — coletada (ele empurrou; verifiquei no remote, não no "respondi"),
  **relayada client-safe** (gate `grep`=0), e **triada no grafo**.
- **Os 7 produtos deriváveis, RESOLVIDOS:** #1 já existia (`create-vertical`), #2 decks, #3 retro-skill
  (bundlada), #4 visitante (autoridade-de-pessoa no onboarding), #5 absorção-de-skill, #6 **diagnose**
  (o que eu quase descartei), #7 gate client-safe (já existia + `--terms`).
- **doctrine-freshness curado de raiz** (#498): o guard pula code fences — `latest` numa tag Docker é
  código, não afirmação doutrinária. Lint 0 HARD/0 SOFT pela 1ª vez na sessão.

## A lição durável — behavior-over-declaration virado PARA DENTRO

O padrão não é novo (a sessão de 07-27 já o nomeou). O que ESTA sessão adiciona é a **direção**: a
dúvida deixou de olhar só para trás (memória, trabalho antigo) e passou a morder o trabalho **mais
fresco possível** — incluindo o que eu tinha acabado de escrever e aprovar.

| # | A declaração | Quem a refutou |
|---|---|---|
| 1 | Minha memória de "onde parei" | git log / o filesystem |
| 2 | O sinal do adotante: "construam o produto #1/#7" | o core JÁ os tinha (create-vertical, projection-safety) |
| 3 | **Minha própria triagem:** "#6 é wrapper fino, baixo valor" | a re-análise: era o de MAIOR alavancagem |
| 4 | **Minha doc recém-escrita:** "o radar pegou as auto-correções sozinho" | a revisão: o radar LISTA, o humano modela |
| 5 | **Meu próprio PLANO aprovado:** "o skeleton passa o --schema" | rodá-lo: skeleton vazio REPROVA (0 nós não é grafo) |

Os três últimos são o salto: a disciplina aplicada contra o **meu próprio output**, cada vez mais
recente — a triagem, depois a doc da mesma sessão, depois o plano aprovado minutos antes.

## A cura foi sempre mecanismo — e o erro virou feature

Nenhuma dessas se resolveu por "lembrar de verificar". O #5 é o exemplar: descobrir que o skeleton
vazio reprova o radar (de propósito — anti-falso-verde) **virou o selftest c1/c2** (vazio reprova · 1º
lote → exit 0). O claim errado do plano não foi apagado — virou a prova de que o valor do diagnose
**nasce do humano preenchendo, lote a lote**, não de um gerador caixa-preta. E cada veredito errado meu
ficou **no grafo**: a triagem do relay carrega os `REFUTES`/`SUPERSEDES` dos meus próprios erros (#1, #4,
#6, #7), e o dogfood de cada entrega reconcilia contra si mesmo. A doutrina não confia nem no que ela
mesma acabou de afirmar — e é isso que o #500 marca.

## O #500 em si — diagnose + automação-com-pausa

O KG-SDAAL ganhou a **3ª aplicação**: além de investigação e domínio de software, o **diagnóstico de
engajamento de negócio**. O mesmo radar soberano, objeto novo: `--domain` estado-absorvente = o gargalo
do cliente; atenção = onde focar; reconciliação = a hipótese que a descoberta refutou. A automação
entregou o **mecânico** (o scaffold do store, o gap real) preservando a **PAUSA** humana como linha
vermelha — não há `--auto` de diagnóstico de propósito, porque diagnóstico sem o selo humano vira
gerador-de-conteúdo, o anti-padrão que o KG-SDAAL existe para combater. Soberania intacta: o método vai
ao core, o KG do engajamento (dado do cliente) nunca sai do adotante.
