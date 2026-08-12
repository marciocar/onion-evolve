---
branch: fix/kg-reverify-worker-contract
pr: 584
date: 2026-08-12
reviewed_diff_sha256: 69dfce262f5f8b5a8e55234b619aa771a6458b2fd6572ea0530a3c0dbd079454
findings_total: 13
findings_real: 13
findings_fixed: 12
tokens: 165087
duration_min: 10
verdict: CORRIGIDO-E-RE-VALIDADO
reviewer: code-reviewer + metaspec-gate-keeper (opus, adversarial, lentes independentes)
---

# Passada adversarial — `fix/kg-reverify-worker-contract`

## Como a passada foi montada

Dois revisores `opus` **em paralelo, com lentes independentes** — um de correção (tentar refutar
as afirmações factuais, re-executar as medições), outro de conformidade doutrinária (gramática do
`.kg.yaml`, coerência do mecanismo, doutrina da casa). Ambos instruídos a **default para "está
errado"** e a dizer explicitamente quando uma dimensão estivesse limpa.

Nenhum dos dois foi tratado como veredito: cada achado foi re-medido antes de virar correção.

## Achados

| # | sev | achado | status |
|---|---|---|---|
| 1 | ALTA | `required:` declarado **duas vezes** no `KgReverifySchema` — a segunda sobrescreve; 7 campos deixaram de ser obrigatórios | corrigido |
| 2 | ALTA | a bancada "8/8" tinha `required` único — **não espelhava o literal embarcado** | corrigido (guarda extrai o schema do próprio arquivo) |
| 3 | ALTA | `if`/`then` sem `required`: omitir o campo satisfazia a guarda | corrigido |
| 4 | ALTA | "o tool-layer força o worker a retentar" — falha de schema também **descarta** o worker (`SKILL.md:274`) | corrigido |
| 5 | ALTA | GUARDA 3 prometia comparar duas propriedades; `2 de 3 declarado TOTAL` passava | corrigido (migrou para o fan-in) |
| 6 | MÉDIA | `claims_measured > claims_total` validava | corrigido (fan-in) |
| 7 | MÉDIA | `UNVERIFIABLE` com `blocked_by` vazio validava | corrigido (GUARDA 3 nova) |
| 8 | MÉDIA | label de `E_VERIFIED_AT_DUPLICADO` descrevia errado o próprio diff (3 dos 5 receberam data nova) | corrigido |
| 9 | MÉDIA | `Q_LACUNA` carimbado citando um run **sem artefato persistido** | corrigido (`docs/analysis/`) |
| 10 | MÉDIA | `C_NO_COMPOSTO` dizia "candidato, não decidido" com o commit irmão já implementando | corrigido |
| 11 | MÉDIA | a classe (chave repetida) foi curada **caso a caso**, sem mecanismo | corrigido (`kg-radar.sh` reprova) |
| 12 | MÉDIA | identificadores em pt-BR misturados com inglês no mesmo objeto | corrigido |
| 13 | BAIXA | `proposed_write` mudou de `{}` para `string` sem menção — contrato do consumidor `/meta:evolve` | **aceito e declarado**, não corrigido |

**Dimensões que os revisores declararam limpas** (registro importa tanto quanto o achado): a
afirmação "o radar lê a última ocorrência" **não foi refutada** — foi confirmada em
`kg-radar.sh:203` e por fixture; e a gramática dos nós novos passou campo a campo.

## O que esta passada custou e o que ela comprou

O achado #1 é o que justifica o mecanismo inteiro: **eu cometi, dentro da cura, a mesma classe de
defeito que a cura documentava.** O commit anterior afirmava "provei antes de embarcar" — e o que
foi provado não era o literal que embarcou. Sem a passada, isso teria mergeado com a mensagem de
commit declarando o oposto do que o arquivo fazia.

O achado #11 rendeu mais do que corrigiu: ao virar guarda, a classe saiu de **5 instâncias num
grafo** para **7 em três grafos**, e as duas novas eram piores — nelas a linha que vencia era a
errada. Uma delas explicava um aviso `MISPLANED` que estava aberto no warm-up desta mesma sessão
sem que ninguém soubesse a causa.

## Teto declarado desta revisão

**Não houve segunda passada adversarial completa após as correções.** A re-validação foi por gate
mecânico — `kg-reverify-schema-check.sh --selftest` (6/6), `kg-radar.sh --integrity --schema`
(exit 0, 31 nós/27 arestas), varredura dos 60 grafos (0 chaves repetidas), `lint-artifacts.sh`
(0 HARD) — mais re-medição pontual de cada achado corrigido. Gate determinístico cobre a dimensão
sintática; **não substitui** um verificador semântico, e essa dimensão fica nomeada como
não-re-verificada.

Também não se provou a **semântica de validação no substrato real** (o tool-layer do Workflow).
`kg-reverify-schema-check.sh` mede a *forma* do schema. Provar o comportamento exige rodar
`/meta:kg-freshness` e observar um worker ser rejeitado — o que só acontece no próximo lote.
