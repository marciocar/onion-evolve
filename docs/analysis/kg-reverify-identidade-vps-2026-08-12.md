---
title: "Re-verificação do grafo identidade-onion-vps — o primeiro lote de /meta:kg-freshness"
date: 2026-08-12
category: analysis
status: reference
kg: docs/onion/graph/identidade-onion-vps-2026-08.kg.yaml
run_id: wf_7804d86f-3a7
tokens: 869649
agents: 16
duration_min: 3
---

# Re-verificação do grafo `identidade-onion-vps-2026-08`

> **Projeção do grafo, não fonte paralela.** Os achados vivem no `.kg.yaml` acima; este documento
> é a leitura humana do run. Se os dois divergirem, o grafo vence.

## O run

| | |
|---|---|
| Padrão | fan-out-and-synthesize (barreira antes do fan-in) |
| Workers | 16 · `sonnet`/`medium` · 0 descartados |
| Medições | 95 comandos executados contra o vivo |
| Custo | 869.649 tokens · 149 tool-calls · 3min19s |
| Corte | `--top 16` de 20 rastreados; 4 fora (atenção ≤ 0.80, todos `done`) |
| Revisão | 2 revisores adversariais `opus` (correção · conformidade) — 165k tokens adicionais |

**Vereditos: 16 CONFIRMED, 0 DRIFTED, 0 REFUTED, 0 UNVERIFIABLE.**

O placar foi interrogado, não celebrado. A favor dele: os 16 mediram o vivo de verdade — nenhum
caso de "li o doc e concluí". O grafo é recente (carimbos de 10 e 11/08), logo houve pouca janela
para envelhecer. Contra: 100% verde é o resultado que esta casa manda desconfiar, e a desconfiança
achou três coisas — nenhuma delas um nó errado, todas defeitos do **instrumento** e do **arquivo**.

## Achado 1 — o carimbo anterior deixou duas verdades no mesmo nó

Cinco nós carregavam **duas linhas `verified_at:`** (`08-10` seguida de `08-11`): a rodada anterior
inseriu a data nova sem remover a velha. O radar é `awk`, uma chave por linha — o arquivo afirmava
duas coisas e o motor escolhia uma calado. Medido, não deduzido: `--freshness-tsv` devolvia a
última, logo o comportamento estava **correto por acidente**.

**A classe só apareceu inteira quando virou guarda.** Enquanto foi caso, a contagem era 5, num
grafo. Com `kg-radar.sh` passando a reprovar chave repetida, a varredura dos 60 grafos achou mais
duas — e as duas piores que as originais, porque nelas a linha vencedora era a **errada**:

- `stack-harmonia-2026-08` / `C_producao_nao_e_o_repo` — `verified_at` **e** `verified_against`
  duplicados, com a última sendo a **mais antiga**. O radar lia `08-01/git-log` tendo no arquivo a
  medição nova e mais rigorosa de `08-08/rev-list`.
- `fios-abertos` / `Q_REGRA56` — `verified_against` duplicado, e **essa era a causa do aviso
  `MISPLANED`** que o warm-up desta mesma sessão exibiu como fio aberto sem explicação. Curou junto.

Instância limpa de `fix-must-become-mechanism`: a cura one-off não teria achado nenhuma das duas.

## Achado 2 — o instrumento cometeu a falha que existe para pegar

No nó de **maior atenção** (att 30.0), o worker devolveu `CONFIRMED` com `blocked_by` preenchido —
campo que o schema reserva a `UNVERIFIABLE`. Mediu 2 das 3 mecânicas e **inferiu** a terceira,
alegando `permission denied` em `/home/onion/onion-bridge/src/`.

**O bloqueio era falso**: `sudo ls` lê o diretório, e o worker já usara `sudo` em quatro comandos
da mesma medição — `verify-access-before-specifying` reincidindo.

Medição fechada à mão, e o nó é CONFIRMED de verdade: `identity.ts:34` (JWKS local), `:45` (cache
`3_600_000`ms), `:129` (`iss`), `:133-145` (`aud`), `:126` (claims só depois da assinatura).
**Veredito certo pelo caminho errado** — a forma mais cara de acertar, porque não deixa rastro de
que não mediu.

## Achado 3 — a saída do backup está escrita e desarmada

`backup-offsite.sh` (commit `31cd4f9`) usa `restic` e sai com `exit 3` declarando que não fez.
Medido com stderr visível: cron do root tem 4 entradas, **nenhuma** offsite; um `.tar.gpg` num só
disco; `~/.password-store` sem entrada `restic`. Faltam `pass insert onion/restic-repo`,
`onion/restic-password` e a linha de cron — **decisão do maestro, não pesquisa a fazer.**

## O que a revisão adversarial derrubou da primeira versão desta cura

Registrado porque é o valor do Elenxo, e porque a mensagem do primeiro commit afirmava algo falso:

1. **`required` duplicado no próprio schema da guarda** — a segunda lista sobrescrevia a primeira,
   e `method`/`observed`/`verdict`/`blocked_by` deixavam de ser obrigatórios. **A mesma classe** do
   achado 1, reincidida no arquivo seguinte do mesmo PR. E a bancada que declarei "8/8" testava um
   literal com `required` único — **ela não espelhava o que embarcou**.
2. **`if`/`then` sem `required`** — em JSON Schema `properties` só se aplica a chaves presentes;
   omitir o campo satisfazia a guarda.
3. **"o tool-layer força o worker a retentar"** — meia-verdade. `SKILL.md:274` diz que output que
   falha no schema vira `null` e é filtrado: o nó **some da fila**. A guarda de schema criava um
   fail-open ao fechar outro. Curado exigindo contagem de descartes no relatório.
4. **A GUARDA 3 prometia o que JSON Schema não pode dar** — comparar duas propriedades. `2 de 3
   declarado TOTAL` passava, que é o modo de falha real. A promessa migrou para o fan-in (JS).

## Teto declarado

- Este run **não move** o passivo de 47 do lint: 15 dos 16 nós já tinham carimbo.
- A guarda de schema garante **coerência**, nunca **honestidade da contagem** — `claims_total: 1`
  num nó que afirma três passa. Por isso os campos aparecem na Saída Esperada e na tabela do gate:
  sem isso o maestro nunca os vê e a guarda vira cerimônia.
- `kg-reverify-schema-check.sh` mede a **forma** do schema, não a semântica de validação no
  substrato real. Provar a semântica exige rodar `/meta:kg-freshness` e observar um worker rejeitado.
