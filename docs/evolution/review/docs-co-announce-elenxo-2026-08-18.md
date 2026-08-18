---
branch: docs/co-announce-elenxo-2026-08-18
pr: 633
date: 2026-08-18
reviewed_diff_sha256: c76e3d3b85bbdaa1080db7f15bcdac914e0ab6f36c6fc5f1ff096125d9be4226
findings_total: 5
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 20
verdict: CONFORME-ENTREGA-12-DE-12-COM-I3-VERIFICADO
reviewer: passada adversarial manual (4 ataques dirigidos) + verificação de entrega por existência e diff; sem subagentes por restrição da sessão
REVISOU: true
---

# Resíduo — `docs/co-announce-elenxo-2026-08-18`

**Origem:** ordem do maestro — *"envia o anúncio de co-evolução para os adotantes"*.

## O fluxo, e onde cada mecanismo entrou

CHANGELOG (entrada nova, auditoria canônica) → `/meta:co-announce` (12 destinatários via
`resolve-target.sh "todos"` — mecanismo, não lista à mão) → `/meta:co-deliver` (12/12 entregues nos
`inbound/` locais, **entrega-sem-commit**) → `git mv` dos 12 para `outbox/<id>/_processed/`.

## Achado 1 — o gate pegou a derivação stale (REAL, curado — e é o gate funcionando)

O 1º commit foi **bloqueado**: o `federation-console.html` é derivação do CHANGELOG e ficou stale ao
nascer a entrada. Regenerado e commitado junto. Registro porque é o contra-exemplo do padrão desta
semana: aqui a guarda EXISTIA no caminho certo e disparou na primeira oportunidade — projeção não
divergiu da fonte nem por um commit.

## Os 4 ataques (3 limpos, 1 com achado colateral)

- **(a) O corpo entregue está íntegro?** `diff` do bloco extraído contra a entrada do CHANGELOG:
  **verbatim**, 31 linhas, sem corte do awk.
- **(b) O entregue = o da outbox?** `diff` no destino (amostra onion-pedro): **idênticos**.
- **(c) I3 — commitei em repo alheio?** `git status` em 3 adotantes: os arquivos estão `??`
  (untracked), **zero commits meus** fora do core. O invariante um-escritor-por-repo segue de pé.
- **(d) Backlog de inbound nos adotantes (colateral, OBSERVAÇÃO — não é deste PR):** somados os 12,
  há **64 anúncios não-processados** (52 anteriores a hoje; pulse-mais 16, granaai 9,
  onion-pessoal 8…). É o lado do ADOTANTE do protocolo — processar é da sessão de cada um, e o
  mecanismo que os sinaliza JÁ EXISTE (hook "you have mail" no SessionStart deles). Não criei
  mecanismo novo: seria o core administrando repo alheio, exatamente o que I3 proíbe. Fica o número
  medido para o maestro decidir se quer uma rodada de processamento nas sessões dos adotantes.

## Prova

- Entrega: **12/12** por existência do arquivo no destino + diff amostral.
- Lint: **0 HARD** (após a regeneração do console).
- Outbox: 12 rascunhos em `_processed/` (transportado git-visível); staging vazia.
- O anúncio credita o adotante que originou o sinal — a doutrina que ele não alcançava é a que
  agora chega a todos.
