---
title: "Nota 00 — Síntese: a interface no estado da arte é a linha intake×execução tornada visível"
category: discussion-synthesis
status: fonte-de-discussao-isolada
date: 2026-07-12
branch: discuss/interface-state-of-art
amarra: SEED.md (4 perguntas) + NOTE-01..04
metodo: 6 frentes de pesquisa citada + aterramento no estudo interno
---

# 🧵 Nota 00 — Síntese da discussão "interface no estado da arte"

> **Isolada.** Pensa, não entrega. Nada vai pro core sem o maestro pedir.
> Cabeça da pasta: leia isto primeiro, depois SEED → NOTE-01..04.

## A tese em uma frase

**A interface no estado da arte, pro Onion, é a linha `intake × execução` tornada visível e observável.**
Não é feature nova — é a doutrina de autorização que o Onion já tem (`authorization-layers-intake-vs-execution.md`),
ganhando uma superfície que coleta, reconhece e comunica ao longo do *mesmo* eixo.

## O eixo único (por que as 4 perguntas são uma só)

As quatro perguntas do SEED convergem num princípio governante único — a linha entre **guardar** (intake,
autônomo de fonte permitida) e **agir** (execução, gated):

| SEED | Pergunta | O que a linha governa | Nota |
|---|---|---|---|
| 1 | telemetria útil e ética | o que a interface **coleta** sozinha (estrutura=intake / conteúdo=gate) | [[NOTE-01]] |
| 2 | reconhecimento de padrões | o que **promove** a doutrina (candidato surfaceia livre / promoção gated + refutador) | [[NOTE-02]] |
| 3 | comunicação além do chat | qual **superfície e intensidade de gate** (reversível=auto / irreversível=hard) | [[NOTE-03]] |
| 4 | intake×execução governa | a interface como **enforcement transversal** da própria linha | [[NOTE-04]] |

## Os achados que sobreviveram à pesquisa (não priors)

1. **O colapso da instância única tem valência dupla.** "Observado = beneficiário = maestro" **dissolve** o
   risco de vigilância (N01) — mas o mesmo colapso "proponente = aprovador = maestro" **cria** o risco de
   apofenia institucionalizada (N02). Mesmo fato, sinais opostos. → exige **refutador adversarial** na promoção.
2. **Os sinais úteis são de atrito, não de produtividade.** `tool_decision` reject-rate, `blocked_on_user`,
   repeated-span/loops, finish_reasons — "onde travei / o que foi rejeitado", não "fui X% mais rápido" (N01).
   E a ética manda **formativo, não performático** (paradoxo do quantified-self).
3. **Não instrumentar do zero.** O Claude Code já emite OTel (`session.id`, `tool_decision`, `blocked_on_user`,
   spans de subagente) com **estrutura grátis / conteúdo gated** — que é a própria linha, de graça (N01).
4. **Fadiga de aprovação é falha de SEGURANÇA.** Gate em rajada vira rubber-stamping; a supervisão fica
   performática. É o que faz o modelo gated do Onion segurar ou virar teatro (N03).
5. **Grafo tem teto duro (~50 nós).** `kg-console` é **modo de inspeção**, não workspace — o esforço vai pro
   gate visual + estado calm (N03).
6. **A interface fecha a lacuna §7 do estudo.** O "enforcement transversal por um só helper" que faltava pode
   **virar UI** — o gate em camadas por risco *é* a linha materializada num lugar só (N04).

## O loop que as notas compõem (dogfood-auditável / NS1)

```
  instrumenta (N01)  →  reconhece padrão de atrito (N02)  →  redesenha gate/superfície (N03)
        ↑                                                                    │
        └───────────────  re-mede: blocked_on_user caiu?  ←─────────────────┘
```

`blocked_on_user` (N01) é a métrica que diz se o gate (N03) fatiga o maestro. Batching + risco-em-camadas +
evidence-pack reduzem o tempo *sem remover* o gate. É o loop NS1 aplicado à própria interface — a interface
observando a si mesma pela mesma linha que ela enforça.

## Invariantes de design candidatos (o que a discussão sugere gravar)

1. **Estrutura é intake autônomo; conteúdo (prompt/código) é default-off gated** (purpose-limitation).
2. **Formativo, não performático** — nada de métrica rankeável/comparável no tempo.
3. **Nada auto-promove nem auto-aplica** — padrão→doutrina exige gate humano + refutador adversarial.
4. **Gate em camadas por risco** = materialização visual da linha: intake=auto, reversível=soft, irreversível=hard.
5. **Exibir degrada skip; gatear degrada veto** (gerador vs gate — a metade certa por elemento).
6. **Estado da sessão vive na periferia** (calm/glanceable), migra ao centro só no limiar de decisão real.

## Fronteira honesta (o que NÃO se resolveu)

- Tudo aqui é **design-only, isolado** — nenhuma linha foi pro core. Gates de N≥3, refutador, "exibir/gatear",
  reputação-condiciona-gate são **candidatos**, gated atrás de dogfood.
- A prova barata proposta (N01, fio 3): ligar `CLAUDE_CODE_ENABLE_TELEMETRY=1` numa sessão real e ver se um
  padrão-candidato emerge com lastro — responder à pergunta 2 do SEED *dogfoodando*, não teorizando.
- Ligações vivas: `discuss/behavior-mapping-kg` (a coleta ampla) e `discuss/onion-mobile-app` (voz = canal de
  intenção / terminal = canal de precisão).

## Método (para auditoria)

6 frentes de pesquisa orquestrada e citada (telemetria dev-tools, ética/privacy-by-design, observability de
agentes, detecção de recorrência, promoção/falso-padrão, interfaces além do chat, gates/calm-tech) + leitura do
estudo interno. Lente Aristóteles em toda analogia externa: *igual → transfere / diferente → desenha*. Fontes
completas em cada nota.
