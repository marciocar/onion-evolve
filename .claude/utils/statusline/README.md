# statusline — o censo de sessões na barra do Claude Code

`onion-sessions-line` imprime uma linha para a statusLine:

```text
sessões: 3 trabalhando · 1 esperam você: onion-evolve · ← claude agents
```

- **Fonte:** `claude agents --json`, a interface suportada do Claude Code (sem mod). Trabalhando = `status: busy`;
  esperando você = `status: waiting` ou `state: blocked`.
- **Custo:** cada leitura sobe um processo `claude` (medido em 2026-11-21: 0,5 s e ~156 MB). Por isso a leitura
  fica em cache por 25 s em `$XDG_RUNTIME_DIR/onion-sessions-line-<uid>/` (ou no tmp do sistema), com trava entre
  sessões. A pasta tem de ser do usuário e fechada (0700); senão a linha diz `sessões: cache inseguro, não li` e não
  lê nem escreve nada ali.
- **Lacuna visível, nunca zero inventado:** sem leitura sai `sessões: não li o estado`; cache corrompido sai
  `sessões: leitura ilegível`; leitura com mais de 90 s mostra a idade (`leitura de N s atrás`). O `0 trabalhando`
  só aparece quando uma leitura real veio vazia, e sessão em estado que a linha não conhece sai contada
  (`N em estado desconhecido`) em vez de sumir.
- **Sempre rc 0:** a statusLine que sai com rc diferente de 0 some da barra.
- **Portável:** o `claude` vem só do PATH; nenhum caminho de home fixo.
- **Clicar e ir:** a statusLine é texto, sem clique. O `← claude agents` no fim aponta o agent view nativo, que lista as
  sessões por estado e pula para a escolhida (no prompt vazio, a seta para a esquerda leva até ele; do shell,
  `claude agents` ou `claude attach <nome>`).

## Como ligar (passo do maestro)

A linha vai no settings do **usuário** (`~/.claude/settings.json`), não no do projeto: a statusLine não se mescla
entre camadas, e a do projeto substitui a de cada pessoa sem aviso. O `/meta:adopt` não escreve statusLine em lugar
nenhum; ele roda `.claude/utils/adopt/offer-statusline.sh <repo>`, que imprime o bloco com o caminho absoluto do
checkout principal já resolvido e avisa se o projeto tem statusLine própria. Para pedir o bloco a qualquer momento:

```bash
bash .claude/utils/adopt/offer-statusline.sh "$(git rev-parse --show-toplevel)"
```

O bloco tem esta forma (troque `<repo>` pelo caminho absoluto que o helper imprime):

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 -I '<repo>/.claude/utils/statusline/onion-sessions-line'",
    "refreshInterval": 30
  }
}
```

Cole na raiz do objeto do `~/.claude/settings.json` (se já houver uma `statusLine` ali, o bloco a substitui) e abra
uma sessão nova. Projeto com `statusLine` no próprio `.claude/settings.json` ou `settings.local.json` continua
mostrando a dele, e o censo não aparece ali.

Bancada: `run_sessions_statusline_selftests` em `.claude/validation/lint-selftest.sh`.
