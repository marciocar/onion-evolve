---
branch: fix/decide-triage-deterministic-nonce
pr: pendente
date: 2026-11-13
reviewed_diff_sha256: d3357866b74c94555176a1df0d74be0891e213d7c84ce8761be07635084bd6ed
reviewed_code_sha256: 7138dd743314ea5e887f5bc0f8f6f48c4202bd6c091ab296279d866873487a42
findings_total: 3
findings_real: 3
findings_blocking: 1
tokens: 0
duration_min: 0
findings_fixed: 2
verdict: FIXED
elenxo: true
reviewer: passada própria do autor (sondas no scanner novo e mutante no workflow real), refeita sobre o código final por um segundo agente
nota: "tokens e duração não medidos. Sem refutador externo: o brief proibia spawnar agentes. O achado 3 fica como limite declarado."
---

# Passada adversarial: `fix/decide-triage-deterministic-nonce`

## O que muda

O `.claude/workflows/decide-triage.js` gerava o nonce da cerca de conteúdo não confiável com
`Date.now()` e `Math.random()`. O runtime de workflow recusa o script com "Date.now() / new Date() are
unavailable in workflow scripts (breaks resume)", e por isso o modo triagem do `/meta:decide` nunca
tinha rodado. O `workflow-syntax-check.sh` dava verde, porque a sintaxe é válida.

- **Cura** (`decide-triage.js`): o nonce passa a ser um hash FNV-1a do TSV com a data. É determinístico
  por rodada, e quem escreve um nó não controla o TSV inteiro nem a data. Já usado em run real
  (`wf_84cf2bbf-b1c`, 3 agentes, sem erro).
- **Guarda** (`workflow-syntax-check.sh`): depois da sintaxe, o check varre o CÓDIGO atrás de
  `Date.now(`, `new Date`, `Date(` e `Math.random(`, e reprova com a linha. Comentário, string,
  template e regex literal são apagados antes da varredura (o `onion-research.js` cita `Date.now()`
  numa mensagem de erro, e isso é legítimo). As expressões dentro de `${…}` continuam sendo código.
- **Bancada** (família `workflow_syntax`): caso novo (j), com 6 formas proibidas que reprovam e um
  arquivo limpo que cita as mesmas formas em comentário, string, template e regex e passa. O caso (a)
  já passava o corpus real pelo check e agora inclui na mensagem a saída dele.
- **Skill** `onion-orchestration`: o comentário do comando de check cita o que ele passa a reprovar.

Varredura do corpus: dos 4 scripts Workflow (`.claude/workflows/*.js` e `census-workflow.mjs`), só o
`decide-triage.js` chamava relógio ou sorteio no código antes da cura. Depois dela, os 4 passam.

**Mutante**: a linha antiga do nonce foi reposta no `decide-triage.js`. O check acusou
`linha 71: Date.now( 71: Math.random(` (rc 1), e a família reprovou o caso (a) (1 de 10). O arquivo
foi restaurado da cópia e conferido com `cmp`, idêntico. Na cópia limpa, 10 de 10 passam.

## Achados

1. (real, BLOQUEAVA, curado) O check espelhava só a sintaxe, e o runtime recusa também o relógio. Um
   workflow com sintaxe válida e `Date.now()` passava verde e só falhava na hora de rodar, que é o
   vermelho tardio que este check existe para antecipar. Curado pela varredura nova e pelo caso (j).
2. (real, curado) Com o mutante, o caso (a) dizia "o falso-negativo voltou", e isso manda o leitor ao
   lugar errado. A mensagem agora traz a linha `✗` do próprio check.
3. (real, limite) O reconhecimento de regex literal é a heurística usual (barra depois de operador ou
   abertura). `x++ / 2` seria lido como início de regex e poderia esconder código até o fim da linha.
   O corpus não tem essa forma. Sondas que passaram: divisão depois de `)` e de número, regex com
   barra em classe (`/[/]…/`), regex com aspa, template aninhado dentro de `${}`, `globalThis.Date.now()`
   e `obj.Date(` (que não é acusado).

## Re-revisão sobre o código final (2026-11-13)

O primeiro carimbo foi feito antes de duas mudanças no código: o `| head -3` da mensagem do check
virou `sed -n '1,3p'` (uma guarda da casa acusou o `head`, que fecha o pipe cedo e é a classe EPIPE
sob `pipefail`; o pré-voo roda a família `shell_pipefail_robustness`), e a mensagem do caso (a)
passou a citar a saída do check. Um segundo agente leu o diff inteiro de novo e refez a prova:

- família `workflow_syntax` isolada (`--families=workflow_syntax`): 10 de 10 passam;
- mutante (linha antiga do nonce reposta): o check sai rc 1 com `linha 71: Date.now( 71:
  Math.random(`, e a família reprova o caso (a) com essa mesma linha; restaurado da cópia e
  conferido com `cmp`, idêntico;
- pre-commit do commit: bancada completa, 2014 passaram, 0 falharam.

Nenhum achado novo.

## Limites declarados

- A lista cobre o que o runtime nomeia (`Date.now`/`new Date`) e `Math.random`, que também quebra o
  replay. `performance.now()` e `crypto.getRandomValues()` não entram; nenhum workflow do corpus os usa.
- `shellcheck` não está instalado nesta máquina; o arquivo foi conferido com `bash -n` e pela bancada.
