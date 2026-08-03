---
date: 2026-08-03
instance: onion-evolve
type: error
classification: collective
tags: [mecanismo, nota, waiter, harness, fail-open, gated-until-trigger]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-01
conflict_class: static
significance: "Identifiquei um bug, escrevi a cura no plano, e reincidi DUAS vezes nas horas seguintes — porque registrei como NOTA. No mesmo dia, três mecanismos que criei tiveram 100% de eficácia. A diferença não é a qualidade do registro; é onde ele mora."
---

## Signal

Registrar uma lição **em texto** não muda comportamento — nem quando o texto é meu, recente,
específico e escrito por mim mesmo minutos antes. **Nota não é mecanismo.** Se a cura depende de
alguém lembrar, ela falha; se depende da ferramenta não existir ou de um gate interromper, funciona.
E o corolário prático: **antes de construir a guarda, pergunte se o erro tinha um mecanismo já
pronto que você ignorou** — foi o meu caso.

## Evidence

- **O erro**: usei `while pgrep -f "lint-selftest"; do sleep 10; done` para esperar um selftest.
  A própria linha de comando do waiter contém `lint-selftest` → `pgrep` casa o **bash pai** → o
  waiter espera **a si mesmo**, para sempre.
- **Identifiquei o bug e escrevi a cura** no plano da sessão, como candidato a 5º detector da
  guarda anti-fail-open, com a correção explícita (`| grep -v $$`, ou checar o artefato).
- **Reincidi 2×** nas horas seguintes. Dois shells presos: um por **30 minutos**, outro por 8 —
  ambos *vivos e produtivos na aparência*, nenhum tendo executado uma linha do selftest. Só
  apareceram porque o maestro perguntou "temos 2 shells rodando, como estão?".
- **Contraste medido no MESMO dia**, mesma pessoa, mesmas horas:

  | Forma do registro | Resultado |
  |---|---|
  | Nota no plano ("lembrar de não usar `pgrep` assim") | **reincidi 2×** |
  | Mecanismo: `agentType: Explore` (sem `Write`/`Edit`) | workers pararam de escrever, **100%** |
  | Mecanismo: guarda anti-fail-open (`exit 2`) | **8 capturas**, todas efetivas |
  | Mecanismo: catraca do `rules-registry` | pegou até o **epitáfio** de uma regra removida |

- **A reavaliação derrubou a guarda que eu ia construir** (pedida pelo maestro antes de eu agir):
  · o repo **não usa `pgrep`** — única ocorrência é este diário; não há superfície de repo a proteger;
  · o auto-match é **inerente**: medido, `pgrep -f X` num comando que contém X acha sempre o bash
    pai — o detector dispararia em ~100% dos usos, virando ruído (e ruído desliga guarda);
  · **causa raiz é outra**: o harness **já notifica** quando um job em background termina. Eu
    reimplementei um mecanismo existente, e o reimplementei mal. O `pgrep` foi só o instrumento.

## Next crumb

Duas coisas, nesta ordem:

1. **Esperar é default, não implementação.** Job em background → aguardar a notificação do harness.
   Não escrever waiter de processo. Se precisar de espera condicional (CI, estado remoto), o waiter
   observa **o artefato** (log, exit code, API), nunca a existência de um processo.
2. **Antes de propor guarda para um erro meu, checar as 3 perguntas** que derrubaram esta:
   o repo usa isso? · o detector distingue erro de uso normal? · já existe mecanismo que eu ignorei?
   Este foi o **terceiro "não construir"** da sessão — junto com o `kg:` pendurado que não existia
   (bloco C) e a generalização da REGRA 4 (sem `.mcp.json`, espaço já ocupado pela R12). Nos três a
   proposta parecia sólida até alguém medir; nos três quem pediu a medição foi o maestro.

_Sem `kg:`: a lição é comportamental e de uso do harness, com evidência direta (contagem de
reincidências e o contraste nota×mecanismo) — não há cadeia de claims a reconciliar num grafo._
