---
branch: fix/selftest-role-predicate-consumers
reviewed_diff_sha256: 267c2056e21abca85658b412dcd2c703ccaf64eb1d1e7ff6a6b676e5b8801090
elenxo: nao
verdict: CORRIGIDO
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 6
nota: "Sem passada adversarial dedicada: o achado NASCEU de dogfood — rodar a bancada dentro de um hub real recem-atualizado. Dois defeitos da mesma classe (papel lido por igualdade a UM valor), o segundo descoberto ao curar o primeiro. Curado e provado POR EXECUCAO no proprio hub: os pulos aparecem com o papel verdadeiro e a familia fecha 12/12 com 4 ⊘."
---

# Resíduo — o predicado de papel da bancada era cego para `hub` e `standalone`

Sem refutador dedicado: **o achado veio do dogfood**. Ao atualizar um hub real com a leva anterior,
rodei a bancada **dentro dele** — e ela reprovou.

## Os dois defeitos, e são a mesma classe

**(1) Os dois casos novos da família do adapter Zoho cobravam AUTORIA do consumidor.** O caso (j)
varre quem enumera providers e o (k) confere `types.md` + `.env.example`. No consumidor eles leem o
`CLAUDE.md` **dele** e o `.env.example` **dele** — que é legitimamente dele, porque o never-clobber
manda o do core para `.env.example.onion`. Cobrar isso é **passivo alheio**, a mesma classe que o
`regen-baselines.sh` cura filtrando chave estrangeira.

**(2) E ao curar o (1) apareceu o maior:** o gate de família core-only da bancada testava
`[ "${SELFTEST_ROLE}" = "adopted" ]`. Um **hub** não é `adopted` — então ele rodava as **19 famílias
core-only** e reprovava. Medido no hub:

```
✗ radar-staleness: (b)…(h) — ERRO: --only: arquivo inexistente:
    /home/marcio/gmill/docs/onion/radar-baselines.yaml
```

Sete casos cobrando uma SSOT que **só o core tem**, de um repo que nunca a teve. O `members_registry`
seguia o mesmo caminho.

**A classe:** papel lido por **igualdade a um valor** envelhece no primeiro papel novo — é
`guarda-por-lista-falha-pelo-vocabulario` no eixo do papel. O predicado certo é **"não é o core"**:
`source` autora; `adopted`, `hub` e `standalone` consomem.

## Prova por execução, no hub

```
⊘ radar_staleness: core-only (role: hub — testa SSOT/maquinaria que só o core tem)
⊘ members_registry: core-only (role: hub — testa SSOT/maquinaria que só o core tem)
⊘ zoho-adapter: (j) core-only (role: hub — paridade de AUTORIA…)
⊘ zoho-adapter: (k) core-only (role: hub — o .env.example do consumidor é dele…)
Passaram : 12 · Pularam : 4 · Falharam : 0
```

O pulo **imprime o papel verdadeiro** em vez de afirmar `adopted` — sinal de máquina que diz o que
vale, não o que se supôs. No core (`role: source`) os 15 casos seguem rodando: **15/15, 0 pulos**.

## Por que a simulação por env NÃO serviu

Tentei provar com `SELFTEST_ROLE=adopted bash …` e passou 15/15 — **falso verde**: a bancada deriva
`SELFTEST_ROLE` do carimbo (`l.180`) e sobrescreve o env. Medir no caminho que eu controlo, quando
produção lê outro, é **não ter medido** — a prova válida foi copiar o arquivo para o hub e rodar lá.

## Gate

`lint-artifacts.sh` → 0 HARD no core · família `zoho_adapter` 15/15 no core e 12/12 + 4 ⊘ no hub.
