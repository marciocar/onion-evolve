# Pontes Onion ↔ SRL/PLEA — as NOSSAS derivações (camada 2)

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-05 | **Camada**: APPLICATIONS (derivação do projeto)
> Tudo aqui é **construção do Onion** sobre a teoria — analogias de engenharia rotuladas
> **PLAUSÍVEL** pelos verificadores, nunca homologias confirmadas. Esta camada **cita** a teoria
> ([theories/](../theories/)) e **jamais a reescreve**. Se uma ponte cair amanhã, a camada 1 não
> se contamina.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-05 |
| **Última Atualização** | 2026-07-05 |
| **Teoria citada (SSOT)** | [plea-rosario.md](../theories/plea-rosario.md) · [srl-zimmerman.md](../theories/srl-zimmerman.md) |
| **Regra da fronteira** | fato-âncora por referência; rótulo obrigatório em cada ponte |

---

## 1. O mapa PLEA ↔ loop de auto-evolução — ⚖️ PLAUSÍVEL

| Fase PLEA (teoria: [plea-rosario §1-3](../theories/plea-rosario.md)) | Análogo no Onion (nossa leitura) |
|---|---|
| Planificação | radar do KG (atenção) · backlog do `/meta:evolve` · plans |
| Execução (+ automonitorização) | atuadores + dogfood |
| Avaliação (= redesenho de estratégias) | juiz adversarial · re-teste de migalhas · D10 → realimenta a próxima rodada |

**Veredito sintético da pesquisa**: rigoroso no esqueleto (3 fases ✓, ciclo-dentro-do-ciclo ✓,
avaliação-que-redesenha ✓, adaptação entre ciclos ✓), **incompleto pela lente SRL** — ver §3.

## 2. As pontes pontuais — cada uma com fato-âncora e limite

| Ponte (nossa) | Fato-âncora ✅ (camada 1) | Limite honesto da analogia |
|---|---|---|
| autoeficácia ↔ `confidence` de claims | autoeficácia é crença da Planificação ([srl-zimmerman §2](../theories/srl-zimmerman.md)) | crença de capacidade do agente ≠ credência epistêmica sobre proposições |
| radar/atuadores ↔ monitorização/controle | W&H: monitorização guia o controle ([srl-zimmerman §3](../theories/srl-zimmerman.md)) | no SRL a monitorização é metacognição INTERNA do aprendiz; o radar é script externo determinístico |
| diário/autobiografia ↔ narrativas do Testas | narrativa como veículo de SRL ([plea-rosario §4](../theories/plea-rosario.md)) | identificação humano-com-personagem ≠ sistema escrevendo o próprio diário |

## 3. A lacuna que a teoria expõe no Onion (achado A4 — para o KG da próxima auditoria)

A dimensão **volitiva/motivacional** é constitutiva do SRL ([srl-zimmerman §2](../theories/srl-zimmerman.md))
e **não tem análogo explícito** no loop radar→atuadores→juiz. Candidatos concretos a mapeamento
formal (falseável, sem antropomorfismo): persistência de re-tentativa · orçamento de esforço por
ciclo · priorização do backlog como orientação-a-metas.

## 4. Abertos que travam derivações (não construir em cima)

- **Q3** (prompts móveis): sem lastro → eixo `messenger` pedagógico segue **gated** —
  `onion-parecer-whatsapp-sender-2026-07.md` (parecer interno do core, §4-C): a *capacidade* de
  mensageria (inclusive prompts autorregulatórios/pedagógicos) é reconhecida, mas o eixo SDAAL só
  nasce quando o gatilho real disparar (demanda em 2+ contextos), à moda Onion (LLM-as-VM, provider
  oficial primeiro) — nunca código vendorizado no core.
- **Q5** (LLM-as-VM vs ACT-R/SOAR): originalidade da tese **não-avaliada**.

## 5. Relações

- Diretrizes de desenho que estas pontes informam: [educational-design-guidelines.md](educational-design-guidelines.md)
- ADR da vertical: `onion-adr-education-vertical-2026-07.md` (ADR interno do core). *Dimensão:* funda
  a vertical `onion-education` com rampa gated — só a camada de conhecimento (2 camadas:
  theories/applications) é construída agora; agentes/comandos/plugin ficam gated até o uso pedir —
  e fixa as diretrizes vinculantes derivadas da evidência; a vertical é **capacidade**, não 4ª dimensão peer.
- Analogias filosóficas irmãs (semente): `onion-research-seed-hegel-dialectics-2026-07.md` (semente de
  pesquisa interna do core). *Dimensão:* hipótese de que a dialética hegeliana (Aufhebung =
  negar+conservar+elevar) descreve formalmente o append-mostly do KG (claim refutado permanece,
  superado-preservando); catálogo do sistema + Q1-Q5, com Q5 como crivo anti-decoração. Deep-research gated.
