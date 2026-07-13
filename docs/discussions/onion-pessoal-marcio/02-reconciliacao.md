---
title: "P2 — O que reconcilia num indivíduo (o motor)"
category: discussion
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/onion-pessoal-marcio
lente: "Aristóteles (a régua) + Hegel (o motor)"
ancora_pesquisa: research/SYNTHESIS-P2.md
constroi_sobre: 01-verticais-peer.md
---

# 🧵 P2 — O que reconcilia num indivíduo (o motor)

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> **Derivação (camada 2):** consome [research/SYNTHESIS-P2.md](research/SYNTHESIS-P2.md) (~60 fontes) e
> **constrói sobre a P1** ([01-verticais-peer.md](01-verticais-peer.md)) — pressupõe as verticais peer,
> as camadas *domain*/*audit* com `TRACES_TO`, o confronto DEV×PROD e o caveat intra-órbita. Não os re-explica.

A P1 fechou *quais são as verticais*. A P2 responde à outra metade do SEED: **o que reconcilia num indivíduo —
decisões passadas × presentes, metas × ações?** A P1 já nomeou o **discriminador motor-vs-bug** como *o* gap
load-bearing. A P2 desenha o motor que ocupa esse gap.

---

## A régua pegou nossa própria falsa distinção

A lição mais desconfortável da pesquisa: **a P1 marcou como "novo" o que era composição, não invenção**. Aplicada
à maquinaria, a régua Aristóteles barrou uma *falsa distinção* nossa — quase todo o motor **já existe pronto** em
peças maduras, e reinventá-las seria o erro:

- O objeto certo é **belief base** (Hansson), não belief set (AGM) — um grafo de claims append-mostly *é* um belief
  base; localizar o subgrafo mínimo contraditório é *kernel contraction*.
- **Argumentação bipolar** (ataque + **suporte**) — a casa formal literal de `SUPPORTS`/`REFUTES` — existe desde
  **2005** (Cayrol-Lagasquerie-Schiex). A P1 marcou "reconciliação por argumentação tipada" como novo por otimismo.
- **Confiança graduada** tem duas maquinarias prontas (ranking functions de Spohn; **QBAF**); o **rastro de
  não-esquecimento** é problema maduro (TMS de Doyle + W3C PROV / provenance semirings).
- O **"quem reconcilia"** que a P1 diz estar desocupado no mercado **já tem nome formal**: *entrincheiramento
  epistêmico* (Gärdenfors-Makinson) — a ordem de prioridade de quem sobrevive à contração.

O que **transfere limpo** é a *semântica* de reconciliação. O que é genuinamente **nosso a desenhar** é a
*composição* + o que segue.

---

## Hegel tem duas encarnações empíricas (não é decoração)

A P1 importou a **Aufhebung** (negar+conservar+elevar, negação determinada) como operador anti-esquecimento. A P2
mostra que ele tem **duas encarnações independentes que a pesquisa validou** — e o motor é a costura das duas:

- **Formal:** a supersessão *append-mostly* de um belief base (fecha a janela do fato velho sem deletá-lo).
- **Narrativa:** a **sequência de redenção** de McAdams (nega o passado ruim, preserva-o na história, eleva ao
  presente) — a Aufhebung empírica, medida em campo. O motor guarda a **trajetória reconciliada, não o snapshot**
  ("o verdadeiro é o todo", em leitura não-metafísica).

---

## 1. Os dois eixos de contradição (não um)

O motor recebe **dois pares**, não um:

| Eixo | O quê | Origem |
|---|---|---|
| **metas × ações** | claim **DEV declarado** (plano datado) × **PROD vivido** (log passivo) | herdado da P1 (§4) — **IGUAL** |
| **eu-passado × eu-presente** | o compromisso do eu-que-prometeu × o comportamento/preferência do eu-de-agora | **novo na P2** — **DIFERENTE** |

E a descoberta que muda o enquadramento: **a divergência eu-passado × eu-presente é estrutural e previsível, não
falha moral.** O desconto humano é **hiperbólico** (Ainslie; Laibson β-δ): a preferência se *inverte* quando a
recompensa menor-cedo se aproxima. O eu-presente "trair" o plano do eu-ontem é **comportamento esperado do sistema**
— o motor carimba a divergência como sinal previsível, e funciona como **prótese de sofisticação**: ao surfaçar o
compromisso passado contra o comportamento vivo, converte um usuário *ingênuo* (não prevê a própria falha) em
*sofisticado* (prevê e pré-compromete).

---

## 2. Compromisso ≠ fato — o objeto novo de primeira classe

Aqui está o achado que **nenhum personal-KB tem** e que a P2 crava como núcleo do design. A tensão que o define:

- A **família do compromisso** (Ulisses, planner-doer de Thaler-Shefrin, regras pessoais/bright-lines de Ainslie)
  diz **SEGURAR** — senão o present-bias vence.
- A **família da revisão** (Parfit: a obrigação da promessa **decai** com a conexão psicológica; Wrosch:
  desengajar de meta inatingível é **adaptativo**) diz **SOLTAR** — o eu-presente é legitimamente livre.

Nenhuma resolve a outra. Reconciliá-las sem colapsar numa só é a **contradição-hegeliana-como-combustível** da P1.
A consequência de modelagem:

> **Um fato contraditório invalida um fato** (supersessão bitemporal, Zep) — **mas não invalida um compromisso.**
> Um compromisso é ou **mantido** (defecção detectada) ou **liberado** (revisão ratificada). Logo compromisso é
> **objeto de primeira classe** — validade temporal + **peso de bindingness graduado** (proporcional à conexão
> psicológica, Parfit) + **bright-line** + **condição de sunset** — distinto de "fato". **DIFERENTE, não-construído.**

Isso materializa o **ipse** de Ricoeur (a capacidade de prometer e permanecer responsável *mesmo quando as
circunstâncias mudam*) como uma **terceira camada** acima de *domain* (fatos atuais, o **idem**) e *audit* (como se
chegou neles): o **fio-de-promessa** que sobrevive à rotatividade dos fatos.

---

## 3. O discriminador — de "desocupado" a "mosaico não-montado"

A P1 disse *desocupado*. A P2 corrige com precisão acionável: **não é vazio, é um mosaico não-montado** — vários
discriminadores parciais existem e **convergem**, discordando só no ponto que é exatamente o gap. Os que transferem:

| Teste | Bug (resolver) vs Motor (preservar) | Papel |
|---|---|---|
| **Sensibilidade à informação** (SEP) | dissolve sob dado completo (14h×16h) vs persiste (autonomia×pertencimento) | screen barato — o Onion já roda (a2a-verify) |
| **Tipo de restrição hard/soft** (MaxSAT) | hard insatisfazível → *unsat-core* aponta o bug vs objetivos soft → fronteira de Pareto a manter | gate determinístico (Colrows "não compila") |
| **Multifinalidade** (Kruglanski) | existe ação que satisfaz ambos os polos? → conflito de meios dissolvível | filtro intermediário |
| **Satisficing por limiar** (Simon) | cair abaixo de limiar hard vs todos os limiares atendidos com múltiplas configs | operacionaliza a incomensurabilidade da P1 |
| **Resíduo** (Williams) | resolve limpo (era aparente) vs deixa resto moral / **re-emerge** | probe **pós-hoc** de runtime |
| **Sacro/trágico/tabu** (Tetlock) | rotineiro→`REFUTES` · trágico→`PRESERVES` · tabu→`REFUSE-TRADE` | taxonomia de arestas |

**Por que automação total é impossível** (os 3 achados que quebram a esperança):

1. **O sacro é autorado, não descoberto** (Chang, "on a par": o compromisso *cria* razões) — para N=1, **quem marca
   o que é sacro é a própria pessoa**.
2. **As disciplinas discordam do default** — Frankfurt trata ambivalência como "doença da vontade" a **resolver**
   (wholehearted); Berlin/Williams tratam o pluralismo como irredutível a **preservar**. Mesmo fenômeno, veredito
   oposto, sem meta-regra. (DBT sobre-sintetiza; Frankfurt sobre-resolve.)
3. **Os sinais confiáveis são pós-hoc** — resíduo (Williams), afeto (Higgins) só se conhecem *depois*. E o alerta de
   Higgins: **nem toda tensão persistente é saudável** — o crônico-duplo approach-avoidance é modo-de-falha, não motor.

**Logo o discriminador é um híbrido de três órgãos**, não um classificador:

1. **Screen determinístico (IGUAL)** — hard/unsat-core aponta o bug ("não compila até resolver"); antes, screen-de-
   informação (verificar o dado); depois, teste multifinal.
2. **Marca humana versionada (DIFERENTE)** — o que sobrevive aos screens recebe uma marca que a *pessoa* declara:
   "esta tensão é protegida-de-resolução". O motor **não infere sozinho** nem **herda default**. Primitivo que
   nenhum produto tem.
3. **Feedback pós-hoc de resíduo (DIFERENTE)** — o teste de Williams como probe de runtime: tensão "resolvida" que
   **re-emerge** = motor mal-classificado → re-abrir e promover a dialetheia protegida. O motor **aprende o
   conjunto-sacro da pessoa** ao longo do tempo (com a guarda de Higgins contra canonizar evitação como sagrado).

---

## 4. O árbitro em N=1 e o antídoto contra o auto-engano (a peça load-bearing)

A P1 exigiu que o "quem reconcilia" fosse explícito, versionado, re-testável. A P2 acrescenta a peça mais frágil e
mais importante — e a **menos fonteada**:

- **Ordem de entrincheiramento (conceito IGUAL / ordem DIFERENTE):** "quem vence" tem nome formal (Gärdenfors), mas a
  ordem concreta (confiança, recência, autoridade, estágio de vida) é **idiográfica** — declarada e versionada pela
  pessoa. É o carimbo de confiança graduada da P1 virado ordem de retração.
- **Responder-gated:** resolver-vs-coexistir e segurar-vs-liberar passam por gate humano — o motor propõe, a pessoa
  ratifica. É o padrão do Onion (gate mecânico + human-in-the-loop).
- **O check externo DEV×PROD como anti-auto-engano (DIFERENTE, load-bearing):** o perigo do N=1 é o eu-presente
  **racionalizar toda defecção como "revisão legítima"**. Sem antídoto, um motor de reconciliação pessoal degenera em
  **máquina de racionalização**. O antídoto é o confronto estrutural que a P1 já tem: o **compromisso DEV declarado e
  datado** é o *check externo* contra o **PROD vivido**. Um desvio não se auto-absolve — ou o **bright-line** de
  Ainslie o classifica como lapso a anotar, ou um **marco temporal N=1** (fresh-start pessoal — aniversário, evento
  de vida) o re-litiga como **sunset ratificado**.

> O DEV passado é o **mastro de Ulisses** que impede o *doer* presente de reescrever a história a seu favor — **com
> uma válvula de escape auditável** (o sunset ratificado) para a revisão genuína (Parfit/Wrosch). Isso resolve a
> tensão SEGURAR×SOLTAR sem colapsá-la: o **default é segurar** (o DEV obriga), mas há **caminho explícito e
> versionado para soltar**, e a distinção é feita **contra evidência externa, não por introspecção do eu-presente**.

---

## 5. A spec do motor, em uma linha

> **belief-base graduado + bipolar** *(IGUAL)* · sobre **grafo bitemporal append-mostly com três camadas
> domain/audit/ipse** *(DIFERENTE)* · reconciliado por **Aufhebung em dupla encarnação formal+narrativa** *(IGUAL o
> operador)* · discriminado por **híbrido screen-determinístico + marca-humana + resíduo-pós-hoc** *(DIFERENTE)* ·
> arbitrado por **entrincheiramento idiográfico responder-gated com o DEV datado como check anti-auto-engano**
> *(DIFERENTE)*. Dialético-no-operador, darwiniano-na-trajetória.

O modelo executável está em [proto/reconciliation-engine.kg.yaml](proto/reconciliation-engine.kg.yaml) e a spec
compacta (camada 2, cita as teorias) em [proto/applications/reconciliation-engine.md](proto/applications/reconciliation-engine.md).

---

## 6. Decisões de design ABERTAS (a agenda que a P2 deixa)

1. **Qual semântica de sobrevivência pinar?** grounded (determinística, binária, encaixa no gate) vs QBAF (graduada,
   mas sem consenso de convergência) — ou híbrido em camadas.
2. **Proxy computável de "conexão psicológica"** (Parfit) para graduar bindingness — recência/consistência/ressonância
   são candidatos; materializá-los é não-fonteado.
3. **ipse/idem como schema concreto** — como materializar o fio-de-promessa como 3ª camada (conf 0.65).
4. **Onde ser normativo, onde ser descritivo** — o motor pode ser racional (AGM) enquanto o humano revisa
   comprovadamente irracional; impor a norma vs espelhar a descrição é escolha de produto.
5. **Cadência: marcos pessoais N=1** (aniversário, luto, mudança) vs data arbitrária.
6. **Detecção automática vs marca manual** de arcos (McAdams) e regime (sacro) — a P2 recomenda marca-humana para o
   regime, inferência-como-hipótese para os arcos.
7. **Como aprender o "conjunto-sacro" sem virar viés de confirmação** — distinguir "protegido legítimo" de "evitação
   cronificada" (o crônico-duplo de Higgins). Aberto.

---

## 7. Honestidade (herdada e agravada)

- **Caveat intra-órbita (P1 §11):** a P2 prova mais fundo o **método** (o discriminador desocupado *é* uma
  arquitetura desenhável; compromisso-como-objeto *é* especificável) — **não o mercado**. N=1 do criador.
- **O risco novo que a P2 adiciona:** o **auto-engano do árbitro**. Declarar que o motor impede o auto-engano
  *melhor que a introspecção honesta* seria **falsa distinção às avessas** — é hipótese fundada, não fato. O
  anti-auto-engano (§4) é a peça mais load-bearing e a **menos fonteada** do desenho.

---

## Ponte para as próximas passadas

- **P3** — fronteira com o core: o Onion pessoal é instância adotante na federação, ou algo à parte (privado)?
- **P4** — privacidade/soberania: classificação por vertical, `de-identification` `none` fail-safe, `exposes:`; e
  agora também a **sensibilidade do fio-de-promessa** (o ipse é dado íntimo).
- Dentro da P2: pinar a semântica (§6.1), o proxy de bindingness (§6.2), o schema ipse (§6.3).

## Dogfood

```bash
bash .claude/validation/kg-radar.sh docs/discussions/onion-pessoal-marcio/proto/reconciliation-engine.kg.yaml
```
