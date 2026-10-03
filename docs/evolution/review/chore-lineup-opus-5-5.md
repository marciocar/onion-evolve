---
reviewed_diff_sha256: f98ef54b5b22c3ad7b794ef3dd8d9c789aa6f8095d073a3c616b459113725134
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
verdict: SEM_ACHADOS
elenxo: nao
nota: >
  `elenxo: nao` — declaração honesta, não omissão. Não houve passada adversarial por subagente: o
  diff aplica UM selo do maestro sobre um achado que JÁ passou por juiz adversarial no PR #907 (que
  reprovou 5 de 6, e foi ao reprovar o A1 que revelou este achado). Re-refutá-lo seria repagar o
  juiz. O risco que sobrava não era "o achado está errado?" e sim "a guarda passa a se comportar
  como se espera?" — e comportamento se mede invocando: 3 cargas reais no hook (allow / block
  fora-do-lineup / block piso-pelo-picker), com o .claude/sessions/model-switch.jsonl corroborando
  as três decisões de forma independente do código de saída. As DUAS contraprovas são o ponto:
  liberar um modelo não podia afrouxar a guarda, e não afrouxou. A projeção da REGRA 70 foi
  derivada rodando a fórmula do próprio lint, nunca digitada.
---

# Resíduo — `chore/lineup-opus-5-5`

**Por que não houve passada adversarial, e por que isso não é um buraco.** O achado deste PR nasceu
de uma passada adversarial — a do PR #907, onde o juiz opus/high reprovou 5 de 6 achados e, ao
reprovar o A1, revelou que a `2.1.280` existe e traz `claude-opus-5-5` como Opus default. Este PR
aplica o selo do maestro sobre esse achado.

## O que o dogfood provou

| carga no hook | decisão | testemunha independente |
|---|---|---|
| `opus-5` → `opus-5-5`, source `picker` | allow, `ladder=restored` | `"decision":"allow"` no jsonl |
| `opus-5-5` → `haiku-3` | block (fora do lineup) | `"decision":"block"`, `ladder=same` |
| `opus-5-5` → `sonnet-5`, source `picker` | block (piso só por fallback) | `"decision":"block"`, `ladder=degraded` |

**Duas testemunhas de propósito.** `$?` lido depois de um pipe é frágil — a guarda anti-fail-open do
shell avisou na hora, e tem razão em geral (aqui a guarda *é* o último elo). O log registra a
decisão sem passar pelo código de saída, e é por isso que ele conta.

**O que NÃO foi medido:** o fallback NATIVO da plataforma caindo de fato para `claude-opus-5-5` sob
sobrecarga real. A paridade `fallbackModel` ↔ escada é cobrada pela **REGRA 70 (fallbackModel do
settings.json é PROJEÇÃO da escada de modelos)** e passou; o *disparo* do fallback nativo depende de
condição de cota que não se provoca à mão. Teto declarado, não simulado.

## A parcial que fica aberta com gatilho

O `session_floor` segue `claude-sonnet-5`. A `2.1.284` traz `claude-sonnet-5-5` como o novo Sonnet
default — **mesmo achado, não autorizado nesta volta**. O piso atual não está quebrado (o modelo
existe), só não é o máximo do lineup. **Gatilho: o maestro dizer, ou a rodada do eixo E6.**

## Um defeito meu desta volta, registrado porque é classe

Ao escrever este resíduo eu extraí o hash com `grep -oE 'Esperado: [0-9a-f]{64}'` — e a guarda, no
caso *artefato ausente*, diz **"O hash deste diff é"**. Extração casada com UMA redação da mensagem
falha na outra. O `test -n` abortou antes de escrever qualquer coisa (fail-closed fez o trabalho),
mas a lição é a de [[guarda-por-lista-falha-pelo-vocabulario]]: em guarda de texto o defeito
dominante é o **vocabulário**, não a lógica. A cura foi casar o **formato** (64 hex), não a frase.
