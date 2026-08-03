---
date: 2026-08-02
instance: onion-evolve
type: innovation
classification: public
tags: [hooks, claude-code, posttooluse, exit-2, fail-open, guarda-de-shell]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Hook PostToolUse que precisa FALAR com o modelo tem de sair com `exit 2` — com `exit 0` ele roda e o stderr EVAPORA (medido com arquivo-marcador em /tmp: o hook executou, a mensagem não chegou). Consequência de desenho: `exit 2` é o único canal, então todo detector precisa ser determinístico e testado contra falso-positivo, porque cada disparo INTERROMPE. A guarda viva é `.claude/hooks/bash-empty-result-guard.sh` (4 detectores, 9 asserções de selftest, das quais 3 provam ausência de falso-positivo). Re-teste ao subir versão do Claude Code: o canal é comportamento da plataforma, não contrato escrito."
review_after: 2026-10-31
conflict_class: dynamic
significance: "Descobri por dogfood que `exit 0` num hook PostToolUse executa mas o stderr evapora — só `exit 2` entrega ao modelo. Foi a descoberta que tornou construível a guarda anti-fail-open do shell, que no mesmo dia me pegou duas vezes."
---

## Signal

**Num hook `PostToolUse`, `exit 0` roda mas o stderr EVAPORA. Só `exit 2` entrega a mensagem ao
modelo.** Não é documentado de forma óbvia e não se descobre lendo — se descobre medindo.

## Evidência

O hook estava registrado, o comando executava, e nada chegava. A dúvida honesta era *"ele roda e a
mensagem some, ou ele nem roda?"* — duas causas com curas opostas. O teste que separou: um
**arquivo-marcador** em `/tmp` escrito pelo próprio hook.

| execução | marcador | mensagem chegou |
|---|---|---|
| `exit 0` | ✅ escrito — **o hook rodou** | ❌ nada |
| `exit 2` | ✅ escrito | ✅ stderr entregue |

Com o canal medido, a guarda ficou construível — `.claude/hooks/bash-empty-result-guard.sh`, 4
detectores determinísticos de comandos que **mentem**:

1. **`EXIT-CODE-DE-PIPE`** — `$?` depois de um pipe lê o exit do *último* estágio
2. **`GLOB-SOB-SUDO`** — `*` num caminho sob `sudo` expande no shell do chamador, não no alvo
3. **`ERRO-ENGOLIDO-VIRANDO-NÚMERO`** — `2>/dev/null` a montante de `wc -l`: falhar e não existir dão o mesmo `0`
4. **`VAZIO ≠ AUSÊNCIA`** — comando de descoberta cru com saída vazia

Cada um nasceu de um erro **desta** sessão, não de imaginação. E a validação circular que vale
registrar: **a guarda me pegou duas vezes no mesmo dia em que nasceu** — uma delas escrevendo estas
próprias entradas de diário (`ls ... 2>/dev/null | wc -l` para contar o diário).

## O que fecha

`exit 2` ser o único canal tem uma **consequência de desenho**, não só operacional: todo disparo
**interrompe**. Logo o detector não pode ser heurístico — falso-positivo aqui não é ruído, é
travamento. Por isso 9 asserções de selftest, das quais **3 existem só para provar ausência de falso
positivo**, e duas nasceram de falsos positivos reais (corpo de heredoc sendo escaneado; `$?`
detectado sem proximidade da linha do pipe).

## Fronteira honesta

Isto é comportamento **medido da plataforma**, não contrato publicado — por isso `conflict_class:
dynamic`: re-testar ao subir versão do Claude Code, com o mesmo truque do arquivo-marcador. E a
guarda cobre **quatro** formas de o shell mentir; existem outras (`set -o pipefail` ausente, `grep`
sem `-q` em `if`, `read` sem `-r`). Ela reduz a superfície, não a fecha.
