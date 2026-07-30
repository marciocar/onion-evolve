---
description: >
  Retro/feedback como spec-as-code. Use ao FECHAR um ciclo — entrega, engajamento,
  sprint, fase de projeto, treino — para capturar o aprendizado de forma versionada,
  comparável e sem colisão. Gera um par perguntas/respostas (um-escritor-por-arquivo,
  I3), híbrido (pulso quantitativo NPS+CSAT + retro aberta nos 4 eixos + depoimento +
  consentimento), agrega as notas e emite migalha de diário ou sinal upstream. Ative
  quando alguém disser "retro", "retrospectiva", "feedback do processo", "fechar o
  ciclo", "o que aprendemos" — mesmo sem pedir explicitamente uma skill.
---

## onion-retro — a retro que vira dado, não conversa que evapora

Uma retro dita numa call evapora. Esta skill a torna **spec-as-code**: um artefato versionado,
com número comparável entre ciclos e prosa honesta, coletado sem colisão de merge. Nasceu de um
dogfood de campo real (um engajamento de consultoria+treino, 2026-07): o instrumento coletou NPS,
CSAT por fase, os 4 eixos e um depoimento consentido — e o ciclo fechou com o dado no repo.

### As invariantes que fizeram funcionar (não negociáveis)

1. **Par perguntas/respostas, um-escritor-por-arquivo (I3).** As perguntas vivem em
   `RETRO-<slug>.md`; as respostas em `RESPOSTAS-<slug>.md`, cujo **único escritor é o respondente**.
   Quem conduz **não toca** o arquivo de respostas — zero colisão de merge, e a voz é de quem responde.
2. **Híbrido: pulso + aberto.** O pulso (NPS 0–10 + CSAT 0–10 por fase) dá **dado comparável** entre
   ciclos; a retro aberta (4 eixos + Start/Stop/Continue + depoimento) dá o **porquê**. Um sem o outro
   mente: só número não explica, só prosa não compara.
3. **Consentimento é do respondente, e condicionável.** Uso como case/marketing pede **sim/não
   explícito**, com condições possíveis (anonimizar cliente/terceiros, revisar antes de publicar).
   Nunca se pré-preenche consentimento.
4. **Client-safe se cruza fronteira.** Se a retro alimenta o core (upstream) ou vira material de
   cliente, passa pelo **gate determinístico** (`grep` de termos sensíveis = 0) antes de sair.
5. **Fecha em dado, não em prosa solta.** Ao ser respondida, a retro **agrega** (NPS, tabela CSAT,
   síntese dos eixos) e **emite** uma migalha de diário e/ou um sinal upstream — o aprendizado nasce
   estruturado (parente do write(KG)).

### Etapas

#### 1. Escopo (parametrizar — a retro não é genérica)
Pergunte (ou derive do contexto): **quem responde** (respondente + papel) e **quais as fases do
processo** que se está avaliando. As fases são do ciclo real (ex.: descoberta → build → entrega),
**não** uma lista fixa — é isso que torna a retro fiel ao que aconteceu.

#### 2. Gerar o par
- `RETRO-<slug>.md` — as perguntas, com as fases do passo 1 na tabela CSAT (template abaixo).
- `RESPOSTAS-<slug>.md` — o esqueleto em branco, com o cabeçalho **"escritor único = <respondente>"**
  e os campos prontos (`Nota: ___`). Local canônico: irmão do processo (`retro/` da área/projeto).

#### 3. (Opcional) Rascunho da espinha factual — para revisar, nunca para falar pelo outro
Se o respondente pedir para não começar do zero, o condutor pode **rascunhar a parte factual**
(o que aconteceu em cada fase, candidatos de "deu certo/errado" tirados do registro do processo),
marcando cada linha com `» (rascunho, confirme/corte):`. **NUNCA** pré-preencha: a **nota** (NPS/CSAT),
o **depoimento** e o **consentimento** — esses ficam `[RESPONDENTE PREENCHE]`. O rascunho vai no
arquivo do respondente para **ele editar** (é a única exceção ao "condutor não toca" — e mesmo assim
ele revisa e reescreve antes de fechar).

#### 4. Coletar (I3)
O respondente preenche `RESPOSTAS-<slug>.md` — escritor único — e avisa (um recado curto, se houver
canal). O condutor **verifica contra o vivo** (o arquivo foi commitado/empurrado?), não confia no
"respondi" declarado.

#### 5. Agregar + emitir
Com as respostas: montar a **síntese** (NPS, tabela CSAT por fase, os 4 eixos condensados,
Start/Stop/Continue) e **emitir**:
- **migalha de diário** (`/meta:diary`) do que o ciclo ensinou; e/ou
- **sinal upstream** (`docs/evolution/inbox/`) se há aprendizado para o core — **passando pelo gate
  client-safe** (grep=0) e respeitando o boundary de autorização (quem relaya).
- Se a retro produziu **achados estruturados** (decisões, produtos deriváveis), o destino é um
  `.kg.yaml` (write(KG)), não prosa paralela.

### Template — `RETRO-<slug>.md`

```markdown
# Retro do processo — <respondente> 🤝

> **Pra quê:** aprender com o ciclo inteiro para evoluir o método. Sinceridade brutal —
> **o que doeu vale mais que o que brilhou.**
> **Onde responder:** em `RESPOSTAS-<slug>.md` (teu arquivo, escritor único — I3).
> **Formato:** híbrido — pulso rápido (número comparável) + retro aberta (o porquê).

## 1. Pulso rápido (0–10)
### 1.1 NPS — recomendaria ESSE jeito de trabalhar a um colega? Nota + porquê.
### 1.2 CSAT por fase (0–10 + 1 linha cada)
| Fase | Nota | Comentário |
|------|:----:|-----------|
| <fase 1 do processo real> | `__` | |
| <fase 2> | `__` | |
| … | `__` | |

## 2. Retro aberta (os 4 eixos)
- ✅ deu certo (manter)  · ❌ deu errado/travou (parar/consertar)
- 🤩 fantástico/inesperado (wow)  · 💸 caro/pouco valor (over-engineering)
- ▶️ Start · ⏹️ Stop · 🔁 Continue

## 3. Depoimento livre 🎙️
Do teu jeito, sem molde.

## 4. Consentimento
Posso usar (parte d)este depoimento como case/material? **sim/não** — e condições
(anonimizar cliente/terceiros? revisar antes de publicar?).
```

### Notas

- **Por que skill e não comando:** a retro é um **workflow reusável** que se ativa por reconhecimento
  ("fechar o ciclo"), não um passo fixo de pipeline. Compõe com `/meta:diary` (migalha) e
  `/meta:co-evolve` (relay do sinal), sem substituí-los.
- **Soberania/federação:** o que viaja é o **método + o template**, não o conteúdo de nenhuma retro
  específica (que é do respondente/da instância). Cada adotante roda a própria.
- **Fronteira de dados:** a retro é client-safe **por construção** quando cruza fronteira; o gate
  grep=0 é o mecanismo, não a disciplina.
