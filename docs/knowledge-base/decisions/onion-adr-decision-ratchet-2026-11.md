---
title: "ADR — Catraca de decisões automáticas: classe pelo ato, força separada, afrouxar só com histórico"
date: 2026-11-21
type: adr
status: accepted — selado pelo maestro em 2026-11-20; em observação (régua não ligada)
decision-scope: governança / autonomia das sessões / aprovação do maestro
supersedes: none
related:
  - ../concepts/decision-ratchet-doctrine.md
  - ../concepts/onion-dogfooding-doctrine.md
  - onion-adr-comms-transport-vs-execution-2026-06.md
---

# ADR — Catraca de decisões automáticas

| Campo | Valor |
|-------|-------|
| **Decisão** | Cada ato cai numa **classe** medida pelo próprio ato: **A** automático (hoje só o que não muda estado), **B** «pode rodar» digitado pelo maestro, **C** só o maestro. A **força da prova** é eixo separado. Lista fixa de C que nunca desce. Livro só de acréscimo com teto declarado. Afrouxar só com histórico medido |
| **Escopo** | Todo ato de sessão que hoje pede formulário, comando `!` ou «pode rodar» do maestro |
| **Status** | ✅ **Aceito** em 2026-11-20 (três selos do maestro). **Em observação**: a régua não está ligada e nenhum ato desceu de classe |
| **Origem** | Consulta Delphi de 7 sessões da família, em 20/11/2026, sobre uma colheita só de leitura dos 20 dias anteriores. No Delphi, cada sessão responde sem ver as outras; as posições circulam sem autor; uma síntese vai ao maestro, que sela |
| **Doutrina** | [Doutrina da catraca de decisões](../concepts/decision-ratchet-doctrine.md) |

---

## Status

✅ **Aceito**, 2026-11-20. Três selos do maestro, por pergunta com opções:

1. **Selar a síntese e começar, documentando para explicação e auditoria** (descartado: selar com ajustes).
2. **A classe B vale já**, antes de o livro morar fora da máquina (descartado: esperar o livro).
3. **Até o executor separado, a classe A vale só para ato que não muda estado** (descartado: primeiro criar a separação).

Os selos estão no grafo de coordenação do core (core-only): `D_DECISION_RATCHET_SYNTHESIS_SEALED_1120`,
`D_RATCHET_CLASS_B_VALID_NOW_1120` e `D_RATCHET_AUTO_ONLY_NON_STATE_CHANGING_1120`.

---

## Contexto

O maestro aprovava à mão quase tudo que mudava estado. Numa colheita de 20 dias (01 a 20/11/2026) nas
sessões do core:

- **213 formulários** respondidos (507 perguntas) e **85 comandos `!`**;
- de 2 a 34 intervenções por dia; cerca de 15 a 18 por dia na última semana;
- cerca de **94 cliques só de merge**;
- o «pode rodar» (aprovação de um toque, desde 19/11) teve **10 recusas em 15 tentativas**.

Quatro problemas apareceram na colheita:

1. **«Nível» tinha quatro sentidos**, e um deles com a numeração invertida. O mesmo número diria coisas
   opostas no mesmo script.
2. **Não havia livro de reversão.** Os registros estavam espalhados, e nenhum guardava se o ato foi
   desfeito. Sem isso, «afrouxar com histórico» não roda.
3. **Tudo é conformidade.** As sessões rodam com o privilégio pleno do usuário do maestro. Uma catraca que se afrouxa sozinha seria escrita pelo mesmo agente que ela regula.
4. **A origem do disparo não entrava na conta.** Um ato pedido por outra sessão valia o mesmo que um
   pedido do maestro.

---

## Decisão

1. **Dois eixos.** Classe A/B/C diz **quem decide**. Força 1/2/3 diz **como a aprovação prova quem a deu**
   (1 frase digitada; 2 fora da banda com identidade conferida; 3 prova física ou de duas pessoas).
   Força 2 por canal ou botão só depois de medir que a superfície não forja o «pode rodar».
2. **Classificar pelo ato medido.** Régua determinística com chave (verbo, alvo, reversível, origem).
   Desconhecido cai em C. Origem por relay, caixa de entrada, A2A (sessão falando com sessão) ou tarefa
   agendada nunca dá A.
3. **Lista fixa de C, que nunca desce:** cliente, dado pessoal, segredo, contas, `sudo`, `sshd`,
   firewall, produção, deploy, CI/CD, publicação externa (repo público, porta), a branch principal de
   produção (master), apagar sem cópia cifrada, instalar ou ativar mod (extensão do Claude Code), PR que
   toca a própria catraca, selo de contrato, tag e release, escrita em repo de outro dono.
4. **Merge de guarda:** vale a regra mais estrita do repo; nunca A.
5. **Livro:** só de acréscimo, encadeado por hash, ponta ancorada fora da máquina, com o teto escrito
   nele: «adulteração detectável, não impossível».
6. **Ordem:** curar a fricção do «pode rodar» → observar 30 dias sem decidir → fixar N (partida: 20 atos
   sem reversão em 30 dias por par verbo+alvo) e ligar descidas, só para atos que se desfazem. A classe
   **sobe com incidente**; o alcance da subida (só o par, ou a catraca inteira) fica para o fim da
   observação.
7. **Pacote** de até ~5 atos, cada um preso ao commit e de uso único, valendo pela classe mais alta.
8. **Fora por ora:** o drive automático. A personalidade só projeta o livro. A confiança de cada
   assistente de empresa é separada da do Onion.
9. **Bancada própria antes de ligar**, com um mutante por regra e um controle vivo.
10. **Documentar para explicação e auditoria** (exigência do maestro no selo): a doutrina diz o que cada
    linha do livro registra e como um terceiro confere.

---

## Alternativas consideradas

### A1 — Catraca de um eixo só, com níveis 0/1/2 (proposta de partida)

Era a pergunta levada ao Delphi: nível 0 automático, 1 «pode rodar», 2 só o maestro. **Rejeitada** por
todas as sessões que trataram do ponto: o número colide com o «nível» do «pode rodar», em que 2 é a
aprovação **mais forte**. Separar classe (letra) de força (número) desfaz a colisão.

### A2 — Classificar pelo texto do pedido

Uma régua que lê o prompt ou a mensagem e infere o risco. **Rejeitada**: o texto é exatamente o que um
adversário controla, e a sessão que classifica é a mesma que quer executar. Uma sessão a listou como
eliminatória; duas vetaram casos vizinhos (identidade tirada do texto, classe declarada pela sessão).

### A3 — Ligar A já para atos reversíveis, com conformidade ancorada

Defendida por uma sessão: com o livro ancorado fora da máquina, atos que se desfazem já poderiam ser
automáticos. Três outras sessões disseram não antes do executor separado. **Afastada pelo efeito do
selo 3**: A3 não era opção na pergunta, mas a escolha («só o que não muda estado») a exclui até existir
o executor.

### A4 — Primeiro criar a separação (executor próprio), depois qualquer automático

**Descartada pelo maestro** (selo 3). Esperar o executor parava também o ganho seguro, que é tirar do
maestro os atos que só leem e medem.

### A5 — B só depois do livro fora da máquina

Posição de uma sessão, que trata todo B como C até o livro morar fora. **Descartada pelo maestro**
(selo 2): o livro serve para descer de classe, não para o maestro aprovar. No repo dessa sessão vale a
regra local, mais estrita.

### A6 — Selar com ajustes

**Descartada pelo maestro** (selo 1) em favor de selar como estava e documentar.

### Dissenso registrado — a objeção de uma sessão

Das 7 sessões, 6 aceitaram a síntese e **1 fez uma objeção pontual**: pediu que o PR da ponte de chat,
que traz aprovação por clique, **esperasse as medições de mods**. Mod é uma extensão do Claude Code. O
registro da objeção guarda a pergunta, não o argumento inteiro. O risco que a cerca está medido em
laboratório e foi trazido por outra posição do Delphi: sem guarda gerenciada, um mod aprova o que a regra
barrou.

O maestro decidiu que o PR **segue** como estava: os atos perigosos pedem clique, e a identidade do
maestro vem do evento do chat conferido pelo portão. As **três medições de mods** foram liberadas para
correr em paralelo no laboratório. A objeção **não foi refutada**. Ela reforça uma condição que a síntese
já trazia: **força 2 por canal ou botão só depois dessas medições**. Até lá, o clique da ponte é guarda
da ponte e não desce a classe de nenhum ato.

### Divergências que ficaram abertas no Delphi

- **B antes do livro fora da máquina?** Resolvida pelo selo 2 (sim).
- **Conformidade ancorada basta para A em atos reversíveis?** Resolvida pelo selo 3 (não, por ora).
- **O valor final de N.** Fica com a medição do modo observar.

---

## Consequências

**Positivas**

- Cada decisão passa a ter resposta escrita para «por que rodou» e «quem decidiu, com que prova».
- O maestro deixa de aprovar atos que só leem e medem.
- O erro fatal (um ato perigoso rodar sozinho) fica fechado por desenho: desconhecido cai em C, e a lista
  fixa nunca desce.

**Negativas**

- No curto prazo quase nada sai do maestro: A é estreita, e descer exige 30 dias de observação.
- O livro é mais uma peça para manter, e sem reversão registrada ele não serve.
- Tudo segue sendo conformidade, não fronteira, até o executor separado existir.

**Neutras**

- A tabela de atos que o core já usa ganha uma coluna de classe; não nasce tabela nova.
- O drive automático fica como está.

---

## Gatilhos que reabrem esta decisão

- **Executor separado pronto** (usuário ou contêiner sem `sudo`, token próprio): reabre o escopo de A.
- **As três medições de mods** no login real: decidem se a força 2 por botão existe.
- **Fim dos 30 dias de observação**: fixa N e o alcance da subida por incidente. Uma posição do Delphi
  propõe ainda: se B for raro (menos de ~5 por dia), só curar a fricção, sem classificar.
- **Conjunto de ouro com algum C caindo em A**: a régua não liga (o teste exige zero). Uma posição propõe,
  nesse caso, ficar só com A e C.
- **Incidente num ato C**: reabre a catraca; as posições divergem entre congelar as descidas e subir
  tudo um degrau.

---

## Referências

- [Doutrina da catraca de decisões](../concepts/decision-ratchet-doctrine.md): classes, força, livro, teto.
- [Transporte × execução](onion-adr-comms-transport-vs-execution-2026-06.md): o eixo irmão (transporte
  automático, execução com gate).
- Grafo de coordenação do core (core-only): `docs/onion/graph/coordenacao-selos-arquivo-2026-11.kg.yaml`.
