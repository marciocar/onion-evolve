---
date: 2026-08-17
instance: onion-evolve
type: error
classification: collective
tags: [teste-do-gatilho, pull-not-push, proposta-propria, gatilho-social, recorrencia, memoria-nao-aplicada]
affects: [meta]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-17
conflict_class: static
significance: "Propus construir uma guarda de base-de-branch e só rodei o Teste do Gatilho quando o maestro perguntou 'o que o Onion pede e tem valor de fato nisso?'. O teste REPROVOU a minha própria proposta em três frentes. A diretriz de rodar esse teste ANTES de propor existe como memória desde 05/08 — o problema não é conhecimento, é APLICAÇÃO, e o gatilho eficaz continua sendo social."
---

# Propus mecanismo sem rodar o Teste do Gatilho — e ele reprovaria a proposta

**O que aconteceu.** Depois de três incidentes no mesmo dia por ramificar branch da branch
atual em vez de `main` (#622 fechado, #624 travado sem checks, #626 com medição contaminada),
eu ofereci ao maestro construir uma guarda que recusasse branch cuja base não fosse `main`.
Ele respondeu com uma pergunta, não com um "sim": *"o que o Onion pede e tem valor de fato
nisso?"* — e aí eu rodei o teste que devia ter rodado antes.

**O Teste do Gatilho reprova, em três frentes, e nenhuma é opinião:**

1. **O dano é barato e AUTO-REVELADOR.** O git acusou na hora (PR fechado, `DIRTY`, diff
   contaminado); o conserto foi um `rebase` de segundos; nada chegou a produção. Mecanismo se
   paga contra defeito **silencioso** — o `echo "MERGED"` que mentia, o gate inerte em 4 de 6
   adotantes, o PAT herdando `bridge:admin`. Esse grita sozinho.
2. **A cura não distingue acidente de PADRÃO INTENCIONAL.** Ramificar de outra branch **é** o
   PR empilhado, que esta casa usa de propósito e tem mecânica documentada. Uma guarda em
   `pre-push` comparando com `main` acusaria trabalho legítimo — e guarda que grita no caminho
   certo é a que a pessoa desliga. Eu estaria construindo o `--no-verify` de amanhã.
3. **Há precedente MEDIDO contra.** A pesquisa da perna de leitura do KG reprovou três curas
   candidatas por cobrirem **1/9** do dano medido (veredito NÃO CONSTRUIR). A minha cobriria
   um incidente barato, com falso-positivo embutido.

**A recorrência, que é o registro que importa.** A diretriz de rodar o Teste do Gatilho
**contra a minha própria proposta, antes de apresentá-la** já existe como memória desde
2026-08-05 (`apply-pull-not-push-to-own-proposals`), e nasceu de um caso idêntico: propus uma
catedral de `systemd-creds` e só corrigi quando o maestro perguntou. Hoje, mesma forma. Logo:
**o problema não é conhecimento — é aplicação**, e o gatilho eficaz continua sendo **social**.
É a terceira aparição desse eixo no mesmo par de dias: o diário de 02/08
(`self-correction-trigger-was-social`, 8 de 15 correções só porque o maestro perguntou), a
pesquisa da perna de leitura (7 de 9 falhas por não-consulta, disparo por humano), e agora.

**Por que NÃO estou criando mecanismo para isto também** — e isso é a coerência que o próprio
teste exige: propor uma guarda que me force a rodar o Teste do Gatilho seria rodar o Teste do
Gatilho... para propor uma guarda que não passa por ele. O dano de propor cedo demais é
**barato** (o maestro pergunta e eu reviso, como aconteceu), e a alternativa mecânica seria um
gate sobre a MINHA fala, que nenhuma guarda determinística alcança. Fica como registro de
classe, com a honestidade de dizer que registro é a cura mais fraca — e que a escolhi porque
a forte não existe aqui, não porque dá menos trabalho.

**O que TEM valor de fato, e virou a dívida real desta rodada:** os **~49s** que eu afirmei
para PR de docs depois de dividir o CI. O `#626` não provou — ele tocava
`.github/workflows/**` (porque nasceu da branch do CI, o mesmo vício), então a bancada rodou
CORRETAMENTE e minha medição foi inválida. **Este PR aqui é o teste**: nasceu de `main`, toca
só diário e resíduo. Se o job `selftest` NÃO aparecer nos checks, os 49s deixam de ser
projeção. Se aparecer, meu filtro de path está errado e eu descubro pelo PR que registrou a
lição.

**Re-teste em 2026-11-17:** contar quantas propostas de mecanismo minhas, entre hoje e lá,
chegaram ao maestro **já filtradas** pelo Teste do Gatilho (GATED explícito quando o gatilho
não disparou) versus quantas ele teve de filtrar perguntando. Se a razão não melhorar, a
conclusão não é "tentar mais" — é que a diretriz precisa virar etapa de algum ritual que já
tenha gate (pre-PR, resíduo R56), e não memória que depende de eu lembrar no momento de falar.
