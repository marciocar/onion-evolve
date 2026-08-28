---
title: "Revisão — farol de sessão mede o dono (informado ≠ verificado)"
date: 2026-08-28
branch: fix/beacon-verified-liveness
reviewer: "2 revisores adversariais em paralelo (código do motor + cobertura de bancada), com execução e mutação; + dogfood do hook pelo caminho real"
reviewed_diff_sha256: 61db9650578e6f1e888e3208ccef7a09d8f05619aef77e2ea58965ec8014f8e2
findings_total: 13
findings_real: 11
verdict: APROVADO_APOS_CORRECAO
tokens: 216000
duration_min: 62
---

# Resíduo — REGRA 56

Mudança de **guarda**: o farol de sessão passa a MEDIR o dono do beacon em vez de confiar no
carimbo `refreshed_at`. Guarda que erra tem dois custos assimétricos, e a revisão foi
desenhada em torno disso: um falso `orphan` (diz morta, está viva) **reabre o incidente
W1×W2** que criou o farol; um falso `declared` custa uma verificação.

## Veredito dos revisores

| revisor | veredito inicial | achados reais |
|---|---|---|
| código do motor (adversarial, com execução) | 🔴 **VERMELHO** | 7 |
| cobertura de bancada (adversarial) | 🟠 laranja | 4 |

**A 1ª versão foi REPROVADA, e com razão.** O que segue é o que mudou depois.

## Achado crítico — a cura nascia violando a própria invariante

`beacon_verdict` curto-circuitava no dono e **nunca consultava o heartbeat**. Provado em
execução (não em leitura): beacon com `refreshed_at == now` e dono morto → veredito `orphan`,
`check` exit **0** — ou seja, **autorizando outra sessão a escrever sobre uma sessão viva**.
`/meta:drive` P3 manda `check` antes de todo switch de worktree: o mecanismo criado para
impedir o W1×W2 estava dando o sinal verde para ele.

Três gatilhos reais produzem "dono não encontrado" **sem** a sessão ter morrido:
(a) `/proc` indisponível/ilegível aqui (container, `hidepid`, macOS lendo beacon alheio);
(b) beacon escrito em **outra máquina** — o pid nem é deste kernel;
(c) a sessão **trocou de processo** (resume/restart com o mesmo sid) e o refresh preservou o
dono velho.

**Cura (mata a classe, não o caso):** `orphan` deixou de ser corolário de "dono não
encontrado" e passou a exigir **conjunção** — dono medido morto **E** heartbeat parado além
de uma janela de graça (30 min, `ONION_BEACON_ORPHAN_GRACE_MIN`) **E** `/proc` legível aqui
(`proc_available` separa *não há o que medir* de *prova de morte*) **E** o beacon ser desta
máquina (o campo `host:` já era gravado e **não tinha consumidor**). O poder de matar
fantasma sobrevive quase inteiro (8h → 30 min) e virou **impossível** declarar morta uma
sessão que acabou de agir.

## Achado crítico nº 2 — a bancada estava cega no ponto que mais importava

O revisor mutou o motor para o veredito `live` **deixar de bloquear** — matando a proteção I3
inteira — e a suíte passou **toda verde**. O caso rodava em sandbox compartilhado e o `exit 1`
que ele conferia vinha dos beacons do teste vizinho. *Teste que não isola mede o vizinho, não
o SUT.* Corrigido com sandbox próprio + grep do rótulo; a mutação agora **reprova**.

O segundo revisor achou a irmã desse defeito: o caso da sonda passava **por motivo diferente
em dev e no CI** (o decoy subia a árvore real e encontrava um `claude` legítimo a 1 hop).
Corrigido reparentando o decoy para o init (`setsid --fork`).

## Demais achados reais corrigidos

| # | achado | cura |
|---|---|---|
| 3 | bancada **abortava** (não pulava) em host sem `/proc`: `sed \| awk` + `pipefail` matava a suíte, tornando os ramos de skip inalcançáveis | `\|\| true` nos pipelines |
| 4 | `record_pass` nos fallbacks "sem /proc" — **falso-verde por vacuidade**, contra a doutrina do próprio arquivo | virou `record_skip` |
| 5 | plugin distribuía o **consumidor sem o motor**: o adotante ficava com a régua de TTL que este PR provou errada, em silêncio | `session-beacon.sh` entrou no manifesto do `onion-work-tools` |
| 6 | `refreshed_at` não-numérico derrubava `verdict`/`check` sob `set -u`, **perdendo a listagem inteira** (inclusive o beacon vivo) | sanitizado nos 3 pontos |
| 7 | `⚠️ NUNCA refrescou` saía até em veredito `live` — e é verdade para **toda** sessão recém-nascida; o texto do hook ensina a lê-la como fantasma | suprimida em `live`; reescrita como "ainda sem prompt" |
| 8 | **`sweep` não tinha gatilho nenhum** (nada no settings.json o chamava): 23 beacons, 20 stale, todos bloqueando | cabeado no `up` do hook, antes do `check` |
| 9 | comentário do fallback do mapa dizia "worktree irmã" — `${BASH_SOURCE[0]%/*}` é sempre o dir local | comentário corrigido |
| 10 | sem cobertura do caminho **positivo** da sonda (eleger) nem da preservação do dono no refresh — a razão de existir citada no próprio código | casos j2/j3/j5 (claude falso determinístico) |
| 11 | texto impresso de `live`/`orphan` nunca conferido (saída em `/dev/null`) | grep do rótulo nos dois |

**2 achados NÃO acatados** (registrados, não corrigidos): teste de hop-limit da sonda e teste
de não-vazamento do `unset` — ambos de baixo risco medido (nenhum outro modo lê as variáveis;
confirmado por grep) e sem modo-de-falha demonstrado.

## Categorias atacadas em que os revisores NÃO acharam nada

- **Parsing de `/proc/<pid>/stat`**: testado com `comm` contendo espaço e parêntese — o
  mapeamento campo 22→20 e ppid 4→2 está correto, e o corte pelo **último** `)` é seguro.
- **Beacons antigos** sem os campos novos: caem em `declared` e bloqueiam (verificado contra
  os 23 beacons reais do repo).
- **Duplicação de chaves**: `up` reescreve o arquivo inteiro.
- **`set -euo pipefail`** no motor: o `if`-block substituiu a cadeia `&&` e o `up` sai 0 com e
  sem dono (medido nos dois casos — era um bug real, achado pelo dogfood antes da revisão).

## Verificação mecânica

- **Bancada `session-beacon`: 25 casos, 0 falhas, 0 skips** (todos os cenários montados de fato).
- **Mutação (5 mutantes, cada um reprova no caso certo):** sonda por substring de cmdline ·
  refresh que não preserva o dono · `sweep` apagando beacon vivo · `live` que não bloqueia ·
  curto-circuito antigo do `orphan` (este derruba 3 casos).
- **Suíte completa** e **`lint-artifacts`**: ver corrida final anexa ao PR.

## Nota de processo

O revisor de código registrou que a working tree mudou sob ele durante a revisão (eram as
minhas correções ao 1º revisor) e **re-rodou todas as provas contra o estado commitado**
(`git show HEAD:`) em vez da árvore suja — a conduta certa, e vale registrar como precedente.
