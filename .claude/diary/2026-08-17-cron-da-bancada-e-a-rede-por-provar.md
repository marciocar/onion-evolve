---
date: 2026-08-17
instance: onion-evolve
type: observation
classification: collective
tags: [ci, schedule, cron, filtro-de-path, ponto-cego, verificacao-fechada, rede-provada]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-18
retested_at: 2026-08-18
conflict_class: static
significance: "RE-TESTADO E FECHADO em 2026-08-18: o cron DISPAROU (run 32100701318, event=schedule, main, 824 asserções / 0 falhas) — a rede debaixo do filtro de path existe e funciona, provada por CONTAGEM e não por exit code. Fica a lição do desenho: a migalha nasceu com review_after de 1 dia porque a capacidade era DECLARADA e não verificada, e o relógio de 1 dia foi o que a trouxe de volta para ser medida. E o cron atrasou 35 min (04:52Z, não 04:17Z) — margem de tolerância é parte do teste, não ruído."
---

# [FECHADO em 2026-08-18 — o cron disparou] O cron que justifica o filtro — e que ainda não provou existir

**O que foi feito (2026-08-17, PR #625).** A bancada (`lint-selftest.sh`, 689 asserções) saiu
do workflow de gate e foi para `onion-selftest.yml`, que roda **só quando a maquinaria muda**
(`.claude/validation|hooks|utils`, `ops/`, `.github/workflows/`). Medição que motivou: a
bancada era **686s de 729s — 94% do CI** — e dos 8 PRs do dia anterior **6 tocaram zero
arquivo de maquinaria**. O gate caiu para **49s**, medido no próprio PR que fez a mudança.

**O risco que isso cria, e não é hipotético.** Filtro de path já produziu **três pontos
cegos** aqui: `plugins/` (#241), `docs/` (#254), `ops/` (#509). Nos três, o defeito não foi
filtrar — foi **filtrar e não ter mais nada**: caminho fora da lista nunca era coberto por
ninguém, e ninguém lê lista de path. Por isso o workflow novo tem `schedule: '17 4 * * *'`
rodando a bancada **inteira** na `main`, sem filtro — a rede debaixo.

**O que está PROVADO hoje:** o workflow está `active` (id 336224267) e o `cron` está no
arquivo **na `main`**, que é de onde o agendador lê. As duas falhas clássicas (workflow não
reconhecido; definição só fora da branch default) estão descartadas.

**O que NÃO está provado:** que ele **dispara**. O `schedule` do GitHub Actions é
*best-effort* — em horário de pico atrasa e pode engolir execuções. O merge foi 13:07 UTC e a
primeira janela é 04:17 UTC do dia seguinte, então "nenhuma execução" hoje é **esperado**, não
defeito. Distinguir os dois é o ponto desta migalha.

**Re-teste (2026-08-18) — uma linha, com o veredito já escrito:**

```bash
gh run list --repo marciocar/onion-evolve --workflow onion-selftest.yml --event schedule --limit 3
```

- **Há execução agendada** → a rede existe; o filtro de path está justificado; fechar esta
  migalha como confirmada.
- **Continua "no runs found"** → a rede **não existe** e o filtro está nu: três pontos cegos
  de precedente dizem o que acontece daí. Aí a decisão é uma destas, e não "prestar atenção":
  reduzir o filtro (voltar a bancada para todo PR e aceitar os 12 min), ou trocar a rede por
  algo que não dependa do agendador do GitHub (cron da própria VPS chamando
  `gh workflow run onion-selftest.yml`, que é disparo e não agendamento).

**A nota de método, porque quase virou relato falso.** Ao conferir isto, meu
`git show origin/main:.github/workflows/onion-selftest.yml` respondeu **"não existe na
origin/main"** — e eu ia reportar ao maestro que o cron não estava na branch default. Era o
meu ref local **desatualizado** (sem `fetch` desde o merge). Um `git fetch` inverteu a
resposta. Terceira vez no mesmo par de dias em que **medir no ref/lugar errado** quase virou
afirmação: `.git/hooks` em vez de `core.hooksPath`, `$?` depois de pipe, e agora `origin/main`
velho. O padrão não é falta de cuidado — é que a leitura errada **responde com confiança**.

---

## RE-TESTE — 2026-08-18 (a rede deixou de ser promessa)

Esta migalha nasceu com `review_after` de **um dia** — o prazo mais curto que já usei — porque o que
ela registrava não era um erro, era uma **capacidade declarada e não verificada**: um `schedule:`
escrito no YAML não é um cron que dispara. O relógio curto era o mecanismo, e funcionou: trouxe o
item de volta para ser medido em vez de envelhecer como fato presumido.

**Medido hoje:**

| O que | Valor |
|---|---|
| Run | `32100701318` — `event=schedule`, branch `main` |
| Disparo | **2026-08-18T04:52:01Z** (a janela declarada é 04:17Z — **35 min de atraso**) |
| Duração | 11m44s |
| Placar da bancada | **824 passaram · 0 pularam · 0 falharam** |

**Fecha, e o veredito é: a rede existe.** O filtro de path que tirou a bancada do gate de todo PR
(12 min → 49s) tem, de fato, alguém por baixo — a suíte inteira roda na `main` todo dia,
independente de qual path o PR tocou. Era exatamente isso que faltava nos três pontos cegos
anteriores (`plugins/` #241, `docs/` #254, `ops/` #509): lá o filtro **não tinha mais nada**.

**Três coisas para levar adiante, e nenhuma é "prestar atenção":**

1. **`success` não foi o que fechou isto.** O que fechou foi a **contagem** — 824/0/0. Um job que
   falhasse em abrir a suíte também sairia verde; e `Pularam: 0` é o campo que prova que nenhuma
   guarda ficou sem exercitar o SUT.
2. **O cron atrasou 35 minutos**, e isso é o comportamento normal do GitHub sob carga. Qualquer
   verificação futura desta rede precisa de **margem de tolerância** — checar às 04:17 em ponto e
   concluir "não disparou" seria um falso negativo por desenho do instrumento.
3. **A separação valeu.** Na véspera eu havia disparado a mesma suíte por `workflow_dispatch` na
   `main` (824/0/0 também). Aquilo provou o **corpo** da rede sem provar o **despertador** — e
   declarar a diferença foi o que permitiu, hoje, saber exatamente o que ainda estava aberto.
