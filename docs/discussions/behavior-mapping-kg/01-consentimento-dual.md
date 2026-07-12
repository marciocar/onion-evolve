---
title: "P1 — A linha ética: mapeamento consentido e dual-autorizado ≠ vigilância"
category: discussion-note
status: fonte-de-discussao-isolada
branch: discuss/behavior-mapping-kg
responde: "SEED.md — pergunta 1 (onde é a linha ética/legal?)"
lente: "Integridade Contextual (Nissenbaum) + a linha intake↔execução do Onion"
ancora_pesquisa: research/SYNTHESIS-P1.md
metodo: "pesquisa orquestrada 4 frentes (citada, verificada) antes de posição"
constroi_sobre: []
---

# 🧵 P1 — A linha ética do sensor de comportamento

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir. Não misturar com os
> outros temas. ⚠️ Tema de alta sensibilidade — a ética vem *antes* do "como coletar".

## O veredito, em uma frase

**Um sensor de comportamento só é legítimo quando a captura é deliberadamente autorizada pela pessoa
_e_ pela organização, para um propósito de melhoria declarado e agregado — nunca imposta nem
acidental — e mesmo assim ele carrega uma lacuna que o consentimento não fecha: a inferência.**

A técnica que mapeia "o que a pessoa faz" para documentar, padronizar e automatizar é a **mesma**
que vigia. O que as separa não é a ferramenta — é a **finalidade, a agregação, a transparência e o
controle do titular** ([SYNTHESIS-P1](research/SYNTHESIS-P1.md) §1, §3). Esta nota crava a linha e
fica atrás dela.

---

## 1. Mapeamento consentido para melhoria ≠ vigilância (a finalidade é o divisor)

A distinção não é intuição moral externa — a própria disciplina de process mining a **codificou**.
O framework **FACT** (van der Aalst) e o *ethical charter* de Fluxicon prescrevem declarar, no
projeto, que **avaliação de desempenho individual NÃO é objetivo** — analisar o **processo**
(agregado), nunca escrutinar a **pessoa** (nominal) ([SYNTHESIS-P1](research/SYNTHESIS-P1.md) §1).
A pesquisa converge em **quatro eixos** que, violado qualquer um, convertem mapa em vigilância:

| Eixo | Mapeamento (legítimo) | Vigilância (anti-padrão) |
|------|-----------------------|--------------------------|
| **Finalidade** | otimizar/automatizar o fluxo transversal | avaliar/punir o indivíduo |
| **Transparência** | o titular sabe o quê, como, quem vê | coleta oculta / default-on |
| **Agregação** | agregado, k-anonimizado, por equipe | rastreio nominal, ao segundo |
| **Controle** | consentimento atualizado, revogável, contestável | sem saída, fora do expediente |

Isto reenquadra o SEED: a empresa entra como **compositora de conhecimento consentido** de várias
pessoas para mapear uma atividade/produto transversal — **não como vigia**. Compor é legítimo
*quando cada fonte consentiu a composição* (§3, agregação/k-anonimato).

## 2. Para um sensor, a permissão de OBSERVAR é o gate (a inversão da linha intake↔execução)

O KB [`authorization-layers-intake-vs-execution`](../../knowledge-base/concepts/authorization-layers-intake-vs-execution.md)
crava a doutrina do Onion: **"guardar ≠ aceitar ≠ aplicar"** — intake (receber/verificar/guardar de
contato permitido) é **autônomo**; só a **execução** (agir, efeito de saída) é gated. Para a maioria
dos canais isso está certo: guardar uma mensagem não faz mal.

**Um sensor de comportamento inverte isso.** Aqui a captura *é* a intrusão — observar já é o ato
sensível. Logo existe uma **camada nova, _antes_ do intake**: a **permissão de observar**. Ela não é
autônoma; é o **gate**. Só se captura em estado autorizado; fora dele, a captura é **VETO** — e,
herdando o fail-safe do estudo de camadas, **ausência de permissão = veto, nunca skip** (o
antipadrão fail-open seria "capturar por default e pedir perdão depois").

> Para o sensor: a linha não é entre *guardar* e *agir* — é **antes de observar**. Capturar sem
> autorização prévia é o "fail-open" que o Onion proíbe em todo gate.

## 3. Dupla autorização deliberada — a pessoa E a organização (nem imposto, nem acidental)

O princípio do maestro, formalizado com o que a pesquisa sustenta:

- **A pessoa autoriza a própria captura.** Consentimento GDPR: livre, específico, informado,
  inequívoco, e **revogável tão facilmente quanto concedido** (Art. 4(11)/7). Mas ele é **frágil sob
  assimetria de poder** — no trabalho, EDPB/WP29 dizem que "quase nunca é livre"
  ([SYNTHESIS-P1](research/SYNTHESIS-P1.md) §2).
- **A organização autoriza e _escopa_ o propósito.** É o que a co-determinação alemã materializa: o
  **Betriebsrat** tem **veto** sobre monitoramento tecnológico (§87 BetrVG), fixando finalidade,
  dados, acessos e retenção. Autorização **coletiva positiva**, não aceite unilateral.
- **A composição entre pessoas é ela mesma consentida** — a org compõe conhecimento transversal só
  com o consentimento próprio de cada fonte.

**Não imposto** → revogabilidade real + VETO-não-SKIP; a org não pode impor à pessoa, nem a pessoa
sozinha legitima a composição coletiva (as duas autorizações são necessárias, nenhuma substitui a
outra). **Não acidental** → *privacy-by-default* (Art. 25), minimização e limitação de finalidade;
sem captura por default, sem scope-creep, sem uso secundário. Isto ancora nas primitivas que o Onion
**já tem**: a classificação 6-níveis do [`rfc-0003`](../../evolution/rfc/rfc-0003-federated-identity-collective-intelligence.md)
(`private` inviolável) e o fail-safe do [`de-identification none`](../../../.claude/utils/de-identification/README.md)
(recusa redigir-e-passar sem override humano explícito).

## 4. A lacuna que o consentimento NÃO fecha: a inferência (o fecho honesto)

Mesmo dupla-consentida e agregada, a captura tem um ponto cego: **o consentimento governa a coleta,
não a derivação**. LLMs inferem atributos sensíveis nunca fornecidos — Staab et al. (ICLR 2024):
**~85% top-1** a partir de texto ([SYNTHESIS-P1](research/SYNTHESIS-P1.md) §4). **Redigir strings de
PII não protege** (o modelo reconstrói pelo estilo/contexto), e o **orçamento ε** de differential
privacy **não cobre a inferência externa** de um modelo raciocinando sobre o próprio grafo. É
exatamente a fronteira aberta que o P4 de `onion-pessoal-marcio` nomeia e não fecha: *o motor que dá
vida ao mapa é também seu maior risco de privacidade.*

Mitigações são **parciais**, não uma cifra: não-retenção do bruto (local-first), revelar
**predicados** em vez de valores (SD-JWT VC/ZKP), e um **ledger de ε** que trate cada agregação como
gasto. A honestidade da nota: **dupla-consentida na captura ≠ protegida na inferência.**

---

## Honestidade (o fecho)

- **O consentimento é frágil onde mais importa.** Sob assimetria de poder (empresa↔pessoa), "a
  pessoa quis" pode ser coerção envernizada. Por isso a dupla autorização precisa de
  **revogabilidade real** e de um mecanismo coletivo (tipo Betriebsrat), não só de um checkbox.
- **A lacuna da inferência é estrutural, não um bug a corrigir depois.** Um sensor que alimenta um
  KG consultado por um transformer *produz* inferência por construção. Se este tema virar produto,
  a inferência entra no *threat model* desde o dia zero — não como fase 2.
- **Parte da minha pesquisa falhou e foi refeita.** 3 das 4 frentes da 1ª orquestração vieram como
  stub; re-executei. E números de mercado/moral que circulam como "fato" são frágeis (fonte única
  de 2021, blogs sem estudo) — ver as correções em [SYNTHESIS-P1](research/SYNTHESIS-P1.md).
- **Não decide fronteira de produto.** Se isto é *feature* do Onion pessoal ou *produto próprio* de
  process-mining consentido é a pergunta 5 do SEED — fora do escopo desta nota.

## Tabela de fecho

| Pergunta (SEED Q1) | Posição desta nota |
|--------------------|--------------------|
| Onde é a linha ética/legal? | Nos 4 eixos (finalidade/transparência/agregação/controle); mapear ≠ vigiar |
| Quem autoriza? | A pessoa **E** a organização — dupla, deliberada, revogável; nenhuma substitui a outra |
| Autônomo ou gated? | Para um sensor, **observar já é o gate**: captura sem autorização = VETO, nunca skip |
| Está resolvido? | **Não.** A inferência fura o consentimento — fronteira aberta (herda P4) |

## Dogfood

O modelo de consentimento desta nota vive como grafo em
[`proto/consent.kg.yaml`](proto/consent.kg.yaml) — a máquina `não-autorizado → autorizado →
revogado` (revogação sempre alcançável), a política de dupla autorização, a regra de VETO e a
reconciliação epistêmica onde a **lacuna da inferência REFUTA** "consentir a captura basta".

```bash
$ bash .claude/validation/kg-radar.sh docs/discussions/behavior-mapping-kg/proto/consent.kg.yaml
# ══ RADAR — atenção: EV_CAPTURE no topo (a captura é o ponto de maior atenção — o gate)
# ══ RECONCILIAÇÃO: REFUTES  C_INFERENCE_GAP → C_CONSENT_SUFFICIENT
# ══ RADAR-DE-DOMÍNIO: ✅ camada domain completa (sem lacunas nas 5 checagens)
# ══ INTEGRIDADE: ✅ sem contradições estruturais (22 nós, 24 arestas)  → exit 0
```

O radar coloca `EV_CAPTURE` como nó de **maior atenção** — o grafo "sabe" que a captura é o ponto
mais crítico, exatamente onde o gate de observar tem que morar.

---

### Próximas perguntas (não desta nota)

- **Q2** — intake×execução aplicado ao ciclo bruto→ação (o estudo de camadas direto).
- **Q3** — captura passiva (telas/ações) vs. declarada; local-first vs. nuvem.
- **Q4** — do sinal bruto ao KG: o que vira `event`/`entity`/`claim`; reconciliar declarado × observado.
- **Q5** — fronteira de produto: feature do Onion pessoal vs. produto próprio de process-mining consentido.
